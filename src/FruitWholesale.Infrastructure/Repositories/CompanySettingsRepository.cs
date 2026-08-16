using Dapper;
using FruitWholesale.Application.Common.Interfaces;
using FruitWholesale.Domain.Entities;
using FruitWholesale.Domain.Enums;

namespace FruitWholesale.Infrastructure.Repositories;

public class CompanySettingsRepository(IDbConnectionFactory connectionFactory, ILedgerService ledgerService) : ICompanySettingsRepository
{
    public async Task<CompanySettings?> GetAsync()
    {
        using var connection = connectionFactory.CreateConnection();
        return await connection.QueryFirstOrDefaultAsync<CompanySettings>(
            "SELECT * FROM CompanySettings ORDER BY CompanyID LIMIT 1");
    }

    public async Task<int> CreateAsync(CompanySettings settings)
    {
        using var connection = connectionFactory.CreateConnection();
        connection.Open();
        using var transaction = connection.BeginTransaction();
        try
        {
            const string insertSql = """
                INSERT INTO CompanySettings (CompanyName, OwnerName, Address, Phone, GSTNo, OpeningCashBalance)
                VALUES (@CompanyName, @OwnerName, @Address, @Phone, @GSTNo, @OpeningCashBalance)
                RETURNING CompanyID;
                """;
            var companyId = await connection.QuerySingleAsync<int>(insertSql, settings, transaction);

            if (settings.OpeningCashBalance != 0)
            {
                await ledgerService.AddCashLedgerEntryAsync(connection, transaction, DateTime.UtcNow.Date,
                    LedgerTransactionTypes.OpeningBalance, ReferenceTables.CompanySettings, companyId,
                    Domain.Enums.PaymentModes.Cash, settings.OpeningCashBalance, 0, "Opening cash balance");
                // The company profile can be set up after other cash transactions already exist
                // (e.g. backdated Daily Expenses entered first). AddCashLedgerEntryAsync only
                // chains off whatever the chronologically-latest balance happens to be at insert
                // time, which is meaningless for an opening balance - recalculate immediately so
                // sp_recalculate_cash_ledger_balance's "OpeningBalance always first" rule takes over.
                await ledgerService.RecalculateCashLedgerAsync(connection, transaction);
            }

            transaction.Commit();
            return companyId;
        }
        catch
        {
            transaction.Rollback();
            throw;
        }
    }

    public async Task UpdateAsync(CompanySettings settings)
    {
        using var connection = connectionFactory.CreateConnection();
        const string sql = """
            UPDATE CompanySettings
            SET CompanyName = @CompanyName, OwnerName = @OwnerName, Address = @Address,
                Phone = @Phone, GSTNo = @GSTNo, UpdatedAt = (now() AT TIME ZONE 'utc')
            WHERE CompanyID = @CompanyID;
            """;
        await connection.ExecuteAsync(sql, settings);
    }

    public async Task UpdateLogoAsync(int companyId, string logoUrl)
    {
        using var connection = connectionFactory.CreateConnection();
        await connection.ExecuteAsync(
            "UPDATE CompanySettings SET LogoUrl = @LogoUrl, UpdatedAt = (now() AT TIME ZONE 'utc') WHERE CompanyID = @CompanyID",
            new { LogoUrl = logoUrl, CompanyID = companyId });
    }
}
