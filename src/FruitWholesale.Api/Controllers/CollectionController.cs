using FruitWholesale.Application.Common.Interfaces;
using FruitWholesale.Application.DTOs.Collection;
using FruitWholesale.Application.Services;
using FruitWholesale.Domain.Enums;
using FruitWholesale.Shared.Pagination;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace FruitWholesale.Api.Controllers;

[Authorize(Roles = $"{UserRoles.Admin},{UserRoles.Manager},{UserRoles.Accountant},{UserRoles.Staff}")]
public class CollectionController(ICollectionService service, ICurrentUserService currentUserService) : ApiControllerBase
{
    [HttpGet]
    public async Task<ActionResult<PaginatedList<CollectionDto>>> GetPaged(
        [FromQuery] PaginationRequest request, [FromQuery] int? shopId, [FromQuery] DateTime? fromDate, [FromQuery] DateTime? toDate) =>
        Ok(await service.GetPagedAsync(request, shopId, fromDate, toDate));

    [HttpGet("{id:int}")]
    public async Task<ActionResult<CollectionDto>> GetById(int id) => Ok(await service.GetByIdAsync(id));

    [HttpGet("pending-settle/preview")]
    public async Task<ActionResult<CollectionSettlementPreviewDto>> GetPendingSettlementPreview([FromQuery] int shopId) =>
        Ok(await service.GetPendingSettlementPreviewAsync(shopId));

    [HttpPost]
    public async Task<ActionResult<CollectionDto>> Create(CreateCollectionDto dto) => FromResult(await service.CreateAsync(dto, currentUserService.UserId));

    [HttpPost("settle")]
    public async Task<ActionResult<CollectionSettlementResultDto>> Settle(SettleCollectionsRequestDto dto) =>
        FromResult(await service.SettlePendingAsync(dto, currentUserService.UserId));

    [HttpPut("{id:int}")]
    public async Task<ActionResult<CollectionDto>> Update(int id, UpdateCollectionDto dto)
    {
        dto.CollectionID = id;
        return FromResult(await service.UpdateAsync(dto));
    }

    [HttpDelete("{id:int}")]
    public async Task<ActionResult> Delete(int id)
    {
        await service.DeleteAsync(id);
        return NoContent();
    }
}
