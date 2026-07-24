using FruitWholesale.Application.DTOs.Profit;
using FruitWholesale.Application.Services;
using FruitWholesale.Domain.Enums;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace FruitWholesale.Api.Controllers;

[Authorize(Roles = $"{UserRoles.Admin},{UserRoles.Manager},{UserRoles.Accountant}")]
public class ProfitController(IProfitService service) : ApiControllerBase
{
    [HttpGet("shop-daily")]
    public async Task<ActionResult<List<ShopDailyProfitRow>>> ShopDaily([FromQuery] int? shopId, [FromQuery] DateTime? fromDate, [FromQuery] DateTime? toDate) =>
        Ok(await service.GetShopDailyProfitAsync(shopId, fromDate, toDate));

    [HttpGet("shop-summary")]
    public async Task<ActionResult<List<ShopProfitSummaryRow>>> ShopSummary([FromQuery] DateTime? fromDate, [FromQuery] DateTime? toDate) =>
        Ok(await service.GetShopProfitSummaryAsync(fromDate, toDate));

    [HttpGet("fruit-summary")]
    public async Task<ActionResult<List<FruitProfitSummaryRow>>> FruitSummary([FromQuery] DateTime? fromDate, [FromQuery] DateTime? toDate) =>
        Ok(await service.GetFruitProfitSummaryAsync(fromDate, toDate));

    [HttpGet("shop-fruit")]
    public async Task<ActionResult<List<ShopFruitProfitRow>>> ShopFruit([FromQuery] int? shopId, [FromQuery] DateTime? fromDate, [FromQuery] DateTime? toDate) =>
        Ok(await service.GetShopFruitProfitAsync(shopId, fromDate, toDate));

    [HttpGet("business-total")]
    public async Task<ActionResult<BusinessProfitTotal>> BusinessTotal() =>
        Ok(await service.GetBusinessTotalProfitAsync());
}
