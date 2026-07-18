using FruitWholesale.Application.Common.Interfaces;
using FruitWholesale.Application.DTOs.DailyExpense;
using FruitWholesale.Application.Services;
using FruitWholesale.Domain.Enums;
using FruitWholesale.Shared.Pagination;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace FruitWholesale.Api.Controllers;

[Authorize(Roles = $"{UserRoles.Admin},{UserRoles.Manager},{UserRoles.Accountant}")]
public class DailyExpenseController(IDailyExpenseService service, ICurrentUserService currentUserService) : ApiControllerBase
{
    [HttpGet]
    public async Task<ActionResult<PaginatedList<DailyExpenseDto>>> GetPaged(
        [FromQuery] PaginationRequest request, [FromQuery] int? expenseCategoryId, [FromQuery] DateTime? fromDate, [FromQuery] DateTime? toDate) =>
        Ok(await service.GetPagedAsync(request, expenseCategoryId, fromDate, toDate));

    [HttpGet("{id:int}")]
    public async Task<ActionResult<DailyExpenseDto>> GetById(int id) => Ok(await service.GetByIdAsync(id));

    [HttpPost]
    public async Task<ActionResult<DailyExpenseDto>> Create(CreateDailyExpenseDto dto) => FromResult(await service.CreateAsync(dto, currentUserService.UserId));

    [HttpPut("{id:int}")]
    public async Task<ActionResult<DailyExpenseDto>> Update(int id, UpdateDailyExpenseDto dto)
    {
        dto.ExpenseID = id;
        return FromResult(await service.UpdateAsync(dto));
    }

    [HttpDelete("{id:int}")]
    public async Task<ActionResult> Delete(int id)
    {
        await service.DeleteAsync(id);
        return NoContent();
    }
}
