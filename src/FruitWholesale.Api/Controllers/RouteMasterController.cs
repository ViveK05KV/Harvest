using FruitWholesale.Application.DTOs.RouteMaster;
using FruitWholesale.Application.Services;
using FruitWholesale.Domain.Enums;
using FruitWholesale.Shared.Pagination;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace FruitWholesale.Api.Controllers;

[Authorize(Roles = $"{UserRoles.Admin},{UserRoles.Manager},{UserRoles.Accountant}")]
public class RouteMasterController(IRouteMasterService service) : ApiControllerBase
{
    [HttpGet]
    public async Task<ActionResult<PaginatedList<RouteMasterDto>>> GetPaged([FromQuery] PaginationRequest request) =>
        Ok(await service.GetPagedAsync(request));

    [HttpGet("active")]
    public async Task<ActionResult<IReadOnlyList<RouteMasterDto>>> GetAllActive() => Ok(await service.GetAllActiveAsync());

    [HttpGet("{id:int}")]
    public async Task<ActionResult<RouteMasterDto>> GetById(int id) => Ok(await service.GetByIdAsync(id));

    [HttpPost]
    public async Task<ActionResult<RouteMasterDto>> Create(CreateRouteMasterDto dto) => FromResult(await service.CreateAsync(dto));

    [HttpPut("{id:int}")]
    public async Task<ActionResult<RouteMasterDto>> Update(int id, UpdateRouteMasterDto dto)
    {
        dto.RouteID = id;
        return FromResult(await service.UpdateAsync(dto));
    }

    [HttpPatch("{id:int}/activate")]
    public async Task<ActionResult> Activate(int id) => FromResult(await service.SetActiveAsync(id, true));

    [HttpPatch("{id:int}/deactivate")]
    public async Task<ActionResult> Deactivate(int id) => FromResult(await service.SetActiveAsync(id, false));
}
