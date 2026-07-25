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
        Ok(await service.GetSummaryAsync(User.IsInRole(UserRoles.Admin)));

    [HttpGet("charts")]
    public async Task<ActionResult<DashboardChartsDto>> GetCharts() => Ok(await service.GetChartsAsync());
}
