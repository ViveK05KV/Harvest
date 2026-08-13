using System.Security.Cryptography;
using FruitWholesale.Application.Common.Interfaces;
using FruitWholesale.Application.DTOs.Auth;
using FruitWholesale.Domain.Entities;
using FruitWholesale.Domain.Enums;
using FruitWholesale.Shared.Results;
using Microsoft.Extensions.Options;

namespace FruitWholesale.Application.Services;

public interface IAuthService
{
    Task<Result<LoginResponseDto>> LoginAsync(LoginRequestDto request);
    Task<Result<LoginResponseDto>> RefreshAsync(string? refreshToken);
    Task LogoutAsync(string? refreshToken);
    Task<Result> ChangePasswordAsync(int userId, ChangePasswordRequestDto request);
}

public class AuthService(
    IUserRepository userRepository,
    IRefreshTokenRepository refreshTokenRepository,
    IJwtTokenService jwtTokenService,
    IOptions<JwtSettings> jwtOptions) : IAuthService
{
    private readonly JwtSettings _jwtSettings = jwtOptions.Value;

    public async Task<Result<LoginResponseDto>> LoginAsync(LoginRequestDto? request)
    {
        if (request is null || string.IsNullOrWhiteSpace(request.Username) || string.IsNullOrWhiteSpace(request.Password))
        {
            return Result.Failure<LoginResponseDto>("Invalid username or password.");
        }

        var user = await userRepository.GetByUsernameAsync(request.Username);
        if (user is null || !BCrypt.Net.BCrypt.Verify(request.Password, user.PasswordHash))
        {
            return Result.Failure<LoginResponseDto>("Invalid username or password.");
        }

        if (!user.IsActive)
        {
            return Result.Failure<LoginResponseDto>("This account has been deactivated. Contact an administrator.");
        }

        return Result.Success(await BuildAuthResponseAsync(user));
    }

    // Rotates the refresh token on every use: the presented token is revoked
    // and replaced, so each refresh token is single-use. If a revoked token is
    // presented again - the tell for a stolen token being replayed after the
    // legitimate client already rotated past it - every active session for
    // that user is torn down rather than just rejecting the one request.
    public async Task<Result<LoginResponseDto>> RefreshAsync(string? refreshToken)
    {
        if (string.IsNullOrWhiteSpace(refreshToken))
        {
            return Result.Failure<LoginResponseDto>("Invalid refresh token.");
        }

        var hash = Hash(refreshToken);
        var stored = await refreshTokenRepository.GetByHashAsync(hash);
        if (stored is null)
        {
            return Result.Failure<LoginResponseDto>("Invalid refresh token.");
        }

        if (stored.RevokedAt is not null)
        {
            await refreshTokenRepository.RevokeAllActiveForUserAsync(stored.UserID);
            return Result.Failure<LoginResponseDto>("Session revoked. Please log in again.");
        }

        if (stored.ExpiresAt < DateTime.UtcNow)
        {
            return Result.Failure<LoginResponseDto>("Session expired. Please log in again.");
        }

        var user = await userRepository.GetByIdAsync(stored.UserID);
        if (user is null || !user.IsActive)
        {
            return Result.Failure<LoginResponseDto>("This account has been deactivated. Contact an administrator.");
        }

        var response = await BuildAuthResponseAsync(user);
        await refreshTokenRepository.RevokeAsync(stored.RefreshTokenID, Hash(response.RefreshToken));
        return Result.Success(response);
    }

    public async Task LogoutAsync(string? refreshToken)
    {
        if (string.IsNullOrWhiteSpace(refreshToken)) return;

        var stored = await refreshTokenRepository.GetByHashAsync(Hash(refreshToken));
        if (stored is not null && stored.RevokedAt is null)
        {
            await refreshTokenRepository.RevokeAsync(stored.RefreshTokenID, null);
        }
    }

    private async Task<LoginResponseDto> BuildAuthResponseAsync(User user)
    {
        var (token, expiresAt) = jwtTokenService.GenerateToken(user);
        var rawRefreshToken = GenerateRefreshToken();

        await refreshTokenRepository.CreateAsync(new RefreshToken
        {
            UserID = user.UserID,
            TokenHash = Hash(rawRefreshToken),
            ExpiresAt = DateTime.UtcNow.AddDays(_jwtSettings.RefreshTokenExpiryDays)
        });

        return new LoginResponseDto
        {
            Token = token,
            ExpiresAt = expiresAt,
            RefreshToken = rawRefreshToken,
            UserID = user.UserID,
            FullName = user.FullName,
            Username = user.Username,
            Role = user.Role
        };
    }

    private static string GenerateRefreshToken() => Convert.ToBase64String(RandomNumberGenerator.GetBytes(32));

    // Only the hash is ever persisted, so a leaked database backup doesn't
    // hand out usable session tokens the way a leaked password table would.
    private static string Hash(string rawToken) =>
        Convert.ToHexString(SHA256.HashData(System.Text.Encoding.UTF8.GetBytes(rawToken)));

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
