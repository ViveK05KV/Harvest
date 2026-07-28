using FruitWholesale.Application.Common.Interfaces;
using FruitWholesale.Infrastructure.Persistence;
using FruitWholesale.Infrastructure.Repositories;
using FruitWholesale.Infrastructure.Services;
using Microsoft.Extensions.DependencyInjection;

namespace FruitWholesale.Infrastructure;

public static class DependencyInjection
{
    public static IServiceCollection AddInfrastructure(this IServiceCollection services)
    {
        services.AddSingleton<IDbConnectionFactory, SqlConnectionFactory>();
        services.AddScoped<MigrationRunner>();
        services.AddScoped<ILedgerService, LedgerService>();
        services.AddScoped<IJwtTokenService, JwtTokenService>();

        services.AddScoped<ICompanySettingsRepository, CompanySettingsRepository>();
        services.AddScoped<IUserRepository, UserRepository>();
        services.AddScoped<IFruitMasterRepository, FruitMasterRepository>();
        services.AddScoped<IShopMasterRepository, ShopMasterRepository>();
        services.AddScoped<ISupplierMasterRepository, SupplierMasterRepository>();
        services.AddScoped<IExpenseCategoryRepository, ExpenseCategoryRepository>();
        services.AddScoped<IRouteRepository, RouteRepository>();
        services.AddScoped<IEmployeeRepository, EmployeeRepository>();

        services.AddScoped<ISupplyRepository, SupplyRepository>();
        services.AddScoped<IPurchaseRepository, PurchaseRepository>();
        services.AddScoped<IShopReturnRepository, ShopReturnRepository>();
        services.AddScoped<ISupplierReturnRepository, SupplierReturnRepository>();
        services.AddScoped<ICollectionRepository, CollectionRepository>();
        services.AddScoped<ISupplierPaymentRepository, SupplierPaymentRepository>();
        services.AddScoped<IDailyExpenseRepository, DailyExpenseRepository>();
        services.AddScoped<IEmployeeWorkLogRepository, EmployeeWorkLogRepository>();

        services.AddScoped<IDashboardRepository, DashboardRepository>();
        services.AddScoped<IReportRepository, ReportRepository>();
        services.AddScoped<IProfitRepository, ProfitRepository>();

        return services;
    }
}
