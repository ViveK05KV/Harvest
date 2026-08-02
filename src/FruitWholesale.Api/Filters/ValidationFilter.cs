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
        // controller assigns it onto the DTO's own "{Entity}ID" property inside the
        // action body — but this filter runs before that body executes, so at validation
        // time the property is still whatever the request body had (usually 0/unset,
        // since the client only puts the id in the URL). Mirror that assignment here,
        // before validating, so a well-formed update isn't rejected by its own
        // GreaterThan(0) rule on that property.
        //
        // The DTO's id property doesn't always equal "{controller}ID" verbatim — e.g.
        // ShopMasterController's DTOs use ShopID, not ShopMasterID (the "Master" suffix
        // on the controller isn't part of the entity's id name), and UsersController's
        // DTO uses UserID against the plural controller name "Users". So instead of one
        // exact name, match every int property ending in "ID" whose name-minus-"ID"
        // appears anywhere in the controller name, and take the longest (most specific)
        // match — this also disambiguates DTOs carrying a foreign id too (e.g.
        // UpdateShopReturnDto has both ShopReturnID and ShopID; controller "ShopReturn"
        // contains both "Shop" and "ShopReturn", and the longer one is the correct
        // primary key). A plain prefix check isn't enough: DailyExpenseController's
        // UpdateDailyExpenseDto uses ExpenseID, and "Expense" is a substring of
        // "DailyExpense" but not a prefix of it.
        if (context.ActionArguments.TryGetValue("id", out var routeIdValue) && routeIdValue is int routeId
            && context.RouteData.Values.TryGetValue("controller", out var controllerNameValue) && controllerNameValue is string controllerName)
        {
            foreach (var argument in context.ActionArguments.Values)
            {
                if (argument is null) continue;

                var property = argument.GetType().GetProperties()
                    .Where(p => p.PropertyType == typeof(int) && p.CanWrite && p.Name.EndsWith("ID", StringComparison.Ordinal))
                    .Where(p => controllerName.Contains(p.Name[..^2], StringComparison.Ordinal))
                    .OrderByDescending(p => p.Name.Length)
                    .FirstOrDefault();

                property?.SetValue(argument, routeId);
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
