using FruitWholesale.Application.Common.Interfaces;
using FruitWholesale.Application.DTOs.Auth;
using FruitWholesale.Application.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace FruitWholesale.Api.Controllers;

public class AuthController(IAuthService authService, ICurrentUserService currentUserService) : ApiControllerBase
{
    [HttpPost("login")]
    [AllowAnonymous]
    public async Task<ActionResult<LoginResponseDto>> Login([FromBody] LoginRequestDto request)
    {
        var result = await authService.LoginAsync(request);
        return result.IsSuccess ? Ok(result.Value) : Unauthorized(new { errors = result.Errors });
    }

    [HttpPost("change-password")]
    public async Task<ActionResult> ChangePassword(ChangePasswordRequestDto request)
    {
        var result = await authService.ChangePasswordAsync(currentUserService.UserId!.Value, request);
        return FromResult(result);
    }
}
