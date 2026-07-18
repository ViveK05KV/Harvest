using AutoMapper;
using FruitWholesale.Application.Common.Interfaces;
using FruitWholesale.Application.DTOs.Employee;
using FruitWholesale.Domain.Entities;
using FruitWholesale.Domain.Enums;
using FruitWholesale.Shared.Exceptions;
using FruitWholesale.Shared.Pagination;
using FruitWholesale.Shared.Results;

namespace FruitWholesale.Application.Services;

public interface IEmployeeWorkLogService
{
    Task<PaginatedList<EmployeeWorkLogDto>> GetPagedAsync(PaginationRequest request, int? employeeId, DateTime? fromDate, DateTime? toDate);
    Task<EmployeeWorkLogDto> GetByIdAsync(int employeeWorkLogId);
    Task<Result<EmployeeWorkLogDto>> CreateAsync(SaveEmployeeWorkLogDto dto, int? userId);
    Task<Result<EmployeeWorkLogDto>> UpdateAsync(SaveEmployeeWorkLogDto dto);
    Task DeleteAsync(int employeeWorkLogId);
}

public class EmployeeWorkLogService(IEmployeeWorkLogRepository repository, IMapper mapper) : IEmployeeWorkLogService
{
    public async Task<PaginatedList<EmployeeWorkLogDto>> GetPagedAsync(PaginationRequest request, int? employeeId, DateTime? fromDate, DateTime? toDate)
    {
        var result = await repository.GetPagedAsync(request, employeeId, fromDate, toDate);
        return new PaginatedList<EmployeeWorkLogDto>(mapper.Map<List<EmployeeWorkLogDto>>(result.Items), result.TotalCount, result.PageNumber, result.PageSize);
    }

    public async Task<EmployeeWorkLogDto> GetByIdAsync(int employeeWorkLogId)
    {
        var workLog = await repository.GetByIdAsync(employeeWorkLogId) ?? throw new NotFoundException(nameof(EmployeeWorkLog), employeeWorkLogId);
        return mapper.Map<EmployeeWorkLogDto>(workLog);
    }

    public async Task<Result<EmployeeWorkLogDto>> CreateAsync(SaveEmployeeWorkLogDto dto, int? userId)
    {
        var validation = Validate(dto);
        if (validation is not null) return Result.Failure<EmployeeWorkLogDto>(validation);

        var workLog = new EmployeeWorkLog
        {
            WorkDate = dto.WorkDate,
            EmployeeID = dto.EmployeeID,
            JobType = dto.JobType,
            RouteID = dto.RouteID,
            Amount = dto.Amount,
            PaymentMode = dto.PaymentMode,
            Remarks = dto.Remarks,
            CreatedBy = userId
        };

        workLog.EmployeeWorkLogID = await repository.CreateAsync(workLog);
        var created = await repository.GetByIdAsync(workLog.EmployeeWorkLogID);
        return Result.Success(mapper.Map<EmployeeWorkLogDto>(created));
    }

    public async Task<Result<EmployeeWorkLogDto>> UpdateAsync(SaveEmployeeWorkLogDto dto)
    {
        var validation = Validate(dto);
        if (validation is not null) return Result.Failure<EmployeeWorkLogDto>(validation);

        _ = await repository.GetByIdAsync(dto.EmployeeWorkLogID) ?? throw new NotFoundException(nameof(EmployeeWorkLog), dto.EmployeeWorkLogID);

        var workLog = new EmployeeWorkLog
        {
            EmployeeWorkLogID = dto.EmployeeWorkLogID,
            WorkDate = dto.WorkDate,
            EmployeeID = dto.EmployeeID,
            JobType = dto.JobType,
            RouteID = dto.RouteID,
            Amount = dto.Amount,
            PaymentMode = dto.PaymentMode,
            Remarks = dto.Remarks
        };

        await repository.UpdateAsync(workLog);
        var updated = await repository.GetByIdAsync(dto.EmployeeWorkLogID);
        return Result.Success(mapper.Map<EmployeeWorkLogDto>(updated));
    }

    public async Task DeleteAsync(int employeeWorkLogId)
    {
        _ = await repository.GetByIdAsync(employeeWorkLogId) ?? throw new NotFoundException(nameof(EmployeeWorkLog), employeeWorkLogId);
        await repository.DeleteAsync(employeeWorkLogId);
    }

    private static string? Validate(SaveEmployeeWorkLogDto dto)
    {
        if (dto.Amount < 0) return "Amount cannot be negative.";
        if (!JobTypes.All.Contains(dto.JobType)) return "Invalid job type.";
        if (dto.Amount > 0 && !PaymentModes.All.Contains(dto.PaymentMode)) return "Invalid payment mode.";
        return null;
    }
}
