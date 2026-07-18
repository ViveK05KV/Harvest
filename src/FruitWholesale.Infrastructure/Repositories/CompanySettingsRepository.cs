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
            "SELECT TOP 1 * FROM dbo.CompanySettings ORDER BY CompanyID");
    }

    public async Task<int> CreateAsync(CompanySettings settings)
    {
        using var connection = connectionFactory.CreateConnection();
        connection.Open();
        using var transaction = connection.BeginTransaction();
        try
        {
            const string insertSql = """
                INSERT INTO dbo.CompanySettings (CompanyName, OwnerName, Address, Phone, GSTNo, OpeningCashBalance)
                OUTPUT INSERTED.CompanyID
                VALUES (@CompanyName, @OwnerName, @Address, @Phone, @GSTNo, @OpeningCashBalance);
                """;
            var companyId = await connection.QuerySingleAsync<int>(insertSql, settings, transaction);

            if (settings.OpeningCashBalance != 0)
            {
                await ledgerService.AddCashLedgerEntryAsync(connection, transaction, DateTime.UtcNow.Date,
                    LedgerTransactionTypes.OpeningBalance, ReferenceTables.CompanySettings, companyId,
                    Domain.Enums.PaymentModes.Cash, settings.OpeningCashBalance, 0, "Opening cash balance");
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
            UPDATE dbo.CompanySettings
            SET CompanyName = @CompanyName, OwnerName = @OwnerName, Address = @Address,
                Phone = @Phone, GSTNo = @GSTNo, UpdatedAt = SYSUTCDATETIME()
            WHERE CompanyID = @CompanyID;
            """;
        await connection.ExecuteAsync(sql, settings);
    }

    public async Task UpdateLogoAsync(int companyId, string logoUrl)
    {
        using var connection = connectionFactory.CreateConnection();
        await connection.ExecuteAsync(
            "UPDATE dbo.CompanySettings SET LogoUrl = @LogoUrl, UpdatedAt = SYSUTCDATETIME() WHERE CompanyID = @CompanyID",
            new { LogoUrl = logoUrl, CompanyID = companyId });
    }
}
