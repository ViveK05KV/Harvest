using AutoMapper;
using FruitWholesale.Application.Common.Interfaces;
using FruitWholesale.Application.DTOs.SupplierPayment;
using FruitWholesale.Domain.Entities;
using FruitWholesale.Domain.Enums;
using FruitWholesale.Shared.Exceptions;
using FruitWholesale.Shared.Pagination;
using FruitWholesale.Shared.Results;

namespace FruitWholesale.Application.Services;

public interface ISupplierPaymentService
{
    Task<PaginatedList<SupplierPaymentDto>> GetPagedAsync(PaginationRequest request, int? supplierId, DateTime? fromDate, DateTime? toDate);
    Task<SupplierPaymentDto> GetByIdAsync(int supplierPaymentId);
    Task<Result<SupplierPaymentDto>> CreateAsync(CreateSupplierPaymentDto dto, int? userId);
    Task<Result<SupplierPaymentDto>> UpdateAsync(UpdateSupplierPaymentDto dto);
    Task DeleteAsync(int supplierPaymentId);
}

public class SupplierPaymentService(ISupplierPaymentRepository repository, IMapper mapper) : ISupplierPaymentService
{
    public async Task<PaginatedList<SupplierPaymentDto>> GetPagedAsync(PaginationRequest request, int? supplierId, DateTime? fromDate, DateTime? toDate)
    {
        var result = await repository.GetPagedAsync(request, supplierId, fromDate, toDate);
        return new PaginatedList<SupplierPaymentDto>(mapper.Map<List<SupplierPaymentDto>>(result.Items), result.TotalCount, result.PageNumber, result.PageSize);
    }

    public async Task<SupplierPaymentDto> GetByIdAsync(int supplierPaymentId)
    {
        var payment = await repository.GetByIdAsync(supplierPaymentId) ?? throw new NotFoundException(nameof(SupplierPayment), supplierPaymentId);
        return mapper.Map<SupplierPaymentDto>(payment);
    }

    public async Task<Result<SupplierPaymentDto>> CreateAsync(CreateSupplierPaymentDto dto, int? userId)
    {
        if (dto.AmountPaid <= 0)
        {
            return Result.Failure<SupplierPaymentDto>("Amount paid must be greater than zero.");
        }

        if (!PaymentModes.All.Contains(dto.PaymentMode))
        {
            return Result.Failure<SupplierPaymentDto>("Invalid payment mode.");
        }

        if (dto.DiscountAmount < 0)
        {
            return Result.Failure<SupplierPaymentDto>("Discount cannot be negative.");
        }

        var payment = new SupplierPayment
        {
            PaymentDate = dto.PaymentDate,
            SupplierID = dto.SupplierID,
            AmountPaid = dto.AmountPaid,
            DiscountAmount = dto.DiscountAmount,
            PaymentMode = dto.PaymentMode,
            ReferenceNumber = dto.ReferenceNumber,
            Remarks = dto.Remarks,
            CreatedBy = userId
        };

        payment.SupplierPaymentID = await repository.CreateAsync(payment);
        var created = await repository.GetByIdAsync(payment.SupplierPaymentID);
        return Result.Success(mapper.Map<SupplierPaymentDto>(created));
    }

    public async Task<Result<SupplierPaymentDto>> UpdateAsync(UpdateSupplierPaymentDto dto)
    {
        if (dto.AmountPaid <= 0)
        {
            return Result.Failure<SupplierPaymentDto>("Amount paid must be greater than zero.");
        }

        if (dto.DiscountAmount < 0)
        {
            return Result.Failure<SupplierPaymentDto>("Discount cannot be negative.");
        }

        _ = await repository.GetByIdAsync(dto.SupplierPaymentID) ?? throw new NotFoundException(nameof(SupplierPayment), dto.SupplierPaymentID);

        var payment = new SupplierPayment
        {
            SupplierPaymentID = dto.SupplierPaymentID,
            PaymentDate = dto.PaymentDate,
            SupplierID = dto.SupplierID,
            AmountPaid = dto.AmountPaid,
            DiscountAmount = dto.DiscountAmount,
            PaymentMode = dto.PaymentMode,
            ReferenceNumber = dto.ReferenceNumber,
            Remarks = dto.Remarks
        };

        await repository.UpdateAsync(payment);
        var updated = await repository.GetByIdAsync(dto.SupplierPaymentID);
        return Result.Success(mapper.Map<SupplierPaymentDto>(updated));
    }

    public async Task DeleteAsync(int supplierPaymentId)
    {
        _ = await repository.GetByIdAsync(supplierPaymentId) ?? throw new NotFoundException(nameof(SupplierPayment), supplierPaymentId);
        await repository.DeleteAsync(supplierPaymentId);
    }
}
