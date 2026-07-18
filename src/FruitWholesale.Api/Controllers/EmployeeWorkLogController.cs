using FruitWholesale.Application.Common.Interfaces;
using FruitWholesale.Application.DTOs.Employee;
using FruitWholesale.Application.Services;
using FruitWholesale.Domain.Enums;
using FruitWholesale.Shared.Pagination;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace FruitWholesale.Api.Controllers;

[Authorize(Roles = $"{UserRoles.Admin},{UserRoles.Manager},{UserRoles.Accountant}")]
public class EmployeeWorkLogController(IEmployeeWorkLogService service, ICurrentUserService currentUserService) : ApiControllerBase
{
    [HttpGet]
    public async Task<ActionResult<PaginatedList<EmployeeWorkLogDto>>> GetPaged(
        [FromQuery] PaginationRequest request, [FromQuery] int? employeeId, [FromQuery] DateTime? fromDate, [FromQuery] DateTime? toDate) =>
        Ok(await service.GetPagedAsync(request, employeeId, fromDate, toDate));

    [HttpGet("{id:int}")]
    public async Task<ActionResult<EmployeeWorkLogDto>> GetById(int id) => Ok(await service.GetByIdAsync(id));

    [HttpPost]
    public async Task<ActionResult<EmployeeWorkLogDto>> Create(SaveEmployeeWorkLogDto dto) =>
        FromResult(await service.CreateAsync(dto, currentUserService.UserId));

    [HttpPut("{id:int}")]
    public async Task<ActionResult<EmployeeWorkLogDto>> Update(int id, SaveEmployeeWorkLogDto dto)
    {
        dto.EmployeeWorkLogID = id;
        return FromResult(await service.UpdateAsync(dto));
    }

    [HttpDelete("{id:int}")]
    public async Task<ActionResult> Delete(int id)
    {
        await service.DeleteAsync(id);
        return NoContent();
    }
}
