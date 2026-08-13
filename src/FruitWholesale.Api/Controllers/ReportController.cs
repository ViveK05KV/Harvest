using FruitWholesale.Application.DTOs.Reports;
using FruitWholesale.Application.Services;
using FruitWholesale.Domain.Enums;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace FruitWholesale.Api.Controllers;

[Authorize(Roles = UserRoles.Admin)]
public class ReportController(IReportService service) : ApiControllerBase
{
    [HttpGet("daily-sales")]
    public async Task<ActionResult<List<DailySalesReportRow>>> DailySales([FromQuery] DateTime fromDate, [FromQuery] DateTime toDate, [FromQuery] int? shopId) =>
        Ok(await service.GetDailySalesAsync(fromDate, toDate, shopId));

    [HttpGet("daily-collection")]
    public async Task<ActionResult<List<DailyCollectionReportRow>>> DailyCollection([FromQuery] DateTime fromDate, [FromQuery] DateTime toDate, [FromQuery] int? shopId) =>
        Ok(await service.GetDailyCollectionAsync(fromDate, toDate, shopId));

    [HttpGet("daily-expense")]
    public async Task<ActionResult<List<DailyExpenseReportRow>>> DailyExpense([FromQuery] DateTime fromDate, [FromQuery] DateTime toDate, [FromQuery] int? expenseCategoryId) =>
        Ok(await service.GetDailyExpenseAsync(fromDate, toDate, expenseCategoryId));

    [HttpGet("purchase")]
    public async Task<ActionResult<List<PurchaseReportRow>>> Purchase([FromQuery] DateTime fromDate, [FromQuery] DateTime toDate, [FromQuery] int? supplierId) =>
        Ok(await service.GetPurchaseReportAsync(fromDate, toDate, supplierId));

    [HttpGet("fruit-sales")]
    public async Task<ActionResult<List<FruitSalesReportRow>>> FruitSales([FromQuery] DateTime fromDate, [FromQuery] DateTime toDate) =>
        Ok(await service.GetFruitSalesReportAsync(fromDate, toDate));

    [HttpGet("outstanding")]
    public async Task<ActionResult<List<OutstandingReportRow>>> Outstanding() => Ok(await service.GetOutstandingReportAsync());

    [HttpGet("profit-summary")]
    public async Task<ActionResult<List<ProfitSummaryReportRow>>> ProfitSummary([FromQuery] DateTime fromDate, [FromQuery] DateTime toDate) =>
        Ok(await service.GetProfitSummaryAsync(fromDate, toDate));

    [HttpGet("expense-by-category")]
    public async Task<ActionResult<List<ExpenseByCategoryReportRow>>> ExpenseByCategory([FromQuery] DateTime fromDate, [FromQuery] DateTime toDate) =>
        Ok(await service.GetExpenseByCategoryAsync(fromDate, toDate));

    [HttpGet("salary-by-employee")]
    public async Task<ActionResult<List<SalaryByEmployeeReportRow>>> SalaryByEmployee([FromQuery] DateTime fromDate, [FromQuery] DateTime toDate, [FromQuery] int? employeeId) =>
        Ok(await service.GetSalaryByEmployeeAsync(fromDate, toDate, employeeId));
}
