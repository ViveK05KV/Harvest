using FruitWholesale.Application.Common.Interfaces;
using FruitWholesale.Domain.Enums;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Filters;

namespace FruitWholesale.Api.Filters;

/// <summary>
/// Mirrors ReportsAccessFilter for the Profit Calculator: ProfitController's
/// [Authorize(Roles = "Admin,Manager")] is a static check, but Manager access is actually
/// conditional on CompanySettings.ProfitVisibleToManagers - a runtime setting the admin
/// flips from the Settings page.
/// </summary>
public class ProfitAccessFilter(ICompanySettingsRepository companySettingsRepository) : IAsyncAuthorizationFilter
{
    public async Task OnAuthorizationAsync(AuthorizationFilterContext context)
    {
        var user = context.HttpContext.User;
        if (user.IsInRole(UserRoles.Admin)) return;

        if (!user.IsInRole(UserRoles.Manager))
        {
            context.Result = new ForbidResult();
            return;
        }

        var settings = await companySettingsRepository.GetAsync();
        if (settings is null || !settings.ProfitVisibleToManagers)
        {
            context.Result = new ForbidResult();
        }
    }
}
