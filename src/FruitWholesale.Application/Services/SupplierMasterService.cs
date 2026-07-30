using AutoMapper;
using FruitWholesale.Application.Common.Interfaces;
using FruitWholesale.Application.DTOs.SupplierMaster;
using FruitWholesale.Domain.Entities;
using FruitWholesale.Shared.Exceptions;
using FruitWholesale.Shared.Pagination;
using FruitWholesale.Shared.Results;

namespace FruitWholesale.Application.Services;

public interface ISupplierMasterService
{
    Task<PaginatedList<SupplierMasterDto>> GetPagedAsync(PaginationRequest request);
    Task<IReadOnlyList<SupplierMasterDto>> GetAllActiveAsync();
    Task<SupplierMasterDto> GetByIdAsync(int supplierId);
    Task<Result<SupplierMasterDto>> CreateAsync(CreateSupplierMasterDto dto);
    Task<Result<SupplierMasterDto>> UpdateAsync(UpdateSupplierMasterDto dto);
    Task SetActiveAsync(int supplierId, bool isActive);
}

public class SupplierMasterService(ISupplierMasterRepository repository, ILedgerService ledgerService, IMapper mapper) : ISupplierMasterService
{
    public async Task<PaginatedList<SupplierMasterDto>> GetPagedAsync(PaginationRequest request)
    {
        var result = await repository.GetPagedAsync(request);
        var dtos = await EnrichWithOutstandingAsync(result.Items);
        return new PaginatedList<SupplierMasterDto>(dtos, result.TotalCount, result.PageNumber, result.PageSize);
    }

    public async Task<IReadOnlyList<SupplierMasterDto>> GetAllActiveAsync()
    {
        var items = await repository.GetAllActiveAsync();
        return await EnrichWithOutstandingAsync(items);
    }

    public async Task<SupplierMasterDto> GetByIdAsync(int supplierId)
    {
        var supplier = await repository.GetByIdAsync(supplierId) ?? throw new NotFoundException(nameof(SupplierMaster), supplierId);
        var dto = mapper.Map<SupplierMasterDto>(supplier);
        dto.CurrentOutstanding = await ledgerService.GetSupplierOutstandingAsync(supplierId);
        dto.NetBalance = await GetLinkedShopOutstandingAsync(supplier.LinkedShopID) - dto.CurrentOutstanding;
        return dto;
    }

    public async Task<Result<SupplierMasterDto>> CreateAsync(CreateSupplierMasterDto dto)
    {
        var supplier = new SupplierMaster
        {
            SupplierName = dto.SupplierName,
            Phone = dto.Phone,
            Address = dto.Address,
            OpeningBalance = dto.OpeningBalance,
            IsActive = true
        };
        supplier.SupplierID = await repository.CreateAsync(supplier);
        var result = mapper.Map<SupplierMasterDto>(supplier);
        result.CurrentOutstanding = supplier.OpeningBalance;
        return Result.Success(result);
    }

    public async Task<Result<SupplierMasterDto>> UpdateAsync(UpdateSupplierMasterDto dto)
    {
        var supplier = await repository.GetByIdAsync(dto.SupplierID) ?? throw new NotFoundException(nameof(SupplierMaster), dto.SupplierID);
        supplier.SupplierName = dto.SupplierName;
        supplier.Phone = dto.Phone;
        supplier.Address = dto.Address;
        await repository.UpdateAsync(supplier);

        var result = mapper.Map<SupplierMasterDto>(supplier);
        result.CurrentOutstanding = await ledgerService.GetSupplierOutstandingAsync(supplier.SupplierID);
        result.NetBalance = await GetLinkedShopOutstandingAsync(supplier.LinkedShopID) - result.CurrentOutstanding;
        return Result.Success(result);
    }

    public async Task SetActiveAsync(int supplierId, bool isActive)
    {
        _ = await repository.GetByIdAsync(supplierId) ?? throw new NotFoundException(nameof(SupplierMaster), supplierId);
        await repository.SetActiveAsync(supplierId, isActive);
    }

    private async Task<decimal> GetLinkedShopOutstandingAsync(int? linkedShopId) =>
        linkedShopId is null ? 0m : await ledgerService.GetShopOutstandingAsync(linkedShopId.Value);

    private async Task<List<SupplierMasterDto>> EnrichWithOutstandingAsync(IEnumerable<SupplierMaster> suppliers)
    {
        var supplierList = suppliers.ToList();
        var outstanding = await ledgerService.GetSupplierOutstandingBatchAsync(supplierList.Select(s => s.SupplierID));
        var linkedShopIds = supplierList.Where(s => s.LinkedShopID.HasValue).Select(s => s.LinkedShopID!.Value).Distinct().ToList();
        var linkedShopOutstanding = linkedShopIds.Count == 0
            ? []
            : await ledgerService.GetShopOutstandingBatchAsync(linkedShopIds);

        return supplierList.Select(supplier =>
        {
            var dto = mapper.Map<SupplierMasterDto>(supplier);
            dto.CurrentOutstanding = outstanding.GetValueOrDefault(supplier.SupplierID);
            var linkedOutstanding = supplier.LinkedShopID.HasValue
                ? linkedShopOutstanding.GetValueOrDefault(supplier.LinkedShopID.Value)
                : 0m;
            dto.NetBalance = linkedOutstanding - dto.CurrentOutstanding;
            return dto;
        }).ToList();
    }
}
