using FruitWholesale.Shared.Results;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace FruitWholesale.Api.Controllers;

[ApiController]
[Authorize]
[Route("api/[controller]")]
public abstract class ApiControllerBase : ControllerBase
{
    protected ActionResult<T> FromResult<T>(Result<T> result) =>
        result.IsSuccess ? Ok(result.Value) : BadRequest(new { errors = result.Errors });

    protected ActionResult FromResult(Result result) =>
        result.IsSuccess ? NoContent() : BadRequest(new { errors = result.Errors });
}
