using AutoMapper;
using FruitWholesale.Application.Common.Interfaces;
using FruitWholesale.Application.DTOs.Users;
using FruitWholesale.Domain.Entities;
using FruitWholesale.Domain.Enums;
using FruitWholesale.Shared.Exceptions;
using FruitWholesale.Shared.Pagination;
using FruitWholesale.Shared.Results;

namespace FruitWholesale.Application.Services;

public interface IUserService
{
    Task<PaginatedList<UserDto>> GetPagedAsync(PaginationRequest request);
    Task<UserDto> GetByIdAsync(int userId);
    Task<Result<UserDto>> CreateAsync(CreateUserDto dto);
    Task<Result<UserDto>> UpdateAsync(UpdateUserDto dto);
    Task SetActiveAsync(int userId, bool isActive);
}

public class UserService(IUserRepository userRepository, IMapper mapper) : IUserService
{
    public async Task<PaginatedList<UserDto>> GetPagedAsync(PaginationRequest request)
    {
        var result = await userRepository.GetPagedAsync(request);
        return new PaginatedList<UserDto>(mapper.Map<List<UserDto>>(result.Items), result.TotalCount, result.PageNumber, result.PageSize);
    }

    public async Task<UserDto> GetByIdAsync(int userId)
    {
        var user = await userRepository.GetByIdAsync(userId) ?? throw new NotFoundException(nameof(User), userId);
        return mapper.Map<UserDto>(user);
    }

    public async Task<Result<UserDto>> CreateAsync(CreateUserDto dto)
    {
        if (await userRepository.UsernameExistsAsync(dto.Username))
        {
            return Result.Failure<UserDto>("Username is already taken.");
        }

        if (!UserRoles.All.Contains(dto.Role))
        {
            return Result.Failure<UserDto>("Invalid role.");
        }

        var user = new User
        {
            FullName = dto.FullName,
            Username = dto.Username,
            PasswordHash = BCrypt.Net.BCrypt.HashPassword(dto.Password, workFactor: 11),
            Role = dto.Role,
            IsActive = true
        };

        user.UserID = await userRepository.CreateAsync(user);
        return Result.Success(mapper.Map<UserDto>(user));
    }

    public async Task<Result<UserDto>> UpdateAsync(UpdateUserDto dto)
    {
        var user = await userRepository.GetByIdAsync(dto.UserID) ?? throw new NotFoundException(nameof(User), dto.UserID);

        if (!UserRoles.All.Contains(dto.Role))
        {
            return Result.Failure<UserDto>("Invalid role.");
        }

        user.FullName = dto.FullName;
        user.Role = dto.Role;
        await userRepository.UpdateAsync(user);
        return Result.Success(mapper.Map<UserDto>(user));
    }

    public async Task SetActiveAsync(int userId, bool isActive)
    {
        _ = await userRepository.GetByIdAsync(userId) ?? throw new NotFoundException(nameof(User), userId);
        await userRepository.SetActiveAsync(userId, isActive);
    }
}
