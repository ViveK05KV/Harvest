using AutoMapper;
using FruitWholesale.Application.Common.Interfaces;
using FruitWholesale.Application.DTOs.Collection;
using FruitWholesale.Domain.Entities;
using FruitWholesale.Domain.Enums;
using FruitWholesale.Shared.Exceptions;
using FruitWholesale.Shared.Pagination;
using FruitWholesale.Shared.Results;

namespace FruitWholesale.Application.Services;

public interface ICollectionService
{
    Task<PaginatedList<CollectionDto>> GetPagedAsync(PaginationRequest request, int? shopId, DateTime? fromDate, DateTime? toDate);
    Task<CollectionDto> GetByIdAsync(int collectionId);
    Task<Result<CollectionDto>> CreateAsync(CreateCollectionDto dto, int? userId);
    Task<Result<CollectionDto>> UpdateAsync(UpdateCollectionDto dto);
    Task DeleteAsync(int collectionId);
    Task<CollectionSettlementPreviewDto> GetPendingSettlementPreviewAsync(int shopId);
    Task<Result<CollectionSettlementResultDto>> SettlePendingAsync(SettleCollectionsRequestDto dto, int? userId);
}

public class CollectionService(ICollectionRepository repository, IMapper mapper) : ICollectionService
{
    public async Task<PaginatedList<CollectionDto>> GetPagedAsync(PaginationRequest request, int? shopId, DateTime? fromDate, DateTime? toDate)
    {
        var result = await repository.GetPagedAsync(request, shopId, fromDate, toDate);
        return new PaginatedList<CollectionDto>(mapper.Map<List<CollectionDto>>(result.Items), result.TotalCount, result.PageNumber, result.PageSize);
    }

    public async Task<CollectionDto> GetByIdAsync(int collectionId)
    {
        var collection = await repository.GetByIdAsync(collectionId) ?? throw new NotFoundException(nameof(Collection), collectionId);
        return mapper.Map<CollectionDto>(collection);
    }

    public async Task<Result<CollectionDto>> CreateAsync(CreateCollectionDto dto, int? userId)
    {
        if (dto.AmountReceived <= 0)
        {
            return Result.Failure<CollectionDto>("Amount received must be greater than zero.");
        }

        if (!PaymentModes.All.Contains(dto.PaymentMode))
        {
            return Result.Failure<CollectionDto>("Invalid payment mode.");
        }

        if (dto.DiscountAmount < 0)
        {
            return Result.Failure<CollectionDto>("Discount cannot be negative.");
        }

        if (!CollectionTypes.All.Contains(dto.CollectionType))
        {
            return Result.Failure<CollectionDto>("Invalid collection type.");
        }

        var collection = new Collection
        {
            CollectionDate = dto.CollectionDate,
            ShopID = dto.ShopID,
            AmountReceived = dto.AmountReceived,
            DiscountAmount = dto.DiscountAmount,
            PaymentMode = dto.PaymentMode,
            ReferenceNumber = dto.ReferenceNumber,
            Remarks = dto.Remarks,
            CollectionType = dto.CollectionType,
            TemporaryStatus = dto.CollectionType == CollectionTypes.Temporary ? TemporaryCollectionStatuses.Pending : TemporaryCollectionStatuses.None,
            CreatedBy = userId
        };

        collection.CollectionID = await repository.CreateAsync(collection);
        var created = await repository.GetByIdAsync(collection.CollectionID);
        return Result.Success(mapper.Map<CollectionDto>(created));
    }

    public async Task<Result<CollectionDto>> UpdateAsync(UpdateCollectionDto dto)
    {
        if (dto.AmountReceived <= 0)
        {
            return Result.Failure<CollectionDto>("Amount received must be greater than zero.");
        }

        if (dto.DiscountAmount < 0)
        {
            return Result.Failure<CollectionDto>("Discount cannot be negative.");
        }

        if (!CollectionTypes.All.Contains(dto.CollectionType))
        {
            return Result.Failure<CollectionDto>("Invalid collection type.");
        }

        _ = await repository.GetByIdAsync(dto.CollectionID) ?? throw new NotFoundException(nameof(Collection), dto.CollectionID);

        var collection = new Collection
        {
            CollectionID = dto.CollectionID,
            CollectionDate = dto.CollectionDate,
            ShopID = dto.ShopID,
            AmountReceived = dto.AmountReceived,
            DiscountAmount = dto.DiscountAmount,
            PaymentMode = dto.PaymentMode,
            ReferenceNumber = dto.ReferenceNumber,
            Remarks = dto.Remarks,
            CollectionType = dto.CollectionType,
            TemporaryStatus = dto.CollectionType == CollectionTypes.Temporary ? TemporaryCollectionStatuses.Pending : TemporaryCollectionStatuses.None
        };

        await repository.UpdateAsync(collection);
        var updated = await repository.GetByIdAsync(dto.CollectionID);
        return Result.Success(mapper.Map<CollectionDto>(updated));
    }

    public async Task DeleteAsync(int collectionId)
    {
        _ = await repository.GetByIdAsync(collectionId) ?? throw new NotFoundException(nameof(Collection), collectionId);
        await repository.DeleteAsync(collectionId);
    }

    public Task<CollectionSettlementPreviewDto> GetPendingSettlementPreviewAsync(int shopId) => repository.GetPendingSettlementPreviewAsync(shopId);

    public async Task<Result<CollectionSettlementResultDto>> SettlePendingAsync(SettleCollectionsRequestDto dto, int? userId)
    {
        if (dto.ShopID <= 0)
        {
            return Result.Failure<CollectionSettlementResultDto>("Shop is required.");
        }

        if (dto.SettlementDate == default)
        {
            return Result.Failure<CollectionSettlementResultDto>("Settlement date is required.");
        }

        var result = await repository.SettlePendingAsync(dto.ShopID, dto.SettlementDate, userId);
        return Result.Success(result);
    }
}
