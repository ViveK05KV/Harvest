using FruitWholesale.Application.Common.Interfaces;
using FruitWholesale.Domain.Enums;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Filters;

namespace FruitWholesale.Api.Filters;

/// <summary>
/// ReportController's [Authorize(Roles = "Admin,Manager")] is a static check, but Manager
/// access is actually conditional on CompanySettings.ReportsVisibleToManagers - a runtime
/// setting the admin flips from the Settings page. [Authorize(Roles=...)] alone can't express
/// that, so this filter closes the gap for Manager after the static role check passes.
/// </summary>
public class ReportsAccessFilter(ICompanySettingsRepository companySettingsRepository) : IAsyncAuthorizationFilter
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
        if (settings is null || !settings.ReportsVisibleToManagers)
        {
            context.Result = new ForbidResult();
        }
    }
}
