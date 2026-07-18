using AutoMapper;
using FruitWholesale.Application.Common.Interfaces;
using FruitWholesale.Application.DTOs.Supply;
using FruitWholesale.Domain.Entities;
using FruitWholesale.Shared.Exceptions;
using FruitWholesale.Shared.Pagination;
using FruitWholesale.Shared.Results;

namespace FruitWholesale.Application.Services;

public interface ISupplyService
{
    Task<PaginatedList<SupplyListItemDto>> GetPagedAsync(PaginationRequest request, int? shopId, DateTime? fromDate, DateTime? toDate);
    Task<SupplyDto> GetByIdAsync(int supplyId);
    Task<string> GetNextInvoiceNoAsync();
    Task<Result<SupplyDto>> CreateAsync(CreateSupplyDto dto, int? userId);
    Task<Result<SupplyDto>> UpdateAsync(UpdateSupplyDto dto);
    Task DeleteAsync(int supplyId);
}

public class SupplyService(ISupplyRepository repository, IMapper mapper) : ISupplyService
{
    public async Task<PaginatedList<SupplyListItemDto>> GetPagedAsync(PaginationRequest request, int? shopId, DateTime? fromDate, DateTime? toDate)
    {
        var result = await repository.GetPagedAsync(request, shopId, fromDate, toDate);
        return new PaginatedList<SupplyListItemDto>(mapper.Map<List<SupplyListItemDto>>(result.Items), result.TotalCount, result.PageNumber, result.PageSize);
    }

    public async Task<SupplyDto> GetByIdAsync(int supplyId)
    {
        var supply = await repository.GetByIdAsync(supplyId) ?? throw new NotFoundException(nameof(Supply), supplyId);
        return mapper.Map<SupplyDto>(supply);
    }

    public Task<string> GetNextInvoiceNoAsync() => repository.GenerateNextInvoiceNoAsync();

    public async Task<Result<SupplyDto>> CreateAsync(CreateSupplyDto dto, int? userId)
    {
        if (dto.Items.Count == 0)
        {
            return Result.Failure<SupplyDto>("At least one item is required.");
        }

        if (await repository.InvoiceNoExistsAsync(dto.InvoiceNo))
        {
            return Result.Failure<SupplyDto>("This invoice number is already used.");
        }

        var supply = new Supply
        {
            SupplyDate = dto.SupplyDate,
            ShopID = dto.ShopID,
            InvoiceNo = dto.InvoiceNo,
            Remarks = dto.Remarks,
            CreatedBy = userId,
            Items = dto.Items.Select(i => new SupplyItem
            {
                FruitID = i.FruitID,
                Quantity = i.Quantity,
                UnitPrice = i.UnitPrice,
                TotalAmount = i.Quantity * i.UnitPrice
            }).ToList()
        };

        supply.SupplyID = await repository.CreateAsync(supply);
        var created = await repository.GetByIdAsync(supply.SupplyID);
        return Result.Success(mapper.Map<SupplyDto>(created));
    }

    public async Task<Result<SupplyDto>> UpdateAsync(UpdateSupplyDto dto)
    {
        if (dto.Items.Count == 0)
        {
            return Result.Failure<SupplyDto>("At least one item is required.");
        }

        _ = await repository.GetByIdAsync(dto.SupplyID) ?? throw new NotFoundException(nameof(Supply), dto.SupplyID);

        if (await repository.InvoiceNoExistsAsync(dto.InvoiceNo, dto.SupplyID))
        {
            return Result.Failure<SupplyDto>("This invoice number is already used.");
        }

        var supply = new Supply
        {
            SupplyID = dto.SupplyID,
            SupplyDate = dto.SupplyDate,
            ShopID = dto.ShopID,
            InvoiceNo = dto.InvoiceNo,
            Remarks = dto.Remarks,
            Items = dto.Items.Select(i => new SupplyItem
            {
                FruitID = i.FruitID,
                Quantity = i.Quantity,
                UnitPrice = i.UnitPrice,
                TotalAmount = i.Quantity * i.UnitPrice
            }).ToList()
        };

        await repository.UpdateAsync(supply);
        var updated = await repository.GetByIdAsync(dto.SupplyID);
        return Result.Success(mapper.Map<SupplyDto>(updated));
    }

    public async Task DeleteAsync(int supplyId)
    {
        _ = await repository.GetByIdAsync(supplyId) ?? throw new NotFoundException(nameof(Supply), supplyId);
        await repository.DeleteAsync(supplyId);
    }
}
