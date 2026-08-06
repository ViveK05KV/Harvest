using FruitWholesale.Application.DTOs.ShopMaster;
using FruitWholesale.Application.Services;
using FruitWholesale.Domain.Enums;
using FruitWholesale.Shared.Pagination;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace FruitWholesale.Api.Controllers;

public class ShopMasterController(IShopMasterService service) : ApiControllerBase
{
    private const string BackOfficeRoles = $"{UserRoles.Admin},{UserRoles.Manager},{UserRoles.Accountant}";

    [HttpGet]
    [Authorize(Roles = BackOfficeRoles)]
    public async Task<ActionResult<PaginatedList<ShopMasterDto>>> GetPaged([FromQuery] PaginationRequest request, [FromQuery] int? routeId = null) =>
        Ok(await service.GetPagedAsync(request, routeId));

    // Open to all authenticated roles (including Staff) — needed for the Supply/Collections shop dropdowns.
    [HttpGet("active")]
    public async Task<ActionResult<IReadOnlyList<ShopMasterDto>>> GetAllActive() => Ok(await service.GetAllActiveAsync());

    [HttpGet("{id:int}")]
    [Authorize(Roles = BackOfficeRoles)]
    public async Task<ActionResult<ShopMasterDto>> GetById(int id) => Ok(await service.GetByIdAsync(id));

    [HttpPost]
    [Authorize(Roles = BackOfficeRoles)]
    public async Task<ActionResult<ShopMasterDto>> Create(CreateShopMasterDto dto) => FromResult(await service.CreateAsync(dto));

    [HttpPut("{id:int}")]
    [Authorize(Roles = BackOfficeRoles)]
    public async Task<ActionResult<ShopMasterDto>> Update(int id, UpdateShopMasterDto dto)
    {
        dto.ShopID = id;
        return FromResult(await service.UpdateAsync(dto));
    }

    [HttpPatch("{id:int}/activate")]
    [Authorize(Roles = BackOfficeRoles)]
    public async Task<ActionResult> Activate(int id)
    {
        await service.SetActiveAsync(id, true);
        return NoContent();
    }

    [HttpPatch("{id:int}/deactivate")]
    [Authorize(Roles = BackOfficeRoles)]
    public async Task<ActionResult> Deactivate(int id)
    {
        await service.SetActiveAsync(id, false);
        return NoContent();
    }

    [HttpPost("{id:int}/balance-adjustment")]
    [Authorize(Roles = $"{UserRoles.Admin},{UserRoles.Accountant}")]
    public async Task<ActionResult> ApplyBalanceAdjustment(int id, ShopBalanceAdjustmentDto dto) =>
        FromResult(await service.ApplyBalanceAdjustmentAsync(id, dto));

    [HttpDelete("{id:int}/adjustment/{ledgerId:long}")]
    [Authorize(Roles = $"{UserRoles.Admin},{UserRoles.Accountant}")]
    public async Task<ActionResult> DeleteAdjustment(int id, long ledgerId) =>
        FromResult(await service.DeleteAdjustmentAsync(id, ledgerId));
}
