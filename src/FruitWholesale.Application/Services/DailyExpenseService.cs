using AutoMapper;
using FruitWholesale.Application.Common.Interfaces;
using FruitWholesale.Application.DTOs.DailyExpense;
using FruitWholesale.Domain.Entities;
using FruitWholesale.Domain.Enums;
using FruitWholesale.Shared.Exceptions;
using FruitWholesale.Shared.Pagination;
using FruitWholesale.Shared.Results;

namespace FruitWholesale.Application.Services;

public interface IDailyExpenseService
{
    Task<PaginatedList<DailyExpenseDto>> GetPagedAsync(PaginationRequest request, int? expenseCategoryId, DateTime? fromDate, DateTime? toDate);
    Task<DailyExpenseDto> GetByIdAsync(int expenseId);
    Task<Result<DailyExpenseDto>> CreateAsync(CreateDailyExpenseDto dto, int? userId);
    Task<Result<DailyExpenseDto>> UpdateAsync(UpdateDailyExpenseDto dto);
    Task DeleteAsync(int expenseId);
}

public class DailyExpenseService(IDailyExpenseRepository repository, IMapper mapper) : IDailyExpenseService
{
    public async Task<PaginatedList<DailyExpenseDto>> GetPagedAsync(PaginationRequest request, int? expenseCategoryId, DateTime? fromDate, DateTime? toDate)
    {
        var result = await repository.GetPagedAsync(request, expenseCategoryId, fromDate, toDate);
        return new PaginatedList<DailyExpenseDto>(mapper.Map<List<DailyExpenseDto>>(result.Items), result.TotalCount, result.PageNumber, result.PageSize);
    }

    public async Task<DailyExpenseDto> GetByIdAsync(int expenseId)
    {
        var expense = await repository.GetByIdAsync(expenseId) ?? throw new NotFoundException(nameof(DailyExpense), expenseId);
        return mapper.Map<DailyExpenseDto>(expense);
    }

    public async Task<Result<DailyExpenseDto>> CreateAsync(CreateDailyExpenseDto dto, int? userId)
    {
        if (dto.Amount <= 0)
        {
            return Result.Failure<DailyExpenseDto>("Amount must be greater than zero.");
        }

        if (!PaymentModes.All.Contains(dto.PaymentMode))
        {
            return Result.Failure<DailyExpenseDto>("Invalid payment mode.");
        }

        var expense = new DailyExpense
        {
            ExpenseDate = dto.ExpenseDate,
            ExpenseCategoryID = dto.ExpenseCategoryID,
            Amount = dto.Amount,
            PaymentMode = dto.PaymentMode,
            PaidTo = dto.PaidTo,
            Description = dto.Description,
            CreatedBy = userId
        };

        expense.ExpenseID = await repository.CreateAsync(expense);
        var created = await repository.GetByIdAsync(expense.ExpenseID);
        return Result.Success(mapper.Map<DailyExpenseDto>(created));
    }

    public async Task<Result<DailyExpenseDto>> UpdateAsync(UpdateDailyExpenseDto dto)
    {
        if (dto.Amount <= 0)
        {
            return Result.Failure<DailyExpenseDto>("Amount must be greater than zero.");
        }

        _ = await repository.GetByIdAsync(dto.ExpenseID) ?? throw new NotFoundException(nameof(DailyExpense), dto.ExpenseID);

        var expense = new DailyExpense
        {
            ExpenseID = dto.ExpenseID,
            ExpenseDate = dto.ExpenseDate,
            ExpenseCategoryID = dto.ExpenseCategoryID,
            Amount = dto.Amount,
            PaymentMode = dto.PaymentMode,
            PaidTo = dto.PaidTo,
            Description = dto.Description
        };

        await repository.UpdateAsync(expense);
        var updated = await repository.GetByIdAsync(dto.ExpenseID);
        return Result.Success(mapper.Map<DailyExpenseDto>(updated));
    }

    public async Task DeleteAsync(int expenseId)
    {
        _ = await repository.GetByIdAsync(expenseId) ?? throw new NotFoundException(nameof(DailyExpense), expenseId);
        await repository.DeleteAsync(expenseId);
    }
}
