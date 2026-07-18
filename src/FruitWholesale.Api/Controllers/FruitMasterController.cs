using FruitWholesale.Application.DTOs.FruitMaster;
using FruitWholesale.Application.Services;
using FruitWholesale.Domain.Enums;
using FruitWholesale.Shared.Pagination;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace FruitWholesale.Api.Controllers;

public class FruitMasterController(IFruitMasterService service) : ApiControllerBase
{
    private const string BackOfficeRoles = $"{UserRoles.Admin},{UserRoles.Manager},{UserRoles.Accountant}";

    [HttpGet]
    [Authorize(Roles = BackOfficeRoles)]
    public async Task<ActionResult<PaginatedList<FruitMasterDto>>> GetPaged([FromQuery] PaginationRequest request) =>
        Ok(await service.GetPagedAsync(request));

    // Open to all authenticated roles (including Staff) — needed for the Supply fruit dropdown.
    [HttpGet("active")]
    public async Task<ActionResult<IReadOnlyList<FruitMasterDto>>> GetAllActive() => Ok(await service.GetAllActiveAsync());

    [HttpGet("{id:int}")]
    [Authorize(Roles = BackOfficeRoles)]
    public async Task<ActionResult<FruitMasterDto>> GetById(int id) => Ok(await service.GetByIdAsync(id));

    [HttpPost]
    [Authorize(Roles = BackOfficeRoles)]
    public async Task<ActionResult<FruitMasterDto>> Create(CreateFruitMasterDto dto) => FromResult(await service.CreateAsync(dto));

    [HttpPut("{id:int}")]
    [Authorize(Roles = BackOfficeRoles)]
    public async Task<ActionResult<FruitMasterDto>> Update(int id, UpdateFruitMasterDto dto)
    {
        dto.FruitID = id;
        return FromResult(await service.UpdateAsync(dto));
    }

    [HttpPatch("{id:int}/activate")]
    [Authorize(Roles = BackOfficeRoles)]
    public async Task<ActionResult> Activate(int id) => FromResult(await service.SetActiveAsync(id, true));

    [HttpPatch("{id:int}/deactivate")]
    [Authorize(Roles = BackOfficeRoles)]
    public async Task<ActionResult> Deactivate(int id) => FromResult(await service.SetActiveAsync(id, false));
}
