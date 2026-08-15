using FruitWholesale.Application.DTOs.Collection;
using FruitWholesale.Application.DTOs.Supply;
using FruitWholesale.Domain.Entities;
using FruitWholesale.Shared.Pagination;

namespace FruitWholesale.Application.Common.Interfaces;

public interface ISupplyRepository
{
    Task<Supply?> GetByIdAsync(int supplyId);
    Task<PaginatedList<Supply>> GetPagedAsync(PaginationRequest request, int? shopId, DateTime? fromDate, DateTime? toDate);
    Task<int> CreateAsync(Supply supply);
    Task UpdateAsync(Supply supply);
    Task DeleteAsync(int supplyId);
    Task<bool> InvoiceNoExistsAsync(string invoiceNo, int? excludeSupplyId = null);
    Task<string> GenerateNextInvoiceNoAsync();
    Task<SupplyBillExtrasDto> GetBillExtrasAsync(int supplyId);
}

public interface IPurchaseRepository
{
    Task<Purchase?> GetByIdAsync(int purchaseId);
    Task<PaginatedList<Purchase>> GetPagedAsync(PaginationRequest request, int? supplierId, DateTime? fromDate, DateTime? toDate);
    Task<int> CreateAsync(Purchase purchase);
    Task UpdateAsync(Purchase purchase);
    Task DeleteAsync(int purchaseId);
    Task<bool> InvoiceNoExistsAsync(string invoiceNo, int? excludePurchaseId = null);
    Task<string> GenerateNextInvoiceNoAsync();
}

public interface IShopReturnRepository
{
    Task<ShopReturn?> GetByIdAsync(int shopReturnId);
    Task<PaginatedList<ShopReturn>> GetPagedAsync(PaginationRequest request, int? shopId, DateTime? fromDate, DateTime? toDate);
    Task<int> CreateAsync(ShopReturn shopReturn);
    Task UpdateAsync(ShopReturn shopReturn);
    Task DeleteAsync(int shopReturnId);
    Task<bool> ReferenceNoExistsAsync(string referenceNo, int? excludeShopReturnId = null);
    Task<string> GenerateNextReferenceNoAsync();
}

public interface ISupplierReturnRepository
{
    Task<SupplierReturn?> GetByIdAsync(int supplierReturnId);
    Task<PaginatedList<SupplierReturn>> GetPagedAsync(PaginationRequest request, int? supplierId, DateTime? fromDate, DateTime? toDate);
    Task<int> CreateAsync(SupplierReturn supplierReturn);
    Task UpdateAsync(SupplierReturn supplierReturn);
    Task DeleteAsync(int supplierReturnId);
    Task<bool> ReferenceNoExistsAsync(string referenceNo, int? excludeSupplierReturnId = null);
    Task<string> GenerateNextReferenceNoAsync();
}

public interface ICollectionRepository
{
    Task<Collection?> GetByIdAsync(int collectionId);
    Task<PaginatedList<Collection>> GetPagedAsync(PaginationRequest request, int? shopId, DateTime? fromDate, DateTime? toDate);
    Task<int> CreateAsync(Collection collection);
    Task UpdateAsync(Collection collection);
    Task DeleteAsync(int collectionId);
    Task<CollectionSettlementPreviewDto> GetPendingSettlementPreviewAsync(int shopId);
    Task<CollectionSettlementResultDto> SettlePendingAsync(int shopId, DateTime settlementDate, int? createdBy);
}

public interface ISupplierPaymentRepository
{
    Task<SupplierPayment?> GetByIdAsync(int supplierPaymentId);
    Task<PaginatedList<SupplierPayment>> GetPagedAsync(PaginationRequest request, int? supplierId, DateTime? fromDate, DateTime? toDate);
    Task<int> CreateAsync(SupplierPayment payment);
    Task UpdateAsync(SupplierPayment payment);
    Task DeleteAsync(int supplierPaymentId);
}

public interface IDailyExpenseRepository
{
    Task<DailyExpense?> GetByIdAsync(int expenseId);
    Task<PaginatedList<DailyExpense>> GetPagedAsync(PaginationRequest request, int? expenseCategoryId, DateTime? fromDate, DateTime? toDate);
    Task<int> CreateAsync(DailyExpense expense);
    Task UpdateAsync(DailyExpense expense);
    Task DeleteAsync(int expenseId);
}

public interface IEmployeeWorkLogRepository
{
    Task<EmployeeWorkLog?> GetByIdAsync(int employeeWorkLogId);
    Task<PaginatedList<EmployeeWorkLog>> GetPagedAsync(PaginationRequest request, int? employeeId, DateTime? fromDate, DateTime? toDate);
    Task<int> CreateAsync(EmployeeWorkLog workLog);
    Task UpdateAsync(EmployeeWorkLog workLog);
    Task DeleteAsync(int employeeWorkLogId);
}
