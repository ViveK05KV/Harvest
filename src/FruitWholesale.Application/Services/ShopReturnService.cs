using AutoMapper;
using FruitWholesale.Application.Common.Interfaces;
using FruitWholesale.Application.DTOs.ShopReturn;
using FruitWholesale.Domain.Entities;
using FruitWholesale.Shared.Exceptions;
using FruitWholesale.Shared.Pagination;
using FruitWholesale.Shared.Results;

namespace FruitWholesale.Application.Services;

public interface IShopReturnService
{
    Task<PaginatedList<ShopReturnListItemDto>> GetPagedAsync(PaginationRequest request, int? shopId, DateTime? fromDate, DateTime? toDate);
    Task<ShopReturnDto> GetByIdAsync(int shopReturnId);
    Task<string> GetNextReferenceNoAsync();
    Task<Result<ShopReturnDto>> CreateAsync(CreateShopReturnDto dto, int? userId);
    Task<Result<ShopReturnDto>> UpdateAsync(UpdateShopReturnDto dto);
    Task DeleteAsync(int shopReturnId);
}

public class ShopReturnService(IShopReturnRepository repository, IMapper mapper) : IShopReturnService
{
    public async Task<PaginatedList<ShopReturnListItemDto>> GetPagedAsync(PaginationRequest request, int? shopId, DateTime? fromDate, DateTime? toDate)
    {
        var result = await repository.GetPagedAsync(request, shopId, fromDate, toDate);
        return new PaginatedList<ShopReturnListItemDto>(
            mapper.Map<List<ShopReturnListItemDto>>(result.Items), result.TotalCount, result.PageNumber, result.PageSize);
    }

    public async Task<ShopReturnDto> GetByIdAsync(int shopReturnId)
    {
        var shopReturn = await repository.GetByIdAsync(shopReturnId) ?? throw new NotFoundException(nameof(Domain.Entities.ShopReturn), shopReturnId);
        return mapper.Map<ShopReturnDto>(shopReturn);
    }

    public Task<string> GetNextReferenceNoAsync() => repository.GenerateNextReferenceNoAsync();

    public async Task<Result<ShopReturnDto>> CreateAsync(CreateShopReturnDto dto, int? userId)
    {
        if (dto.Items.Count == 0)
        {
            return Result.Failure<ShopReturnDto>("At least one item is required.");
        }

        if (await repository.ReferenceNoExistsAsync(dto.ReferenceNo))
        {
            return Result.Failure<ShopReturnDto>("This reference number is already used.");
        }

        var shopReturn = new Domain.Entities.ShopReturn
        {
            ReturnDate = dto.ReturnDate,
            ShopID = dto.ShopID,
            SupplyID = dto.SupplyID,
            ReferenceNo = dto.ReferenceNo,
            Remarks = dto.Remarks,
            CreatedBy = userId,
            Items = dto.Items.Select(i => new ShopReturnItem
            {
                FruitID = i.FruitID,
                Quantity = i.Quantity,
                UnitPrice = i.UnitPrice,
                TotalAmount = (i.BoxCount ?? 0) > 0 ? i.BoxCount!.Value * i.UnitPrice : i.Quantity * i.UnitPrice,
                BoxCount = i.BoxCount
            }).ToList()
        };

        shopReturn.ShopReturnID = await repository.CreateAsync(shopReturn);
        var created = await repository.GetByIdAsync(shopReturn.ShopReturnID);
        return Result.Success(mapper.Map<ShopReturnDto>(created));
    }

    public async Task<Result<ShopReturnDto>> UpdateAsync(UpdateShopReturnDto dto)
    {
        if (dto.Items.Count == 0)
        {
            return Result.Failure<ShopReturnDto>("At least one item is required.");
        }

        _ = await repository.GetByIdAsync(dto.ShopReturnID) ?? throw new NotFoundException(nameof(Domain.Entities.ShopReturn), dto.ShopReturnID);

        if (await repository.ReferenceNoExistsAsync(dto.ReferenceNo, dto.ShopReturnID))
        {
            return Result.Failure<ShopReturnDto>("This reference number is already used.");
        }

        var shopReturn = new Domain.Entities.ShopReturn
        {
            ShopReturnID = dto.ShopReturnID,
            ReturnDate = dto.ReturnDate,
            ShopID = dto.ShopID,
            SupplyID = dto.SupplyID,
            ReferenceNo = dto.ReferenceNo,
            Remarks = dto.Remarks,
            Items = dto.Items.Select(i => new ShopReturnItem
            {
                FruitID = i.FruitID,
                Quantity = i.Quantity,
                UnitPrice = i.UnitPrice,
                TotalAmount = (i.BoxCount ?? 0) > 0 ? i.BoxCount!.Value * i.UnitPrice : i.Quantity * i.UnitPrice,
                BoxCount = i.BoxCount
            }).ToList()
        };

        await repository.UpdateAsync(shopReturn);
        var updated = await repository.GetByIdAsync(dto.ShopReturnID);
        return Result.Success(mapper.Map<ShopReturnDto>(updated));
    }

    public async Task DeleteAsync(int shopReturnId)
    {
        _ = await repository.GetByIdAsync(shopReturnId) ?? throw new NotFoundException(nameof(Domain.Entities.ShopReturn), shopReturnId);
        await repository.DeleteAsync(shopReturnId);
    }
}
