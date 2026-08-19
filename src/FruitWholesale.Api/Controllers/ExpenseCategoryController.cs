using FruitWholesale.Application.DTOs.ExpenseCategory;
using FruitWholesale.Application.Services;
using FruitWholesale.Domain.Enums;
using FruitWholesale.Shared.Pagination;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace FruitWholesale.Api.Controllers;

[Authorize(Roles = $"{UserRoles.Admin},{UserRoles.Manager},{UserRoles.Accountant}")]
public class ExpenseCategoryController(IExpenseCategoryService service) : ApiControllerBase
{
    [HttpGet]
    public async Task<ActionResult<PaginatedList<ExpenseCategoryDto>>> GetPaged([FromQuery] PaginationRequest request) =>
        Ok(await service.GetPagedAsync(request));

    [HttpGet("active")]
    public async Task<ActionResult<IReadOnlyList<ExpenseCategoryDto>>> GetAllActive() => Ok(await service.GetAllActiveAsync());

    [HttpGet("{id:int}")]
    public async Task<ActionResult<ExpenseCategoryDto>> GetById(int id) => Ok(await service.GetByIdAsync(id));

    [HttpPost]
    public async Task<ActionResult<ExpenseCategoryDto>> Create(CreateExpenseCategoryDto dto) => FromResult(await service.CreateAsync(dto));

    [HttpPut("{id:int}")]
    public async Task<ActionResult<ExpenseCategoryDto>> Update(int id, UpdateExpenseCategoryDto dto)
    {
        dto.ExpenseCategoryID = id;
        return FromResult(await service.UpdateAsync(dto));
    }

    [HttpPatch("{id:int}/activate")]
    public async Task<ActionResult> Activate(int id)
    {
        await service.SetActiveAsync(id, true);
        return NoContent();
    }

    [HttpPatch("{id:int}/deactivate")]
    public async Task<ActionResult> Deactivate(int id)
    {
        await service.SetActiveAsync(id, false);
        return NoContent();
    }

    [HttpDelete("{id:int}")]
    public async Task<ActionResult> Delete(int id) => FromResult(await service.DeleteAsync(id));
}
