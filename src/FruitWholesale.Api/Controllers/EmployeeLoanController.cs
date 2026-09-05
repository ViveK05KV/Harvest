using FruitWholesale.Application.Common.Interfaces;
using FruitWholesale.Application.DTOs.Employee;
using FruitWholesale.Application.Services;
using FruitWholesale.Domain.Enums;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace FruitWholesale.Api.Controllers;

[Authorize(Roles = $"{UserRoles.Admin},{UserRoles.Manager},{UserRoles.Accountant}")]
public class EmployeeLoanController(IEmployeeLoanService service, ICurrentUserService currentUserService) : ApiControllerBase
{
    [HttpGet("summary")]
    public async Task<ActionResult<List<EmployeeLoanSummaryDto>>> GetSummary() => Ok(await service.GetSummaryAsync());

    [HttpGet("{employeeId:int}/history")]
    public async Task<ActionResult<List<EmployeeLoanHistoryRowDto>>> GetHistory(int employeeId) => Ok(await service.GetHistoryAsync(employeeId));

    [HttpPost("repayments")]
    public async Task<ActionResult<EmployeeLoanRepaymentDto>> CreateRepayment(SaveEmployeeLoanRepaymentDto dto) =>
        FromResult(await service.CreateRepaymentAsync(dto, currentUserService.UserId));

    [HttpPut("repayments/{id:int}")]
    public async Task<ActionResult<EmployeeLoanRepaymentDto>> UpdateRepayment(int id, SaveEmployeeLoanRepaymentDto dto)
    {
        dto.EmployeeLoanRepaymentID = id;
        return FromResult(await service.UpdateRepaymentAsync(dto));
    }

    [HttpDelete("repayments/{id:int}")]
    public async Task<ActionResult> DeleteRepayment(int id)
    {
        await service.DeleteRepaymentAsync(id);
        return NoContent();
    }

    [HttpPost("{employeeId:int}/adjustments")]
    public async Task<ActionResult> ApplyAdjustment(int employeeId, EmployeeLoanAdjustmentDto dto) =>
        FromResult(await service.ApplyAdjustmentAsync(employeeId, dto, currentUserService.UserId));

    [HttpDelete("adjustments/{id:int}")]
    public async Task<ActionResult> DeleteAdjustment(int id) => FromResult(await service.DeleteAdjustmentAsync(id));
}
