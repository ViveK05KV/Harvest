using AutoMapper;
using FruitWholesale.Application.Common.Interfaces;
using FruitWholesale.Application.DTOs.SupplierReturn;
using FruitWholesale.Domain.Entities;
using FruitWholesale.Shared.Exceptions;
using FruitWholesale.Shared.Pagination;
using FruitWholesale.Shared.Results;

namespace FruitWholesale.Application.Services;

public interface ISupplierReturnService
{
    Task<PaginatedList<SupplierReturnListItemDto>> GetPagedAsync(PaginationRequest request, int? supplierId, DateTime? fromDate, DateTime? toDate);
    Task<SupplierReturnDto> GetByIdAsync(int supplierReturnId);
    Task<string> GetNextReferenceNoAsync();
    Task<Result<SupplierReturnDto>> CreateAsync(CreateSupplierReturnDto dto, int? userId);
    Task<Result<SupplierReturnDto>> UpdateAsync(UpdateSupplierReturnDto dto);
    Task DeleteAsync(int supplierReturnId);
}

public class SupplierReturnService(ISupplierReturnRepository repository, IMapper mapper) : ISupplierReturnService
{
    public async Task<PaginatedList<SupplierReturnListItemDto>> GetPagedAsync(PaginationRequest request, int? supplierId, DateTime? fromDate, DateTime? toDate)
    {
        var result = await repository.GetPagedAsync(request, supplierId, fromDate, toDate);
        return new PaginatedList<SupplierReturnListItemDto>(
            mapper.Map<List<SupplierReturnListItemDto>>(result.Items), result.TotalCount, result.PageNumber, result.PageSize);
    }

    public async Task<SupplierReturnDto> GetByIdAsync(int supplierReturnId)
    {
        var supplierReturn = await repository.GetByIdAsync(supplierReturnId) ?? throw new NotFoundException(nameof(Domain.Entities.SupplierReturn), supplierReturnId);
        return mapper.Map<SupplierReturnDto>(supplierReturn);
    }

    public Task<string> GetNextReferenceNoAsync() => repository.GenerateNextReferenceNoAsync();

    public async Task<Result<SupplierReturnDto>> CreateAsync(CreateSupplierReturnDto dto, int? userId)
    {
        if (dto.Items.Count == 0)
        {
            return Result.Failure<SupplierReturnDto>("At least one item is required.");
        }

        if (await repository.ReferenceNoExistsAsync(dto.ReferenceNo))
        {
            return Result.Failure<SupplierReturnDto>("This reference number is already used.");
        }

        var supplierReturn = new Domain.Entities.SupplierReturn
        {
            ReturnDate = dto.ReturnDate,
            SupplierID = dto.SupplierID,
            PurchaseID = dto.PurchaseID,
            ReferenceNo = dto.ReferenceNo,
            Remarks = dto.Remarks,
            CreatedBy = userId,
            Items = dto.Items.Select(i => new SupplierReturnItem
            {
                FruitID = i.FruitID,
                Quantity = i.Quantity,
                UnitPrice = i.UnitPrice,
                TotalAmount = i.Quantity * i.UnitPrice
            }).ToList()
        };

        supplierReturn.SupplierReturnID = await repository.CreateAsync(supplierReturn);
        var created = await repository.GetByIdAsync(supplierReturn.SupplierReturnID);
        return Result.Success(mapper.Map<SupplierReturnDto>(created));
    }

    public async Task<Result<SupplierReturnDto>> UpdateAsync(UpdateSupplierReturnDto dto)
    {
        if (dto.Items.Count == 0)
        {
            return Result.Failure<SupplierReturnDto>("At least one item is required.");
        }

        _ = await repository.GetByIdAsync(dto.SupplierReturnID) ?? throw new NotFoundException(nameof(Domain.Entities.SupplierReturn), dto.SupplierReturnID);

        if (await repository.ReferenceNoExistsAsync(dto.ReferenceNo, dto.SupplierReturnID))
        {
            return Result.Failure<SupplierReturnDto>("This reference number is already used.");
        }

        var supplierReturn = new Domain.Entities.SupplierReturn
        {
            SupplierReturnID = dto.SupplierReturnID,
            ReturnDate = dto.ReturnDate,
            SupplierID = dto.SupplierID,
            PurchaseID = dto.PurchaseID,
            ReferenceNo = dto.ReferenceNo,
            Remarks = dto.Remarks,
            Items = dto.Items.Select(i => new SupplierReturnItem
            {
                FruitID = i.FruitID,
                Quantity = i.Quantity,
                UnitPrice = i.UnitPrice,
                TotalAmount = i.Quantity * i.UnitPrice
            }).ToList()
        };

        await repository.UpdateAsync(supplierReturn);
        var updated = await repository.GetByIdAsync(dto.SupplierReturnID);
        return Result.Success(mapper.Map<SupplierReturnDto>(updated));
    }

    public async Task DeleteAsync(int supplierReturnId)
    {
        _ = await repository.GetByIdAsync(supplierReturnId) ?? throw new NotFoundException(nameof(Domain.Entities.SupplierReturn), supplierReturnId);
        await repository.DeleteAsync(supplierReturnId);
    }
}
