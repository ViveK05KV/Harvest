using FruitWholesale.Application.Common.Interfaces;
using FruitWholesale.Application.DTOs.Supply;
using FruitWholesale.Application.Services;
using FruitWholesale.Shared.Pagination;
using Microsoft.AspNetCore.Mvc;

namespace FruitWholesale.Api.Controllers;

// Deliberately open to all authenticated roles (including Staff) - see
// backOfficeGuard comment in the Angular app.routes.ts: Staff can record Supply.
public class SupplyController(ISupplyService service, ICurrentUserService currentUserService) : ApiControllerBase
{
    [HttpGet]
    public async Task<ActionResult<PaginatedList<SupplyListItemDto>>> GetPaged(
        [FromQuery] PaginationRequest request, [FromQuery] int? shopId, [FromQuery] DateTime? fromDate, [FromQuery] DateTime? toDate) =>
        Ok(await service.GetPagedAsync(request, shopId, fromDate, toDate));

    [HttpGet("{id:int}")]
    public async Task<ActionResult<SupplyDto>> GetById(int id) => Ok(await service.GetByIdAsync(id));

    [HttpGet("next-invoice-no")]
    public async Task<ActionResult<string>> GetNextInvoiceNo() => Ok(await service.GetNextInvoiceNoAsync());

    [HttpPost]
    public async Task<ActionResult<SupplyDto>> Create(CreateSupplyDto dto) => FromResult(await service.CreateAsync(dto, currentUserService.UserId));

    [HttpPut("{id:int}")]
    public async Task<ActionResult<SupplyDto>> Update(int id, UpdateSupplyDto dto)
    {
        dto.SupplyID = id;
        return FromResult(await service.UpdateAsync(dto));
    }

    [HttpDelete("{id:int}")]
    public async Task<ActionResult> Delete(int id)
    {
        await service.DeleteAsync(id);
        return NoContent();
    }
}
