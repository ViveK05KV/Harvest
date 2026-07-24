using FruitWholesale.Application.Common.Interfaces;
using FruitWholesale.Application.DTOs.Profit;

namespace FruitWholesale.Application.Services;

public interface IProfitService
{
    Task<List<ShopDailyProfitRow>> GetShopDailyProfitAsync(int? shopId, DateTime? fromDate, DateTime? toDate);
    Task<List<ShopProfitSummaryRow>> GetShopProfitSummaryAsync(DateTime? fromDate, DateTime? toDate);
    Task<List<FruitProfitSummaryRow>> GetFruitProfitSummaryAsync(DateTime? fromDate, DateTime? toDate);
    Task<List<ShopFruitProfitRow>> GetShopFruitProfitAsync(int? shopId, DateTime? fromDate, DateTime? toDate);
    Task<BusinessProfitTotal> GetBusinessTotalProfitAsync();
}

public class ProfitService(IProfitRepository repository) : IProfitService
{
    public Task<List<ShopDailyProfitRow>> GetShopDailyProfitAsync(int? shopId, DateTime? fromDate, DateTime? toDate) =>
        repository.GetShopDailyProfitAsync(shopId, fromDate, toDate);

    public Task<List<ShopProfitSummaryRow>> GetShopProfitSummaryAsync(DateTime? fromDate, DateTime? toDate) =>
        repository.GetShopProfitSummaryAsync(fromDate, toDate);

    public Task<List<FruitProfitSummaryRow>> GetFruitProfitSummaryAsync(DateTime? fromDate, DateTime? toDate) =>
        repository.GetFruitProfitSummaryAsync(fromDate, toDate);

    public Task<List<ShopFruitProfitRow>> GetShopFruitProfitAsync(int? shopId, DateTime? fromDate, DateTime? toDate) =>
        repository.GetShopFruitProfitAsync(shopId, fromDate, toDate);

    public Task<BusinessProfitTotal> GetBusinessTotalProfitAsync() => repository.GetBusinessTotalProfitAsync();
}
