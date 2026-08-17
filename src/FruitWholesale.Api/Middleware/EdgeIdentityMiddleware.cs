using System.Security.Claims;

namespace FruitWholesale.Api.Middleware;

/// <summary>
/// Undoes the two things CloudFront's Origin Access Control does to a request's identity before
/// ASP.NET Core's own authentication gets to look at it. Must be registered before
/// <c>UseAuthentication</c>.
///
/// The API runs as a Lambda function URL with <c>AuthType=AWS_IAM</c>, reached through a CloudFront
/// OAC with <c>SigningBehavior=always</c>. That has two consequences:
///
/// 1. OAC overwrites the viewer's <c>Authorization</c> header with its own SigV4 signature, so a JWT
///    sent the usual way never survives the hop. Browser clients send it as <c>X-Authorization</c>
///    and this middleware puts it back where JwtBearer expects it. Clients that reach the API
///    directly (local dev, Swagger) keep using <c>Authorization</c> and are unaffected — the header
///    is only replaced when <c>X-Authorization</c> is actually present.
///
/// 2. Because the function URL uses IAM auth, Lambda populates <c>requestContext.authorizer.iam</c>
///    with the signing identity, and the ASP.NET Core Lambda adapter turns that into an
///    <b>authenticated</b> <see cref="ClaimsPrincipal"/> on <c>HttpContext.User</c>. Since OAC signs
///    every request, every request would arrive already authenticated. The authentication middleware
///    leaves an existing principal in place when JwtBearer returns no result, so plain
///    <c>[Authorize]</c> endpoints would be reachable with no JWT at all. Clearing the principal here
///    makes the JWT the only thing that can authenticate a caller.
/// </summary>
public class EdgeIdentityMiddleware(RequestDelegate next)
{
    private const string ForwardedHeader = "X-Authorization";

    public async Task InvokeAsync(HttpContext context)
    {
        if (context.Request.Headers.TryGetValue(ForwardedHeader, out var forwarded))
        {
            var value = forwarded.ToString();
            if (!string.IsNullOrWhiteSpace(value))
            {
                context.Request.Headers.Authorization = value;
            }
        }

        // Discard the infrastructure-supplied principal; only JwtBearer may authenticate a caller.
        context.User = new ClaimsPrincipal(new ClaimsIdentity());

        await next(context);
    }
}
