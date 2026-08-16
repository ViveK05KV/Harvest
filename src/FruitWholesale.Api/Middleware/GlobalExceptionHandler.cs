using FluentValidation;
using FruitWholesale.Shared.Exceptions;
using Microsoft.AspNetCore.Diagnostics;
using Microsoft.AspNetCore.Mvc;
using Npgsql;

namespace FruitWholesale.Api.Middleware;

public class GlobalExceptionHandler(ILogger<GlobalExceptionHandler> logger) : IExceptionHandler
{
    public async ValueTask<bool> TryHandleAsync(HttpContext httpContext, Exception exception, CancellationToken cancellationToken)
    {
        var (statusCode, title, detail, errors) = MapException(exception);

        if (statusCode >= 500)
        {
            logger.LogError(exception, "Unhandled exception processing {Method} {Path}", httpContext.Request.Method, httpContext.Request.Path);
        }
        else
        {
            logger.LogWarning("{ExceptionType}: {Message}", exception.GetType().Name, exception.Message);
        }

        var problemDetails = new ProblemDetails
        {
            Status = statusCode,
            Title = title,
            Detail = detail,
            Instance = httpContext.Request.Path
        };

        if (errors is not null)
        {
            problemDetails.Extensions["errors"] = errors;
        }

        httpContext.Response.StatusCode = statusCode;
        await httpContext.Response.WriteAsJsonAsync(problemDetails, cancellationToken);
        return true;
    }

    private static (int StatusCode, string Title, string Detail, IDictionary<string, string[]>? Errors) MapException(Exception exception) => exception switch
    {
        NotFoundException notFound => (StatusCodes.Status404NotFound, "Not Found", notFound.Message, null),
        BusinessRuleException businessRule => (StatusCodes.Status400BadRequest, "Business Rule Violation", businessRule.Message, null),
        ValidationAppException appValidation => (StatusCodes.Status400BadRequest, "Validation Failed", "One or more validation errors occurred.", appValidation.Errors),
        FluentValidation.ValidationException fluentValidation => (StatusCodes.Status400BadRequest, "Validation Failed", "One or more validation errors occurred.",
            fluentValidation.Errors.GroupBy(e => e.PropertyName).ToDictionary(g => g.Key, g => g.Select(e => e.ErrorMessage).ToArray())),
        UnauthorizedAccessException => (StatusCodes.Status403Forbidden, "Forbidden", "You do not have permission to perform this action.", null),
        PostgresException pg when pg.SqlState == PostgresErrorCodes.UniqueViolation =>
            (StatusCodes.Status409Conflict, "Conflict", "A record with the same value already exists. Please refresh and try again.", null),
        _ => (StatusCodes.Status500InternalServerError, "Internal Server Error", "An unexpected error occurred. Please try again later.", null)
    };
}
