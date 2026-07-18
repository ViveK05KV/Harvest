using FruitWholesale.Application.DTOs.Stock;
using FruitWholesale.Application.Services;
using FruitWholesale.Domain.Enums;
using FruitWholesale.Shared.Pagination;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace FruitWholesale.Api.Controllers;

[Authorize(Roles = $"{UserRoles.Admin},{UserRoles.Manager},{UserRoles.Accountant}")]
public class StockController(IStockService service) : ApiControllerBase
{
    [HttpGet("current")]
    public async Task<ActionResult<List<CurrentStockDto>>> GetCurrentStock() => Ok(await service.GetCurrentStockAsync());

    [HttpGet("ledger/{fruitId:int}")]
    public async Task<ActionResult<PaginatedList<StockLedgerDto>>> GetStockLedger(
        int fruitId, [FromQuery] DateTime? fromDate, [FromQuery] DateTime? toDate, [FromQuery] PaginationRequest request) =>
        Ok(await service.GetStockLedgerAsync(fruitId, fromDate, toDate, request));

    [HttpPost("adjustment")]
    [Authorize(Roles = $"{UserRoles.Admin},{UserRoles.Manager}")]
    public async Task<ActionResult> ApplyAdjustment(StockAdjustmentDto dto) => FromResult(await service.ApplyAdjustmentAsync(dto));
}
