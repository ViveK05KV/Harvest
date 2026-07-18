using FruitWholesale.Application.DTOs.SupplierMaster;
using FruitWholesale.Application.Services;
using FruitWholesale.Domain.Enums;
using FruitWholesale.Shared.Pagination;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace FruitWholesale.Api.Controllers;

[Authorize(Roles = $"{UserRoles.Admin},{UserRoles.Manager},{UserRoles.Accountant}")]
public class SupplierMasterController(ISupplierMasterService service) : ApiControllerBase
{
    [HttpGet]
    public async Task<ActionResult<PaginatedList<SupplierMasterDto>>> GetPaged([FromQuery] PaginationRequest request) =>
        Ok(await service.GetPagedAsync(request));

    [HttpGet("active")]
    public async Task<ActionResult<IReadOnlyList<SupplierMasterDto>>> GetAllActive() => Ok(await service.GetAllActiveAsync());

    [HttpGet("{id:int}")]
    public async Task<ActionResult<SupplierMasterDto>> GetById(int id) => Ok(await service.GetByIdAsync(id));

    [HttpPost]
    public async Task<ActionResult<SupplierMasterDto>> Create(CreateSupplierMasterDto dto) => FromResult(await service.CreateAsync(dto));

    [HttpPut("{id:int}")]
    public async Task<ActionResult<SupplierMasterDto>> Update(int id, UpdateSupplierMasterDto dto)
    {
        dto.SupplierID = id;
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
