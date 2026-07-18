using AutoMapper;
using FruitWholesale.Application.Common.Interfaces;
using FruitWholesale.Application.DTOs.Employee;
using FruitWholesale.Domain.Entities;
using FruitWholesale.Shared.Exceptions;
using FruitWholesale.Shared.Pagination;
using FruitWholesale.Shared.Results;

namespace FruitWholesale.Application.Services;

public interface IEmployeeService
{
    Task<PaginatedList<EmployeeDto>> GetPagedAsync(PaginationRequest request);
    Task<IReadOnlyList<EmployeeDto>> GetAllActiveAsync();
    Task<EmployeeDto> GetByIdAsync(int employeeId);
    Task<Result<EmployeeDto>> CreateAsync(CreateEmployeeDto dto);
    Task<Result<EmployeeDto>> UpdateAsync(UpdateEmployeeDto dto);
    Task SetActiveAsync(int employeeId, bool isActive);
}

public class EmployeeService(IEmployeeRepository repository, IMapper mapper) : IEmployeeService
{
    public async Task<PaginatedList<EmployeeDto>> GetPagedAsync(PaginationRequest request)
    {
        var result = await repository.GetPagedAsync(request);
        return new PaginatedList<EmployeeDto>(mapper.Map<List<EmployeeDto>>(result.Items), result.TotalCount, result.PageNumber, result.PageSize);
    }

    public async Task<IReadOnlyList<EmployeeDto>> GetAllActiveAsync()
    {
        var items = await repository.GetAllActiveAsync();
        return mapper.Map<List<EmployeeDto>>(items);
    }

    public async Task<EmployeeDto> GetByIdAsync(int employeeId)
    {
        var employee = await repository.GetByIdAsync(employeeId) ?? throw new NotFoundException(nameof(Employee), employeeId);
        return mapper.Map<EmployeeDto>(employee);
    }

    public async Task<Result<EmployeeDto>> CreateAsync(CreateEmployeeDto dto)
    {
        var employee = new Employee
        {
            FullName = dto.FullName,
            Phone = dto.Phone,
            Address = dto.Address,
            IsActive = true
        };
        employee.EmployeeID = await repository.CreateAsync(employee);
        return Result.Success(mapper.Map<EmployeeDto>(employee));
    }

    public async Task<Result<EmployeeDto>> UpdateAsync(UpdateEmployeeDto dto)
    {
        var employee = await repository.GetByIdAsync(dto.EmployeeID) ?? throw new NotFoundException(nameof(Employee), dto.EmployeeID);
        employee.FullName = dto.FullName;
        employee.Phone = dto.Phone;
        employee.Address = dto.Address;
        await repository.UpdateAsync(employee);

        return Result.Success(mapper.Map<EmployeeDto>(employee));
    }

    public async Task SetActiveAsync(int employeeId, bool isActive)
    {
        _ = await repository.GetByIdAsync(employeeId) ?? throw new NotFoundException(nameof(Employee), employeeId);
        await repository.SetActiveAsync(employeeId, isActive);
    }
}
