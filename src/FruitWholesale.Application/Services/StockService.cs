using AutoMapper;
using FruitWholesale.Application.Common.Interfaces;
using FruitWholesale.Application.DTOs.Stock;
using FruitWholesale.Domain.Enums;
using FruitWholesale.Shared.Pagination;
using FruitWholesale.Shared.Results;

namespace FruitWholesale.Application.Services;

public interface IStockService
{
    Task<List<CurrentStockDto>> GetCurrentStockAsync();
    Task<PaginatedList<StockLedgerDto>> GetStockLedgerAsync(int fruitId, DateTime? fromDate, DateTime? toDate, PaginationRequest request);
    Task<Result> ApplyAdjustmentAsync(StockAdjustmentDto dto);
}

public class StockService(
    IFruitMasterRepository fruitRepository,
    ILedgerService ledgerService,
    IDbConnectionFactory connectionFactory,
    IMapper mapper) : IStockService
{
    public async Task<List<CurrentStockDto>> GetCurrentStockAsync()
    {
        var fruitsTask = fruitRepository.GetAllActiveAsync();
        var stockByFruitTask = ledgerService.GetCurrentStockForAllFruitsAsync();
        var boxSummaryByFruitTask = ledgerService.GetCurrentBoxSummaryForAllFruitsAsync();
        await Task.WhenAll(fruitsTask, stockByFruitTask, boxSummaryByFruitTask);

        var fruits = await fruitsTask;
        var stockByFruit = await stockByFruitTask;
        var boxSummaryByFruit = await boxSummaryByFruitTask;

        return fruits.Select(f =>
        {
            var boxSummary = boxSummaryByFruit.GetValueOrDefault(f.FruitID);
            return new CurrentStockDto
            {
                FruitID = f.FruitID,
                FruitName = f.FruitName,
                Unit = f.Unit,
                CurrentStock = stockByFruit.GetValueOrDefault(f.FruitID, 0m),
                TracksByBox = f.TracksByBox,
                FullBoxCount = boxSummary?.FullBoxCount ?? 0,
                OpenedBoxRemainingKg = boxSummary?.OpenedBoxRemainingKg
            };
        }).ToList();
    }

    public async Task<PaginatedList<StockLedgerDto>> GetStockLedgerAsync(int fruitId, DateTime? fromDate, DateTime? toDate, PaginationRequest request)
    {
        var result = await ledgerService.GetStockLedgerAsync(fruitId, fromDate, toDate, request.PageNumber, request.PageSize);
        return new PaginatedList<StockLedgerDto>(mapper.Map<List<StockLedgerDto>>(result.Items), result.TotalCount, request.PageNumber, request.PageSize);
    }

    public async Task<Result> ApplyAdjustmentAsync(StockAdjustmentDto dto)
    {
        if (dto.Quantity <= 0)
        {
            return Result.Failure("Adjustment quantity must be greater than zero.");
        }

        using var connection = connectionFactory.CreateConnection();
        connection.Open();
        using var transaction = connection.BeginTransaction();
        try
        {
            var quantityIn = dto.IsIncrease ? dto.Quantity : 0;
            var quantityOut = dto.IsIncrease ? 0 : dto.Quantity;

            await ledgerService.AddStockLedgerEntryAsync(connection, transaction, dto.FruitID, DateTime.UtcNow,
                LedgerTransactionTypes.Adjustment, ReferenceTables.FruitMaster, dto.FruitID, quantityIn, quantityOut, dto.Narration);
            await ledgerService.RecalculateStockLedgerAsync(connection, transaction, dto.FruitID);

            transaction.Commit();
            return Result.Success();
        }
        catch
        {
            transaction.Rollback();
            throw;
        }
    }
}
