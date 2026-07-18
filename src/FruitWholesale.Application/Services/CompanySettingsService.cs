using AutoMapper;
using FruitWholesale.Application.Common.Interfaces;
using FruitWholesale.Application.DTOs.CompanySettings;
using FruitWholesale.Domain.Enums;
using FruitWholesale.Shared.Exceptions;
using FruitWholesale.Shared.Results;

namespace FruitWholesale.Application.Services;

public interface ICompanySettingsService
{
    Task<CompanySettingsDto?> GetAsync();
    Task<CompanySettingsDto> SaveAsync(UpsertCompanySettingsDto dto);
    Task<Result> ApplyCashAdjustmentAsync(CashAdjustmentDto dto);
    Task<Result<CompanySettingsDto>> UpdateLogoAsync(string logoUrl);
}

public class CompanySettingsService(
    ICompanySettingsRepository companySettingsRepository,
    ILedgerService ledgerService,
    IDbConnectionFactory connectionFactory,
    IMapper mapper) : ICompanySettingsService
{
    public async Task<CompanySettingsDto?> GetAsync()
    {
        var settings = await companySettingsRepository.GetAsync();
        return settings is null ? null : mapper.Map<CompanySettingsDto>(settings);
    }

    public async Task<CompanySettingsDto> SaveAsync(UpsertCompanySettingsDto dto)
    {
        var existing = await companySettingsRepository.GetAsync();
        if (existing is null)
        {
            var created = new Domain.Entities.CompanySettings
            {
                CompanyName = dto.CompanyName,
                OwnerName = dto.OwnerName,
                Address = dto.Address,
                Phone = dto.Phone,
                GSTNo = dto.GSTNo,
                OpeningCashBalance = dto.OpeningCashBalance
            };
            created.CompanyID = await companySettingsRepository.CreateAsync(created);
            return mapper.Map<CompanySettingsDto>(created);
        }

        existing.CompanyName = dto.CompanyName;
        existing.OwnerName = dto.OwnerName;
        existing.Address = dto.Address;
        existing.Phone = dto.Phone;
        existing.GSTNo = dto.GSTNo;
        await companySettingsRepository.UpdateAsync(existing);
        return mapper.Map<CompanySettingsDto>(existing);
    }

    public async Task<Result<CompanySettingsDto>> UpdateLogoAsync(string logoUrl)
    {
        var existing = await companySettingsRepository.GetAsync();
        if (existing is null)
        {
            return Result.Failure<CompanySettingsDto>("Save the company profile before uploading a logo.");
        }

        await companySettingsRepository.UpdateLogoAsync(existing.CompanyID, logoUrl);
        existing.LogoUrl = logoUrl;
        return Result.Success(mapper.Map<CompanySettingsDto>(existing));
    }

    public async Task<Result> ApplyCashAdjustmentAsync(CashAdjustmentDto dto)
    {
        if (dto.Amount <= 0)
        {
            return Result.Failure("Adjustment amount must be greater than zero.");
        }

        using var connection = connectionFactory.CreateConnection();
        connection.Open();
        using var transaction = connection.BeginTransaction();
        try
        {
            var cashIn = dto.IsIncrease ? dto.Amount : 0;
            var cashOut = dto.IsIncrease ? 0 : dto.Amount;

            await ledgerService.AddCashLedgerEntryAsync(connection, transaction, DateTime.UtcNow,
                LedgerTransactionTypes.Adjustment, ReferenceTables.CompanySettings, null,
                PaymentModes.Cash, cashIn, cashOut, dto.Narration);
            await ledgerService.RecalculateCashLedgerAsync(connection, transaction);

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
