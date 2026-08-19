using AutoMapper;
using FruitWholesale.Application.Common.Interfaces;
using FruitWholesale.Application.DTOs.ExpenseCategory;
using FruitWholesale.Domain.Entities;
using FruitWholesale.Shared.Exceptions;
using FruitWholesale.Shared.Pagination;
using FruitWholesale.Shared.Results;

namespace FruitWholesale.Application.Services;

public interface IExpenseCategoryService
{
    Task<PaginatedList<ExpenseCategoryDto>> GetPagedAsync(PaginationRequest request);
    Task<IReadOnlyList<ExpenseCategoryDto>> GetAllActiveAsync();
    Task<ExpenseCategoryDto> GetByIdAsync(int expenseCategoryId);
    Task<Result<ExpenseCategoryDto>> CreateAsync(CreateExpenseCategoryDto dto);
    Task<Result<ExpenseCategoryDto>> UpdateAsync(UpdateExpenseCategoryDto dto);
    Task SetActiveAsync(int expenseCategoryId, bool isActive);
    Task<Result> DeleteAsync(int expenseCategoryId);
}

public class ExpenseCategoryService(IExpenseCategoryRepository repository, IMapper mapper) : IExpenseCategoryService
{
    public async Task<PaginatedList<ExpenseCategoryDto>> GetPagedAsync(PaginationRequest request)
    {
        var result = await repository.GetPagedAsync(request);
        return new PaginatedList<ExpenseCategoryDto>(mapper.Map<List<ExpenseCategoryDto>>(result.Items), result.TotalCount, result.PageNumber, result.PageSize);
    }

    public async Task<IReadOnlyList<ExpenseCategoryDto>> GetAllActiveAsync()
    {
        var items = await repository.GetAllActiveAsync();
        return mapper.Map<List<ExpenseCategoryDto>>(items);
    }

    public async Task<ExpenseCategoryDto> GetByIdAsync(int expenseCategoryId)
    {
        var category = await repository.GetByIdAsync(expenseCategoryId) ?? throw new NotFoundException(nameof(ExpenseCategory), expenseCategoryId);
        return mapper.Map<ExpenseCategoryDto>(category);
    }

    public async Task<Result<ExpenseCategoryDto>> CreateAsync(CreateExpenseCategoryDto dto)
    {
        var category = new ExpenseCategory { CategoryName = dto.CategoryName, Description = dto.Description, IsActive = true };
        category.ExpenseCategoryID = await repository.CreateAsync(category);
        return Result.Success(mapper.Map<ExpenseCategoryDto>(category));
    }

    public async Task<Result<ExpenseCategoryDto>> UpdateAsync(UpdateExpenseCategoryDto dto)
    {
        var category = await repository.GetByIdAsync(dto.ExpenseCategoryID) ?? throw new NotFoundException(nameof(ExpenseCategory), dto.ExpenseCategoryID);
        category.CategoryName = dto.CategoryName;
        category.Description = dto.Description;
        await repository.UpdateAsync(category);
        return Result.Success(mapper.Map<ExpenseCategoryDto>(category));
    }

    public async Task SetActiveAsync(int expenseCategoryId, bool isActive)
    {
        _ = await repository.GetByIdAsync(expenseCategoryId) ?? throw new NotFoundException(nameof(ExpenseCategory), expenseCategoryId);
        await repository.SetActiveAsync(expenseCategoryId, isActive);
    }

    public async Task<Result> DeleteAsync(int expenseCategoryId)
    {
        _ = await repository.GetByIdAsync(expenseCategoryId) ?? throw new NotFoundException(nameof(ExpenseCategory), expenseCategoryId);
        if (await repository.IsInUseAsync(expenseCategoryId))
        {
            return Result.Failure("This category has expenses recorded against it and can't be deleted. Deactivate it instead.");
        }
        await repository.DeleteAsync(expenseCategoryId);
        return Result.Success();
    }
}
