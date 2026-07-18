using FruitWholesale.Application.Common.Interfaces;
using FruitWholesale.Application.DTOs.Purchase;
using FruitWholesale.Application.Services;
using FruitWholesale.Domain.Enums;
using FruitWholesale.Shared.Pagination;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace FruitWholesale.Api.Controllers;

[Authorize(Roles = $"{UserRoles.Admin},{UserRoles.Manager},{UserRoles.Accountant}")]
public class PurchaseController(IPurchaseService service, ICurrentUserService currentUserService) : ApiControllerBase
{
    [HttpGet]
    public async Task<ActionResult<PaginatedList<PurchaseListItemDto>>> GetPaged(
        [FromQuery] PaginationRequest request, [FromQuery] int? supplierId, [FromQuery] DateTime? fromDate, [FromQuery] DateTime? toDate) =>
        Ok(await service.GetPagedAsync(request, supplierId, fromDate, toDate));

    [HttpGet("{id:int}")]
    public async Task<ActionResult<PurchaseDto>> GetById(int id) => Ok(await service.GetByIdAsync(id));

    [HttpGet("next-invoice-no")]
    public async Task<ActionResult<string>> GetNextInvoiceNo() => Ok(await service.GetNextInvoiceNoAsync());

    [HttpPost]
    public async Task<ActionResult<PurchaseDto>> Create(CreatePurchaseDto dto) => FromResult(await service.CreateAsync(dto, currentUserService.UserId));

    [HttpPut("{id:int}")]
    public async Task<ActionResult<PurchaseDto>> Update(int id, UpdatePurchaseDto dto)
    {
        dto.PurchaseID = id;
        return FromResult(await service.UpdateAsync(dto));
    }

    [HttpDelete("{id:int}")]
    public async Task<ActionResult> Delete(int id)
    {
        await service.DeleteAsync(id);
        return NoContent();
    }
}
