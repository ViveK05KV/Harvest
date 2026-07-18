using FruitWholesale.Application.Common.Interfaces;
using FruitWholesale.Application.DTOs.Auth;
using FruitWholesale.Domain.Enums;
using FruitWholesale.Shared.Results;

namespace FruitWholesale.Application.Services;

public interface IAuthService
{
    Task<Result<LoginResponseDto>> LoginAsync(LoginRequestDto request);
    Task<Result> ChangePasswordAsync(int userId, ChangePasswordRequestDto request);
}

public class AuthService(IUserRepository userRepository, IJwtTokenService jwtTokenService) : IAuthService
{
    public async Task<Result<LoginResponseDto>> LoginAsync(LoginRequestDto request)
    {
        var user = await userRepository.GetByUsernameAsync(request.Username);
        if (user is null || !BCrypt.Net.BCrypt.Verify(request.Password, user.PasswordHash))
        {
            return Result.Failure<LoginResponseDto>("Invalid username or password.");
        }

        if (!user.IsActive)
        {
            return Result.Failure<LoginResponseDto>("This account has been deactivated. Contact an administrator.");
        }

        var (token, expiresAt) = jwtTokenService.GenerateToken(user);

        return Result.Success(new LoginResponseDto
        {
            Token = token,
            ExpiresAt = expiresAt,
            UserID = user.UserID,
            FullName = user.FullName,
            Username = user.Username,
            Role = user.Role
        });
    }

    public async Task<Result> ChangePasswordAsync(int userId, ChangePasswordRequestDto request)
    {
        var user = await userRepository.GetByIdAsync(userId);
        if (user is null)
        {
            return Result.Failure("User not found.");
        }

        if (!BCrypt.Net.BCrypt.Verify(request.CurrentPassword, user.PasswordHash))
        {
            return Result.Failure("Current password is incorrect.");
        }

        var newHash = BCrypt.Net.BCrypt.HashPassword(request.NewPassword, workFactor: 11);
        await userRepository.ChangePasswordAsync(userId, newHash);
        return Result.Success();
    }
}
