using FruitWholesale.Domain.Entities;
using FruitWholesale.Shared.Pagination;

namespace FruitWholesale.Application.Common.Interfaces;

public interface ICompanySettingsRepository
{
    Task<CompanySettings?> GetAsync();
    Task<int> CreateAsync(CompanySettings settings);
    Task UpdateAsync(CompanySettings settings);
    Task UpdateLogoAsync(int companyId, string logoUrl);
}

public interface IUserRepository
{
    Task<User?> GetByIdAsync(int userId);
    Task<User?> GetByUsernameAsync(string username);
    Task<PaginatedList<User>> GetPagedAsync(PaginationRequest request);
    Task<int> CreateAsync(User user);
    Task UpdateAsync(User user);
    Task SetActiveAsync(int userId, bool isActive);
    Task<bool> UsernameExistsAsync(string username, int? excludeUserId = null);
    Task ChangePasswordAsync(int userId, string newPasswordHash);
}

public interface IFruitMasterRepository
{
    Task<FruitMaster?> GetByIdAsync(int fruitId);
    Task<IReadOnlyList<FruitMaster>> GetAllActiveAsync();
    Task<PaginatedList<FruitMaster>> GetPagedAsync(PaginationRequest request);
    Task<int> CreateAsync(FruitMaster fruit);
    Task UpdateAsync(FruitMaster fruit);
    Task SetActiveAsync(int fruitId, bool isActive);
    Task<bool> NameExistsAsync(string fruitName, int? excludeFruitId = null);
}

public interface IShopMasterRepository
{
    Task<ShopMaster?> GetByIdAsync(int shopId);
    Task<IReadOnlyList<ShopMaster>> GetAllActiveAsync();
    Task<PaginatedList<ShopMaster>> GetPagedAsync(PaginationRequest request);
    Task<int> CreateAsync(ShopMaster shop);
    Task UpdateAsync(ShopMaster shop);
    Task SetActiveAsync(int shopId, bool isActive);
}

public interface ISupplierMasterRepository
{
    Task<SupplierMaster?> GetByIdAsync(int supplierId);
    Task<IReadOnlyList<SupplierMaster>> GetAllActiveAsync();
    Task<PaginatedList<SupplierMaster>> GetPagedAsync(PaginationRequest request);
    Task<int> CreateAsync(SupplierMaster supplier);
    Task UpdateAsync(SupplierMaster supplier);
    Task SetActiveAsync(int supplierId, bool isActive);
}

public interface IExpenseCategoryRepository
{
    Task<ExpenseCategory?> GetByIdAsync(int expenseCategoryId);
    Task<IReadOnlyList<ExpenseCategory>> GetAllActiveAsync();
    Task<PaginatedList<ExpenseCategory>> GetPagedAsync(PaginationRequest request);
    Task<int> CreateAsync(ExpenseCategory category);
    Task UpdateAsync(ExpenseCategory category);
    Task SetActiveAsync(int expenseCategoryId, bool isActive);
}

public interface IRouteRepository
{
    Task<RouteMaster?> GetByIdAsync(int routeId);
    Task<IReadOnlyList<RouteMaster>> GetAllActiveAsync();
    Task<PaginatedList<RouteMaster>> GetPagedAsync(PaginationRequest request);
    Task<int> CreateAsync(RouteMaster route);
    Task UpdateAsync(RouteMaster route);
    Task SetActiveAsync(int routeId, bool isActive);
    Task<bool> NameExistsAsync(string routeName, int? excludeRouteId = null);
    Task<int> GetShopCountAsync(int routeId);
    Task<Dictionary<int, int>> GetShopCountBatchAsync(IEnumerable<int> routeIds);
}

public interface IEmployeeRepository
{
    Task<Employee?> GetByIdAsync(int employeeId);
    Task<IReadOnlyList<Employee>> GetAllActiveAsync();
    Task<PaginatedList<Employee>> GetPagedAsync(PaginationRequest request);
    Task<int> CreateAsync(Employee employee);
    Task UpdateAsync(Employee employee);
    Task SetActiveAsync(int employeeId, bool isActive);
}
