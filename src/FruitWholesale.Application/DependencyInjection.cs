using FluentValidation;
using FruitWholesale.Application.Common.Mapping;
using FruitWholesale.Application.Services;
using Microsoft.Extensions.DependencyInjection;

namespace FruitWholesale.Application;

public static class DependencyInjection
{
    public static IServiceCollection AddApplication(this IServiceCollection services)
    {
        services.AddAutoMapper(cfg => cfg.AddProfile<MappingProfile>());
        services.AddValidatorsFromAssemblyContaining<MappingProfile>();

        services.AddScoped<IAuthService, AuthService>();
        services.AddScoped<IUserService, UserService>();
        services.AddScoped<ICompanySettingsService, CompanySettingsService>();
        services.AddScoped<IFruitMasterService, FruitMasterService>();
        services.AddScoped<IShopMasterService, ShopMasterService>();
        services.AddScoped<ISupplierMasterService, SupplierMasterService>();
        services.AddScoped<IExpenseCategoryService, ExpenseCategoryService>();
        services.AddScoped<IRouteMasterService, RouteMasterService>();
        services.AddScoped<IEmployeeService, EmployeeService>();

        services.AddScoped<ISupplyService, SupplyService>();
        services.AddScoped<IPurchaseService, PurchaseService>();
        services.AddScoped<ICollectionService, CollectionService>();
        services.AddScoped<ISupplierPaymentService, SupplierPaymentService>();
        services.AddScoped<IDailyExpenseService, DailyExpenseService>();
        services.AddScoped<IEmployeeWorkLogService, EmployeeWorkLogService>();

        services.AddScoped<ILedgerAppService, LedgerAppService>();
        services.AddScoped<IStockService, StockService>();
        services.AddScoped<IDashboardService, DashboardService>();
        services.AddScoped<IReportService, ReportService>();
        services.AddScoped<IProfitService, ProfitService>();

        return services;
    }
}
