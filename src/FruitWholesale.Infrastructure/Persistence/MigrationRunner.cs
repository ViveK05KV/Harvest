using FruitWholesale.Application.Common.Interfaces;
using Npgsql;
using Microsoft.Extensions.Logging;

namespace FruitWholesale.Infrastructure.Persistence;

/// <summary>
/// Applies migration scripts listed in database/auto-migrations.txt that haven't already
/// been recorded in SchemaMigrations, in the order they're listed, on app startup.
///
/// Eligibility is an explicit allowlist, deliberately NOT inferred from filename
/// numbering — this folder also contains one-time bootstrap scripts (01-05;
/// 01_CreateDatabase_Tables.sql drops and recreates every table) and manual reset
/// utilities (11_ClearTransactionalData.sql deletes all real transactional data with
/// no idempotency guard) that must never be auto-applied. A script only runs here if
/// its filename is explicitly listed in the manifest.
/// </summary>
public class MigrationRunner(IDbConnectionFactory connectionFactory, ILogger<MigrationRunner> logger)
{
    private const string ManifestFileName = "auto-migrations.txt";
    private const int MaxConnectAttempts = 5;

    // Fixed advisory-lock key for the migration process; hashtext() of a stable string
    // would also work, but a literal keeps the lock key visible without a round trip.
    private const long MigrationLockKey = 872341;

    public async Task RunAsync(string migrationsDirectory, CancellationToken cancellationToken = default)
    {
        if (!Directory.Exists(migrationsDirectory))
        {
            logger.LogWarning("Migrations directory {Dir} not found; skipping migrations", migrationsDirectory);
            return;
        }

        using var connection = (NpgsqlConnection)connectionFactory.CreateConnection();
        await OpenWithRetryAsync(connection, cancellationToken);

        // Serialize across replicas that might start concurrently.
        await using (var lockCmd = connection.CreateCommand())
        {
            lockCmd.CommandText = "SELECT pg_advisory_lock(@LockKey);";
            lockCmd.Parameters.AddWithValue("LockKey", MigrationLockKey);
            await lockCmd.ExecuteNonQueryAsync(cancellationToken);
        }

        try
        {
            await EnsureJournalTableAsync(connection, cancellationToken);

            var manifestPath = Path.Combine(migrationsDirectory, ManifestFileName);
            if (!File.Exists(manifestPath))
            {
                logger.LogWarning("Migration manifest {Manifest} not found; skipping migrations", manifestPath);
                return;
            }

            var scriptNames = (await File.ReadAllLinesAsync(manifestPath, cancellationToken))
                .Select(line => line.Trim())
                .Where(line => line.Length > 0 && !line.StartsWith('#'))
                .ToList();

            foreach (var scriptName in scriptNames)
            {
                var scriptPath = Path.Combine(migrationsDirectory, scriptName);
                if (!File.Exists(scriptPath))
                {
                    logger.LogError("Migration {Script} is listed in {Manifest} but the file doesn't exist; skipping it", scriptName, ManifestFileName);
                    continue;
                }

                if (await IsAppliedAsync(connection, scriptName, cancellationToken))
                {
                    logger.LogInformation("Skipping migration {Script} (already applied)", scriptName);
                    continue;
                }

                logger.LogInformation("Applying migration {Script}", scriptName);
                var sql = await File.ReadAllTextAsync(scriptPath, cancellationToken);

                await using (var cmd = connection.CreateCommand())
                {
                    cmd.CommandText = sql;
                    cmd.CommandTimeout = 120;
                    await cmd.ExecuteNonQueryAsync(cancellationToken);
                }

                await using (var insertCmd = connection.CreateCommand())
                {
                    insertCmd.CommandText = "INSERT INTO SchemaMigrations (ScriptName) VALUES (@ScriptName);";
                    insertCmd.Parameters.AddWithValue("@ScriptName", scriptName);
                    await insertCmd.ExecuteNonQueryAsync(cancellationToken);
                }

                logger.LogInformation("Applied migration {Script}", scriptName);
            }
        }
        finally
        {
            await using var unlockCmd = connection.CreateCommand();
            unlockCmd.CommandText = "SELECT pg_advisory_unlock(@LockKey);";
            unlockCmd.Parameters.AddWithValue("LockKey", MigrationLockKey);
            await unlockCmd.ExecuteNonQueryAsync(cancellationToken);
        }
    }

    /// <summary>
    /// A managed Postgres free/serverless tier can auto-pause after inactivity and take
    /// well over a plain connection timeout to wake — and since this now runs before the
    /// app can serve any traffic, a paused DB on the first request after a deploy must not
    /// crash startup.
    /// </summary>
    private async Task OpenWithRetryAsync(NpgsqlConnection connection, CancellationToken cancellationToken)
    {
        for (var attempt = 1; ; attempt++)
        {
            try
            {
                await connection.OpenAsync(cancellationToken);
                return;
            }
            catch (NpgsqlException ex) when (attempt < MaxConnectAttempts)
            {
                var delay = TimeSpan.FromSeconds(5 * attempt);
                logger.LogWarning(ex, "Database connection attempt {Attempt}/{Max} failed; retrying in {Delay}s (likely waking from auto-pause)", attempt, MaxConnectAttempts, delay.TotalSeconds);
                await Task.Delay(delay, cancellationToken);
            }
        }
    }

    private static async Task EnsureJournalTableAsync(NpgsqlConnection connection, CancellationToken cancellationToken)
    {
        await using var cmd = connection.CreateCommand();
        cmd.CommandText = """
            CREATE TABLE IF NOT EXISTS SchemaMigrations (
                ScriptName VARCHAR(255) NOT NULL PRIMARY KEY,
                AppliedAt TIMESTAMP NOT NULL DEFAULT (now())
            );
            """;
        await cmd.ExecuteNonQueryAsync(cancellationToken);
    }

    private static async Task<bool> IsAppliedAsync(NpgsqlConnection connection, string scriptName, CancellationToken cancellationToken)
    {
        await using var cmd = connection.CreateCommand();
        cmd.CommandText = "SELECT COUNT(1) FROM SchemaMigrations WHERE ScriptName = @ScriptName;";
        cmd.Parameters.AddWithValue("@ScriptName", scriptName);
        var count = (long)(await cmd.ExecuteScalarAsync(cancellationToken))!;
        return count > 0;
    }
}
