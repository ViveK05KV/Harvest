using FruitWholesale.Application.Common.Interfaces;
using FruitWholesale.Application.DTOs.ShopReturn;
using FruitWholesale.Application.Services;
using FruitWholesale.Shared.Pagination;
using Microsoft.AspNetCore.Mvc;

namespace FruitWholesale.Api.Controllers;

public class ShopReturnController(IShopReturnService service, ICurrentUserService currentUserService) : ApiControllerBase
{
    [HttpGet]
    public async Task<ActionResult<PaginatedList<ShopReturnListItemDto>>> GetPaged(
        [FromQuery] PaginationRequest request, [FromQuery] int? shopId, [FromQuery] DateTime? fromDate, [FromQuery] DateTime? toDate) =>
        Ok(await service.GetPagedAsync(request, shopId, fromDate, toDate));

    [HttpGet("{id:int}")]
    public async Task<ActionResult<ShopReturnDto>> GetById(int id) => Ok(await service.GetByIdAsync(id));

    [HttpGet("next-reference-no")]
    public async Task<ActionResult<string>> GetNextReferenceNo() => Ok(await service.GetNextReferenceNoAsync());

    [HttpPost]
    public async Task<ActionResult<ShopReturnDto>> Create(CreateShopReturnDto dto) => FromResult(await service.CreateAsync(dto, currentUserService.UserId));

    [HttpPut("{id:int}")]
    public async Task<ActionResult<ShopReturnDto>> Update(int id, UpdateShopReturnDto dto)
    {
        dto.ShopReturnID = id;
        return FromResult(await service.UpdateAsync(dto));
    }

    [HttpDelete("{id:int}")]
    public async Task<ActionResult> Delete(int id)
    {
        await service.DeleteAsync(id);
        return NoContent();
    }
}
