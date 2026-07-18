using Dapper;
using FruitWholesale.Application.Common.Interfaces;
using FruitWholesale.Domain.Entities;
using FruitWholesale.Domain.Enums;
using FruitWholesale.Shared.Pagination;

namespace FruitWholesale.Infrastructure.Repositories;

public class SupplierPaymentRepository(IDbConnectionFactory connectionFactory, ILedgerService ledgerService) : ISupplierPaymentRepository
{
    public async Task<SupplierPayment?> GetByIdAsync(int supplierPaymentId)
    {
        using var connection = connectionFactory.CreateConnection();
        const string sql = """
            SELECT sp.*, s.SupplierName FROM dbo.SupplierPayments sp
            INNER JOIN dbo.SupplierMaster s ON s.SupplierID = sp.SupplierID
            WHERE sp.SupplierPaymentID = @SupplierPaymentID;
            """;
        return await connection.QueryFirstOrDefaultAsync<SupplierPayment>(sql, new { SupplierPaymentID = supplierPaymentId });
    }

    public async Task<PaginatedList<SupplierPayment>> GetPagedAsync(PaginationRequest request, int? supplierId, DateTime? fromDate, DateTime? toDate)
    {
        using var connection = connectionFactory.CreateConnection();
        const string sql = """
            SELECT COUNT(*) FROM dbo.SupplierPayments sp
            INNER JOIN dbo.SupplierMaster s ON s.SupplierID = sp.SupplierID
            WHERE (@SupplierID IS NULL OR sp.SupplierID = @SupplierID)
              AND (@FromDate IS NULL OR sp.PaymentDate >= @FromDate)
              AND (@ToDate IS NULL OR sp.PaymentDate <= @ToDate)
              AND (@SearchTerm IS NULL OR s.SupplierName LIKE @SearchPattern OR sp.ReferenceNumber LIKE @SearchPattern);

            SELECT sp.*, s.SupplierName FROM dbo.SupplierPayments sp
            INNER JOIN dbo.SupplierMaster s ON s.SupplierID = sp.SupplierID
            WHERE (@SupplierID IS NULL OR sp.SupplierID = @SupplierID)
              AND (@FromDate IS NULL OR sp.PaymentDate >= @FromDate)
              AND (@ToDate IS NULL OR sp.PaymentDate <= @ToDate)
              AND (@SearchTerm IS NULL OR s.SupplierName LIKE @SearchPattern OR sp.ReferenceNumber LIKE @SearchPattern)
            ORDER BY sp.PaymentDate DESC, sp.SupplierPaymentID DESC
            OFFSET @Offset ROWS FETCH NEXT @PageSize ROWS ONLY;
            """;
        using var multi = await connection.QueryMultipleAsync(sql, new
        {
            SupplierID = supplierId,
            FromDate = fromDate,
            ToDate = toDate,
            SearchTerm = request.SearchTerm,
            SearchPattern = $"%{request.SearchTerm}%",
            request.Offset,
            request.PageSize
        });
        var total = await multi.ReadSingleAsync<int>();
        var items = (await multi.ReadAsync<SupplierPayment>()).ToList();
        return new PaginatedList<SupplierPayment>(items, total, request.PageNumber, request.PageSize);
    }

    public async Task<int> CreateAsync(SupplierPayment payment)
    {
        using var connection = connectionFactory.CreateConnection();
        connection.Open();
        using var transaction = connection.BeginTransaction();
        try
        {
            const string insertSql = """
                INSERT INTO dbo.SupplierPayments (PaymentDate, SupplierID, AmountPaid, DiscountAmount, PaymentMode, ReferenceNumber, Remarks, CreatedBy)
                OUTPUT INSERTED.SupplierPaymentID
                VALUES (@PaymentDate, @SupplierID, @AmountPaid, @DiscountAmount, @PaymentMode, @ReferenceNumber, @Remarks, @CreatedBy);
                """;
            var paymentId = await connection.QuerySingleAsync<int>(insertSql, payment, transaction);

            await ledgerService.AddSupplierLedgerEntryAsync(connection, transaction, payment.SupplierID, payment.PaymentDate,
                LedgerTransactionTypes.SupplierPayment, paymentId, 0, payment.AmountPaid + payment.DiscountAmount,
                SupplierPaymentNarration(payment));
            await ledgerService.RecalculateSupplierLedgerAsync(connection, transaction, payment.SupplierID);

            await ledgerService.AddCashLedgerEntryAsync(connection, transaction, payment.PaymentDate,
                LedgerTransactionTypes.SupplierPayment, ReferenceTables.SupplierPayments, paymentId, payment.PaymentMode,
                0, payment.AmountPaid, $"Payment to supplier (ID {payment.SupplierID})");
            await ledgerService.RecalculateCashLedgerAsync(connection, transaction);

            transaction.Commit();
            return paymentId;
        }
        catch
        {
            transaction.Rollback();
            throw;
        }
    }

