using FruitWholesale.Application.DTOs.Dashboard;
using FruitWholesale.Application.Services;
using FruitWholesale.Domain.Enums;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace FruitWholesale.Api.Controllers;

[Authorize(Roles = $"{UserRoles.Admin},{UserRoles.Manager},{UserRoles.Accountant}")]
public class DashboardController(IDashboardService service) : ApiControllerBase
{
    [HttpGet("summary")]
    public async Task<ActionResult<DashboardSummaryDto>> GetSummary() =>
        Ok(await service.GetSummaryAsync(User.IsInRole(UserRoles.Admin) || User.IsInRole(UserRoles.Accountant)));

    [HttpGet("charts")]
    public async Task<ActionResult<DashboardChartsDto>> GetCharts() => Ok(await service.GetChartsAsync());

    [HttpGet("sales-trend")]
    public async Task<ActionResult<List<TrendPointDto>>> GetSalesTrend([FromQuery] string period = DashboardPeriods.ThisWeek) =>
        Ok(await service.GetSalesTrendAsync(period));

    [HttpGet("sales-vs-purchases")]
    public async Task<ActionResult<SalesVsPurchasesDto>> GetSalesVsPurchases([FromQuery] string period = DashboardPeriods.ThisWeek) =>
        Ok(await service.GetSalesVsPurchasesAsync(period));
}
