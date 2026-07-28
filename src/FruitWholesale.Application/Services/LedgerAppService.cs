using AutoMapper;
using FruitWholesale.Application.Common.Interfaces;
using FruitWholesale.Application.DTOs.Ledger;
using FruitWholesale.Shared.Pagination;

namespace FruitWholesale.Application.Services;

public interface ILedgerAppService
{
    Task<PaginatedList<ShopLedgerDto>> GetShopLedgerAsync(int shopId, DateTime? fromDate, DateTime? toDate, PaginationRequest request);
    Task<PaginatedList<SupplierLedgerDto>> GetSupplierLedgerAsync(int supplierId, DateTime? fromDate, DateTime? toDate, PaginationRequest request);
    Task<PaginatedList<CashLedgerDto>> GetCashLedgerAsync(DateTime? fromDate, DateTime? toDate, string? transactionType, PaginationRequest request);
}

public class LedgerAppService(ILedgerService ledgerService, IMapper mapper) : ILedgerAppService
{
    public async Task<PaginatedList<ShopLedgerDto>> GetShopLedgerAsync(int shopId, DateTime? fromDate, DateTime? toDate, PaginationRequest request)
    {
        var result = await ledgerService.GetShopLedgerAsync(shopId, fromDate, toDate, request.PageNumber, request.PageSize);
        return new PaginatedList<ShopLedgerDto>(mapper.Map<List<ShopLedgerDto>>(result.Items), result.TotalCount, request.PageNumber, request.PageSize);
    }

    public async Task<PaginatedList<SupplierLedgerDto>> GetSupplierLedgerAsync(int supplierId, DateTime? fromDate, DateTime? toDate, PaginationRequest request)
    {
        var result = await ledgerService.GetSupplierLedgerAsync(supplierId, fromDate, toDate, request.PageNumber, request.PageSize);
        return new PaginatedList<SupplierLedgerDto>(mapper.Map<List<SupplierLedgerDto>>(result.Items), result.TotalCount, request.PageNumber, request.PageSize);
    }

    public async Task<PaginatedList<CashLedgerDto>> GetCashLedgerAsync(DateTime? fromDate, DateTime? toDate, string? transactionType, PaginationRequest request)
    {
        var result = await ledgerService.GetCashLedgerAsync(fromDate, toDate, transactionType, request.PageNumber, request.PageSize);
        return new PaginatedList<CashLedgerDto>(mapper.Map<List<CashLedgerDto>>(result.Items), result.TotalCount, request.PageNumber, request.PageSize);
    }
}