    public async Task UpdateAsync(SupplierPayment payment)
    {
        using var connection = connectionFactory.CreateConnection();
        connection.Open();
        using var transaction = connection.BeginTransaction();
        try
        {
            var oldSupplierId = await connection.ExecuteScalarAsync<int>(
                "SELECT SupplierID FROM dbo.SupplierPayments WHERE SupplierPaymentID = @SupplierPaymentID", new { payment.SupplierPaymentID }, transaction);

            const string updateSql = """
                UPDATE dbo.SupplierPayments
                SET PaymentDate = @PaymentDate, SupplierID = @SupplierID, AmountPaid = @AmountPaid,
                    DiscountAmount = @DiscountAmount, PaymentMode = @PaymentMode, ReferenceNumber = @ReferenceNumber,
                    Remarks = @Remarks, UpdatedAt = SYSUTCDATETIME()
                WHERE SupplierPaymentID = @SupplierPaymentID;
                """;
            await connection.ExecuteAsync(updateSql, payment, transaction);

            await ledgerService.RemoveSupplierLedgerEntriesForReferenceAsync(connection, transaction, LedgerTransactionTypes.SupplierPayment, payment.SupplierPaymentID);
            await ledgerService.AddSupplierLedgerEntryAsync(connection, transaction, payment.SupplierID, payment.PaymentDate,
                LedgerTransactionTypes.SupplierPayment, payment.SupplierPaymentID, 0, payment.AmountPaid + payment.DiscountAmount,
                SupplierPaymentNarration(payment));
            await ledgerService.RecalculateSupplierLedgerAsync(connection, transaction, payment.SupplierID);
            if (oldSupplierId != payment.SupplierID)
            {
                await ledgerService.RecalculateSupplierLedgerAsync(connection, transaction, oldSupplierId);
            }

            await ledgerService.RemoveCashLedgerEntriesForReferenceAsync(connection, transaction, ReferenceTables.SupplierPayments, payment.SupplierPaymentID);
            await ledgerService.AddCashLedgerEntryAsync(connection, transaction, payment.PaymentDate,
                LedgerTransactionTypes.SupplierPayment, ReferenceTables.SupplierPayments, payment.SupplierPaymentID, payment.PaymentMode,
                0, payment.AmountPaid, $"Payment to supplier (ID {payment.SupplierID})");
            await ledgerService.RecalculateCashLedgerAsync(connection, transaction);

            transaction.Commit();
        }
        catch
        {
            transaction.Rollback();
            throw;
        }
    }

    public async Task DeleteAsync(int supplierPaymentId)
    {
        using var connection = connectionFactory.CreateConnection();
        connection.Open();
        using var transaction = connection.BeginTransaction();
        try
        {
            var supplierId = await connection.ExecuteScalarAsync<int>(
                "SELECT SupplierID FROM dbo.SupplierPayments WHERE SupplierPaymentID = @SupplierPaymentID", new { SupplierPaymentID = supplierPaymentId }, transaction);

            await ledgerService.RemoveSupplierLedgerEntriesForReferenceAsync(connection, transaction, LedgerTransactionTypes.SupplierPayment, supplierPaymentId);
            await ledgerService.RemoveCashLedgerEntriesForReferenceAsync(connection, transaction, ReferenceTables.SupplierPayments, supplierPaymentId);
            await connection.ExecuteAsync("DELETE FROM dbo.SupplierPayments WHERE SupplierPaymentID = @SupplierPaymentID", new { SupplierPaymentID = supplierPaymentId }, transaction);

            await ledgerService.RecalculateSupplierLedgerAsync(connection, transaction, supplierId);
            await ledgerService.RecalculateCashLedgerAsync(connection, transaction);

            transaction.Commit();
        }
        catch
        {
            transaction.Rollback();
            throw;
        }
    }

    private static string SupplierPaymentNarration(SupplierPayment payment) =>
        payment.DiscountAmount > 0
            ? $"Payment made ({payment.PaymentMode}) + discount {payment.DiscountAmount:0.##}"
            : $"Payment made ({payment.PaymentMode})";
}
