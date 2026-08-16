using System.Text;
using System.Text.RegularExpressions;
using FruitWholesale.Application.Common.Interfaces;
using Microsoft.Data.SqlClient;
using Microsoft.Extensions.Logging;

namespace FruitWholesale.Infrastructure.Persistence;

/// <summary>
/// Applies migration scripts listed in database/auto-migrations.txt that haven't already
/// been recorded in dbo.SchemaMigrations, in the order they're listed, on app startup.
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
    private static readonly Regex GoSeparatorPattern = new(@"^\s*GO\s*$", RegexOptions.IgnoreCase | RegexOptions.Compiled);

    public async Task RunAsync(string migrationsDirectory, CancellationToken cancellationToken = default)
    {
        if (!Directory.Exists(migrationsDirectory))
        {
            logger.LogWarning("Migrations directory {Dir} not found; skipping migrations", migrationsDirectory);
            return;
        }

        using var connection = (SqlConnection)connectionFactory.CreateConnection();
        await OpenWithRetryAsync(connection, cancellationToken);

        // Serialize across replicas that might start concurrently.
        await using (var lockCmd = connection.CreateCommand())
        {
            lockCmd.CommandText = "EXEC sp_getapplock @Resource = 'SchemaMigrations', @LockMode = 'Exclusive', @LockOwner = 'Session', @LockTimeout = 60000;";
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

                foreach (var batch in SplitBatches(sql))
                {
                    await using var cmd = connection.CreateCommand();
                    cmd.CommandText = batch;
                    cmd.CommandTimeout = 120;
                    await cmd.ExecuteNonQueryAsync(cancellationToken);
                }

                await using (var insertCmd = connection.CreateCommand())
                {
                    insertCmd.CommandText = "INSERT INTO dbo.SchemaMigrations (ScriptName) VALUES (@ScriptName);";
                    insertCmd.Parameters.AddWithValue("@ScriptName", scriptName);
                    await insertCmd.ExecuteNonQueryAsync(cancellationToken);
                }

                logger.LogInformation("Applied migration {Script}", scriptName);
            }
        }
        finally
        {
            await using var unlockCmd = connection.CreateCommand();
            unlockCmd.CommandText = "EXEC sp_releaseapplock @Resource = 'SchemaMigrations', @LockOwner = 'Session';";
            await unlockCmd.ExecuteNonQueryAsync(cancellationToken);
        }
    }

    /// <summary>
    /// The Azure SQL free tier auto-pauses after inactivity and can take well over a plain
    /// connection timeout to wake — and since this now runs before the app can serve any
    /// traffic, a paused DB on the first request after a deploy must not crash startup.
    /// </summary>
    private async Task OpenWithRetryAsync(SqlConnection connection, CancellationToken cancellationToken)
    {
        for (var attempt = 1; ; attempt++)
        {
            try
            {
                await connection.OpenAsync(cancellationToken);
                return;
            }
            catch (SqlException ex) when (attempt < MaxConnectAttempts)
            {
                var delay = TimeSpan.FromSeconds(5 * attempt);
                logger.LogWarning(ex, "Database connection attempt {Attempt}/{Max} failed; retrying in {Delay}s (likely waking from auto-pause)", attempt, MaxConnectAttempts, delay.TotalSeconds);
                await Task.Delay(delay, cancellationToken);
            }
        }
    }

    private static async Task EnsureJournalTableAsync(SqlConnection connection, CancellationToken cancellationToken)
    {
        await using var cmd = connection.CreateCommand();
        cmd.CommandText = """
            IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'SchemaMigrations')
            BEGIN
                CREATE TABLE dbo.SchemaMigrations (
                    ScriptName NVARCHAR(255) NOT NULL CONSTRAINT PK_SchemaMigrations PRIMARY KEY,
                    AppliedAt DATETIME2 NOT NULL CONSTRAINT DF_SchemaMigrations_AppliedAt DEFAULT (SYSUTCDATETIME())
                );
            END
            """;
        await cmd.ExecuteNonQueryAsync(cancellationToken);
    }

    private static async Task<bool> IsAppliedAsync(SqlConnection connection, string scriptName, CancellationToken cancellationToken)
    {
        await using var cmd = connection.CreateCommand();
        cmd.CommandText = "SELECT COUNT(1) FROM dbo.SchemaMigrations WHERE ScriptName = @ScriptName;";
        cmd.Parameters.AddWithValue("@ScriptName", scriptName);
        var count = (int)(await cmd.ExecuteScalarAsync(cancellationToken))!;
        return count > 0;
    }

    /// <summary>
    /// "GO" is a client-side batch separator (sqlcmd/SSMS), not real T-SQL, so a script
    /// with multiple GO-separated batches can't be sent to SqlCommand as one string.
    /// </summary>
    private static IEnumerable<string> SplitBatches(string sql)
    {
        var lines = sql.Replace("\r\n", "\n").Split('\n');
        var batch = new StringBuilder();

        foreach (var line in lines)
        {
            if (GoSeparatorPattern.IsMatch(line))
            {
                if (batch.Length > 0)
                {
                    yield return batch.ToString();
                    batch.Clear();
                }
            }
            else
            {
                batch.AppendLine(line);
            }
        }

        if (batch.ToString().Trim().Length > 0)
        {
            yield return batch.ToString();
        }
    }
}
