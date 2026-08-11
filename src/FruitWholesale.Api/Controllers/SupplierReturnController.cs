using FruitWholesale.Application.Common.Interfaces;
using FruitWholesale.Application.DTOs.SupplierReturn;
using FruitWholesale.Application.Services;
using FruitWholesale.Domain.Enums;
using FruitWholesale.Shared.Pagination;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace FruitWholesale.Api.Controllers;

[Authorize(Roles = $"{UserRoles.Admin},{UserRoles.Manager},{UserRoles.Accountant}")]
public class SupplierReturnController(ISupplierReturnService service, ICurrentUserService currentUserService) : ApiControllerBase
{
    [HttpGet]
    public async Task<ActionResult<PaginatedList<SupplierReturnListItemDto>>> GetPaged(
        [FromQuery] PaginationRequest request, [FromQuery] int? supplierId, [FromQuery] DateTime? fromDate, [FromQuery] DateTime? toDate) =>
        Ok(await service.GetPagedAsync(request, supplierId, fromDate, toDate));

    [HttpGet("{id:int}")]
    public async Task<ActionResult<SupplierReturnDto>> GetById(int id) => Ok(await service.GetByIdAsync(id));

    [HttpGet("next-reference-no")]
    public async Task<ActionResult<string>> GetNextReferenceNo() => Ok(await service.GetNextReferenceNoAsync());

    [HttpPost]
    public async Task<ActionResult<SupplierReturnDto>> Create(CreateSupplierReturnDto dto) => FromResult(await service.CreateAsync(dto, currentUserService.UserId));

    [HttpPut("{id:int}")]
    public async Task<ActionResult<SupplierReturnDto>> Update(int id, UpdateSupplierReturnDto dto)
    {
        dto.SupplierReturnID = id;
        return FromResult(await service.UpdateAsync(dto));
    }

    [HttpDelete("{id:int}")]
    public async Task<ActionResult> Delete(int id)
    {
        await service.DeleteAsync(id);
        return NoContent();
    }
}
