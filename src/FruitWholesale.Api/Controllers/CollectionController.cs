using FruitWholesale.Application.Common.Interfaces;
using FruitWholesale.Application.DTOs.Collection;
using FruitWholesale.Application.Services;
using FruitWholesale.Shared.Pagination;
using Microsoft.AspNetCore.Mvc;

namespace FruitWholesale.Api.Controllers;

public class CollectionController(ICollectionService service, ICurrentUserService currentUserService) : ApiControllerBase
{
    [HttpGet]
    public async Task<ActionResult<PaginatedList<CollectionDto>>> GetPaged(
        [FromQuery] PaginationRequest request, [FromQuery] int? shopId, [FromQuery] DateTime? fromDate, [FromQuery] DateTime? toDate) =>
        Ok(await service.GetPagedAsync(request, shopId, fromDate, toDate));

    [HttpGet("{id:int}")]
    public async Task<ActionResult<CollectionDto>> GetById(int id) => Ok(await service.GetByIdAsync(id));

    [HttpPost]
    public async Task<ActionResult<CollectionDto>> Create(CreateCollectionDto dto) => FromResult(await service.CreateAsync(dto, currentUserService.UserId));

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
