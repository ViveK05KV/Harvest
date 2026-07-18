using FruitWholesale.Application.Common.Interfaces;
using FruitWholesale.Application.DTOs.SupplierPayment;
using FruitWholesale.Application.Services;
using FruitWholesale.Domain.Enums;
using FruitWholesale.Shared.Pagination;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace FruitWholesale.Api.Controllers;

[Authorize(Roles = $"{UserRoles.Admin},{UserRoles.Manager},{UserRoles.Accountant}")]
public class SupplierPaymentController(ISupplierPaymentService service, ICurrentUserService currentUserService) : ApiControllerBase
{
    [HttpGet]
    public async Task<ActionResult<PaginatedList<SupplierPaymentDto>>> GetPaged(
        [FromQuery] PaginationRequest request, [FromQuery] int? supplierId, [FromQuery] DateTime? fromDate, [FromQuery] DateTime? toDate) =>
        Ok(await service.GetPagedAsync(request, supplierId, fromDate, toDate));

    [HttpGet("{id:int}")]
    public async Task<ActionResult<SupplierPaymentDto>> GetById(int id) => Ok(await service.GetByIdAsync(id));

    [HttpPost]
    public async Task<ActionResult<SupplierPaymentDto>> Create(CreateSupplierPaymentDto dto) => FromResult(await service.CreateAsync(dto, currentUserService.UserId));

    [HttpPut("{id:int}")]
    public async Task<ActionResult<SupplierPaymentDto>> Update(int id, UpdateSupplierPaymentDto dto)
    {
        dto.SupplierPaymentID = id;
        return FromResult(await service.UpdateAsync(dto));
    }

    [HttpDelete("{id:int}")]
    public async Task<ActionResult> Delete(int id)
    {
        await service.DeleteAsync(id);
        return NoContent();
    }
}
