using AutoMapper;
using FruitWholesale.Application.Common.Interfaces;
using FruitWholesale.Application.DTOs.ShopMaster;
using FruitWholesale.Domain.Entities;
using FruitWholesale.Shared.Exceptions;
using FruitWholesale.Shared.Pagination;
using FruitWholesale.Shared.Results;

namespace FruitWholesale.Application.Services;

public interface IShopMasterService
{
    Task<PaginatedList<ShopMasterDto>> GetPagedAsync(PaginationRequest request);
    Task<IReadOnlyList<ShopMasterDto>> GetAllActiveAsync();
    Task<ShopMasterDto> GetByIdAsync(int shopId);
    Task<Result<ShopMasterDto>> CreateAsync(CreateShopMasterDto dto);
    Task<Result<ShopMasterDto>> UpdateAsync(UpdateShopMasterDto dto);
    Task SetActiveAsync(int shopId, bool isActive);
}

public class ShopMasterService(IShopMasterRepository repository, ILedgerService ledgerService, IMapper mapper) : IShopMasterService
{
    public async Task<PaginatedList<ShopMasterDto>> GetPagedAsync(PaginationRequest request)
    {
        var result = await repository.GetPagedAsync(request);
        var dtos = await EnrichWithOutstandingAsync(result.Items);
        return new PaginatedList<ShopMasterDto>(dtos, result.TotalCount, result.PageNumber, result.PageSize);
    }

    public async Task<IReadOnlyList<ShopMasterDto>> GetAllActiveAsync()
    {
        var items = await repository.GetAllActiveAsync();
        return await EnrichWithOutstandingAsync(items);
    }

    public async Task<ShopMasterDto> GetByIdAsync(int shopId)
    {
        var shop = await repository.GetByIdAsync(shopId) ?? throw new NotFoundException(nameof(ShopMaster), shopId);
        var dto = mapper.Map<ShopMasterDto>(shop);

        var outstandingTask = ledgerService.GetShopOutstandingAsync(shopId);
        var linkedOutstandingTask = GetLinkedSupplierOutstandingAsync(shop.LinkedSupplierID);
        await Task.WhenAll(outstandingTask, linkedOutstandingTask);

        dto.CurrentOutstanding = await outstandingTask;
        dto.NetBalance = dto.CurrentOutstanding - await linkedOutstandingTask;
        return dto;
    }

    public async Task<Result<ShopMasterDto>> CreateAsync(CreateShopMasterDto dto)
    {
        var shop = new ShopMaster
        {
            ShopName = dto.ShopName,
            OwnerName = dto.OwnerName,
            Phone = dto.Phone,
            Address = dto.Address,
            OpeningBalance = dto.OpeningBalance,
            CreditLimit = dto.CreditLimit,
            RouteID = dto.RouteID,
            LinkedSupplierID = dto.LinkedSupplierID,
            IsActive = true
        };
        shop.ShopID = await repository.CreateAsync(shop);
        var result = mapper.Map<ShopMasterDto>(shop);
        result.CurrentOutstanding = shop.OpeningBalance;
        result.NetBalance = shop.OpeningBalance - await GetLinkedSupplierOutstandingAsync(shop.LinkedSupplierID);
        return Result.Success(result);
    }

    public async Task<Result<ShopMasterDto>> UpdateAsync(UpdateShopMasterDto dto)
    {
        var shop = await repository.GetByIdAsync(dto.ShopID) ?? throw new NotFoundException(nameof(ShopMaster), dto.ShopID);
        shop.ShopName = dto.ShopName;
        shop.OwnerName = dto.OwnerName;
        shop.Phone = dto.Phone;
        shop.Address = dto.Address;
        shop.CreditLimit = dto.CreditLimit;
        shop.RouteID = dto.RouteID;
        shop.LinkedSupplierID = dto.LinkedSupplierID;
        await repository.UpdateAsync(shop);

        var result = mapper.Map<ShopMasterDto>(shop);
        result.CurrentOutstanding = await ledgerService.GetShopOutstandingAsync(shop.ShopID);
        result.NetBalance = result.CurrentOutstanding - await GetLinkedSupplierOutstandingAsync(shop.LinkedSupplierID);
        return Result.Success(result);
    }

    public async Task SetActiveAsync(int shopId, bool isActive)
    {
        _ = await repository.GetByIdAsync(shopId) ?? throw new NotFoundException(nameof(ShopMaster), shopId);
        await repository.SetActiveAsync(shopId, isActive);
    }

    private async Task<decimal> GetLinkedSupplierOutstandingAsync(int? linkedSupplierId) =>
        linkedSupplierId is null ? 0m : await ledgerService.GetSupplierOutstandingAsync(linkedSupplierId.Value);

    private async Task<List<ShopMasterDto>> EnrichWithOutstandingAsync(IEnumerable<ShopMaster> shops)
    {
        var shopList = shops.ToList();
        var outstanding = await ledgerService.GetShopOutstandingBatchAsync(shopList.Select(s => s.ShopID));
        var linkedSupplierIds = shopList.Where(s => s.LinkedSupplierID.HasValue).Select(s => s.LinkedSupplierID!.Value).Distinct().ToList();
        var linkedSupplierOutstanding = linkedSupplierIds.Count == 0
            ? []
            : await ledgerService.GetSupplierOutstandingBatchAsync(linkedSupplierIds);

        return shopList.Select(shop =>
        {
            var dto = mapper.Map<ShopMasterDto>(shop);
            dto.CurrentOutstanding = outstanding.GetValueOrDefault(shop.ShopID);
            var linkedOutstanding = shop.LinkedSupplierID.HasValue
                ? linkedSupplierOutstanding.GetValueOrDefault(shop.LinkedSupplierID.Value)
                : 0m;
            dto.NetBalance = dto.CurrentOutstanding - linkedOutstanding;
            return dto;
        }).ToList();
    }
}
