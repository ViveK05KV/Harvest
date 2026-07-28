using FruitWholesale.Application.DTOs.Users;
using FruitWholesale.Application.Services;
using FruitWholesale.Domain.Enums;
using FruitWholesale.Shared.Pagination;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace FruitWholesale.Api.Controllers;

[Authorize(Roles = $"{UserRoles.Admin},{UserRoles.Accountant}")]
public class UsersController(IUserService userService) : ApiControllerBase
{
    [HttpGet]
    public async Task<ActionResult<PaginatedList<UserDto>>> GetPaged([FromQuery] PaginationRequest request) =>
        Ok(await userService.GetPagedAsync(request));

    [HttpGet("{id:int}")]
    public async Task<ActionResult<UserDto>> GetById(int id) => Ok(await userService.GetByIdAsync(id));

    [HttpPost]
    public async Task<ActionResult<UserDto>> Create(CreateUserDto dto) => FromResult(await userService.CreateAsync(dto));

    [HttpPut("{id:int}")]
    public async Task<ActionResult<UserDto>> Update(int id, UpdateUserDto dto)
    {
        dto.UserID = id;
        return FromResult(await userService.UpdateAsync(dto));
    }

    [HttpPatch("{id:int}/activate")]
    public async Task<ActionResult> Activate(int id)
    {
        await userService.SetActiveAsync(id, true);
        return NoContent();
    }

    [HttpPatch("{id:int}/deactivate")]
    public async Task<ActionResult> Deactivate(int id)
    {
        await userService.SetActiveAsync(id, false);
        return NoContent();
    }
}
