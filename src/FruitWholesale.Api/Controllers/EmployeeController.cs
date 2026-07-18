using FruitWholesale.Application.DTOs.Employee;
using FruitWholesale.Application.Services;
using FruitWholesale.Domain.Enums;
using FruitWholesale.Shared.Pagination;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace FruitWholesale.Api.Controllers;

[Authorize(Roles = $"{UserRoles.Admin},{UserRoles.Manager},{UserRoles.Accountant}")]
public class EmployeeController(IEmployeeService service) : ApiControllerBase
{
    [HttpGet]
    public async Task<ActionResult<PaginatedList<EmployeeDto>>> GetPaged([FromQuery] PaginationRequest request) =>
        Ok(await service.GetPagedAsync(request));

    [HttpGet("active")]
    public async Task<ActionResult<IReadOnlyList<EmployeeDto>>> GetAllActive() => Ok(await service.GetAllActiveAsync());

    [HttpGet("{id:int}")]
    public async Task<ActionResult<EmployeeDto>> GetById(int id) => Ok(await service.GetByIdAsync(id));

    [HttpPost]
    public async Task<ActionResult<EmployeeDto>> Create(CreateEmployeeDto dto) => FromResult(await service.CreateAsync(dto));

    [HttpPut("{id:int}")]
    public async Task<ActionResult<EmployeeDto>> Update(int id, UpdateEmployeeDto dto)
    {
        dto.EmployeeID = id;
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
}
