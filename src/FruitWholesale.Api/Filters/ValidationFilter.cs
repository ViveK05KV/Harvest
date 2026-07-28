using FluentValidation;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Filters;

namespace FruitWholesale.Api.Filters;

/// <summary>
/// Runs the FluentValidation validator registered for each action argument type
/// (if one exists) before the action executes, short-circuiting with 400 on failure.
/// This keeps controllers free of repeated "if (!ModelState.IsValid) ..." boilerplate.
/// </summary>
public class ValidationFilter(IServiceProvider serviceProvider) : IAsyncActionFilter
{
    public async Task OnActionExecutionAsync(ActionExecutingContext context, ActionExecutionDelegate next)
    {
        // PUT actions take the id from the route (e.g. PUT /api/supply/{id}) and the
        // controller assigns it onto the DTO's own "{Controller}ID" property inside the
        // action body — but this filter runs before that body executes, so at validation
        // time the property is still whatever the request body had (usually 0/unset,
        // since the client only puts the id in the URL). Mirror that assignment here,
        // before validating, so a well-formed update isn't rejected by its own
        // GreaterThan(0) rule on that property.
        if (context.ActionArguments.TryGetValue("id", out var routeIdValue) && routeIdValue is int routeId
            && context.RouteData.Values.TryGetValue("controller", out var controllerNameValue) && controllerNameValue is string controllerName)
        {
            var idPropertyName = $"{controllerName}ID";
            foreach (var argument in context.ActionArguments.Values)
            {
                if (argument is null) continue;
                var property = argument.GetType().GetProperty(idPropertyName);
                if (property is not null && property.PropertyType == typeof(int) && property.CanWrite)
                {
                    property.SetValue(argument, routeId);
                }
            }
        }

        foreach (var argument in context.ActionArguments.Values)
        {
            if (argument is null) continue;

            var validatorType = typeof(IValidator<>).MakeGenericType(argument.GetType());
            if (serviceProvider.GetService(validatorType) is not IValidator validator) continue;

            var validationContext = new ValidationContext<object>(argument);
            var result = await validator.ValidateAsync(validationContext);
            if (!result.IsValid)
            {
                var errors = result.Errors
                    .GroupBy(e => e.PropertyName)
                    .ToDictionary(g => g.Key, g => g.Select(e => e.ErrorMessage).ToArray());

                context.Result = new BadRequestObjectResult(new ValidationProblemDetails(errors));
                return;
            }
        }

        await next();
    }
}
