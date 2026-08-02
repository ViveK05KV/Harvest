using AutoMapper;
using FruitWholesale.Application.Common.Interfaces;
using FruitWholesale.Application.DTOs.Purchase;
using FruitWholesale.Domain.Entities;
using FruitWholesale.Shared.Exceptions;
using FruitWholesale.Shared.Pagination;
using FruitWholesale.Shared.Results;

namespace FruitWholesale.Application.Services;

public interface IPurchaseService
{
    Task<PaginatedList<PurchaseListItemDto>> GetPagedAsync(PaginationRequest request, int? supplierId, DateTime? fromDate, DateTime? toDate);
    Task<PurchaseDto> GetByIdAsync(int purchaseId);
    Task<string> GetNextInvoiceNoAsync();
    Task<Result<PurchaseDto>> CreateAsync(CreatePurchaseDto dto, int? userId);
    Task<Result<PurchaseDto>> UpdateAsync(UpdatePurchaseDto dto);
    Task DeleteAsync(int purchaseId);
}

public class PurchaseService(IPurchaseRepository repository, IMapper mapper) : IPurchaseService
{
    public async Task<PaginatedList<PurchaseListItemDto>> GetPagedAsync(PaginationRequest request, int? supplierId, DateTime? fromDate, DateTime? toDate)
    {
        var result = await repository.GetPagedAsync(request, supplierId, fromDate, toDate);
        return new PaginatedList<PurchaseListItemDto>(mapper.Map<List<PurchaseListItemDto>>(result.Items), result.TotalCount, result.PageNumber, result.PageSize);
    }

    public async Task<PurchaseDto> GetByIdAsync(int purchaseId)
    {
        var purchase = await repository.GetByIdAsync(purchaseId) ?? throw new NotFoundException(nameof(Purchase), purchaseId);
        return mapper.Map<PurchaseDto>(purchase);
    }

    public Task<string> GetNextInvoiceNoAsync() => repository.GenerateNextInvoiceNoAsync();

    public async Task<Result<PurchaseDto>> CreateAsync(CreatePurchaseDto dto, int? userId)
    {
        if (dto.Items.Count == 0)
        {
            return Result.Failure<PurchaseDto>("At least one item is required.");
        }

        if (await repository.InvoiceNoExistsAsync(dto.InvoiceNo))
        {
            return Result.Failure<PurchaseDto>("This invoice number is already used.");
        }

        var purchase = new Purchase
        {
            PurchaseDate = dto.PurchaseDate,
            SupplierID = dto.SupplierID,
            InvoiceNo = dto.InvoiceNo,
            Remarks = dto.Remarks,
            CreatedBy = userId,
            Items = dto.Items.Select(i => new PurchaseItem
            {
                FruitID = i.FruitID,
                Quantity = i.Quantity,
                PurchasePrice = i.PurchasePrice,
                TotalAmount = (i.BoxCount ?? 0) > 0 ? i.BoxCount!.Value * i.PurchasePrice : i.Quantity * i.PurchasePrice,
                BoxCount = i.BoxCount
            }).ToList()
        };

        purchase.PurchaseID = await repository.CreateAsync(purchase);
        var created = await repository.GetByIdAsync(purchase.PurchaseID);
        return Result.Success(mapper.Map<PurchaseDto>(created));
    }

    public async Task<Result<PurchaseDto>> UpdateAsync(UpdatePurchaseDto dto)
    {
        if (dto.Items.Count == 0)
        {
            return Result.Failure<PurchaseDto>("At least one item is required.");
        }

        _ = await repository.GetByIdAsync(dto.PurchaseID) ?? throw new NotFoundException(nameof(Purchase), dto.PurchaseID);

        if (await repository.InvoiceNoExistsAsync(dto.InvoiceNo, dto.PurchaseID))
        {
            return Result.Failure<PurchaseDto>("This invoice number is already used.");
        }

        var purchase = new Purchase
        {
            PurchaseID = dto.PurchaseID,
            PurchaseDate = dto.PurchaseDate,
            SupplierID = dto.SupplierID,
            InvoiceNo = dto.InvoiceNo,
            Remarks = dto.Remarks,
            Items = dto.Items.Select(i => new PurchaseItem
            {
                FruitID = i.FruitID,
                Quantity = i.Quantity,
                PurchasePrice = i.PurchasePrice,
                TotalAmount = (i.BoxCount ?? 0) > 0 ? i.BoxCount!.Value * i.PurchasePrice : i.Quantity * i.PurchasePrice,
                BoxCount = i.BoxCount
            }).ToList()
        };

        await repository.UpdateAsync(purchase);
        var updated = await repository.GetByIdAsync(dto.PurchaseID);
        return Result.Success(mapper.Map<PurchaseDto>(updated));
    }

    public async Task DeleteAsync(int purchaseId)
    {
        _ = await repository.GetByIdAsync(purchaseId) ?? throw new NotFoundException(nameof(Purchase), purchaseId);
        await repository.DeleteAsync(purchaseId);
    }
}
