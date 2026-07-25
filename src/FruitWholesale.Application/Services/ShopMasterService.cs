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
        dto.CurrentOutstanding = await ledgerService.GetShopOutstandingAsync(shopId);
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
            IsActive = true
        };
        shop.ShopID = await repository.CreateAsync(shop);
        var result = mapper.Map<ShopMasterDto>(shop);
        result.CurrentOutstanding = shop.OpeningBalance;
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
        await repository.UpdateAsync(shop);

        var result = mapper.Map<ShopMasterDto>(shop);
        result.CurrentOutstanding = await ledgerService.GetShopOutstandingAsync(shop.ShopID);
        return Result.Success(result);
    }

    public async Task SetActiveAsync(int shopId, bool isActive)
    {
        _ = await repository.GetByIdAsync(shopId) ?? throw new NotFoundException(nameof(ShopMaster), shopId);
        await repository.SetActiveAsync(shopId, isActive);
    }

    private async Task<List<ShopMasterDto>> EnrichWithOutstandingAsync(IEnumerable<ShopMaster> shops)
    {
        var dtos = new List<ShopMasterDto>();
        foreach (var shop in shops)
        {
            var dto = mapper.Map<ShopMasterDto>(shop);
            dto.CurrentOutstanding = await ledgerService.GetShopOutstandingAsync(shop.ShopID);
            dtos.Add(dto);
        }
        return dtos;
    }
}
