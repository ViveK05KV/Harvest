using FruitWholesale.Application.DTOs.Ledger;
using FruitWholesale.Application.Services;
using FruitWholesale.Domain.Enums;
using FruitWholesale.Shared.Pagination;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace FruitWholesale.Api.Controllers;

[Route("api/ledger")]
[Authorize(Roles = $"{UserRoles.Admin},{UserRoles.Manager},{UserRoles.Accountant}")]
public class LedgerController(ILedgerAppService service) : ApiControllerBase
{
    [HttpGet("shop/{shopId:int}")]
    public async Task<ActionResult<PaginatedList<ShopLedgerDto>>> GetShopLedger(
        int shopId, [FromQuery] DateTime? fromDate, [FromQuery] DateTime? toDate, [FromQuery] PaginationRequest request) =>
        Ok(await service.GetShopLedgerAsync(shopId, fromDate, toDate, request));

    [HttpGet("supplier/{supplierId:int}")]
    public async Task<ActionResult<PaginatedList<SupplierLedgerDto>>> GetSupplierLedger(
        int supplierId, [FromQuery] DateTime? fromDate, [FromQuery] DateTime? toDate, [FromQuery] PaginationRequest request) =>
        Ok(await service.GetSupplierLedgerAsync(supplierId, fromDate, toDate, request));

    [HttpGet("cash")]
    public async Task<ActionResult<PaginatedList<CashLedgerDto>>> GetCashLedger(
        [FromQuery] DateTime? fromDate, [FromQuery] DateTime? toDate, [FromQuery] string? transactionType,
        [FromQuery] bool newestFirst, [FromQuery] PaginationRequest request) =>
        Ok(await service.GetCashLedgerAsync(fromDate, toDate, transactionType, newestFirst, request));

    [HttpGet("cash/balance")]
    public async Task<ActionResult<decimal>> GetCurrentCashBalance() => Ok(await service.GetCurrentCashBalanceAsync());
}
