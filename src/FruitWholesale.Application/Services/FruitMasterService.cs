using AutoMapper;
using FruitWholesale.Application.Common.Interfaces;
using FruitWholesale.Application.DTOs.FruitMaster;
using FruitWholesale.Domain.Entities;
using FruitWholesale.Shared.Exceptions;
using FruitWholesale.Shared.Pagination;
using FruitWholesale.Shared.Results;

namespace FruitWholesale.Application.Services;

public interface IFruitMasterService
{
    Task<PaginatedList<FruitMasterDto>> GetPagedAsync(PaginationRequest request);
    Task<IReadOnlyList<FruitMasterDto>> GetAllActiveAsync();
    Task<FruitMasterDto> GetByIdAsync(int fruitId);
    Task<Result<FruitMasterDto>> CreateAsync(CreateFruitMasterDto dto);
    Task<Result<FruitMasterDto>> UpdateAsync(UpdateFruitMasterDto dto);
    Task<Result> SetActiveAsync(int fruitId, bool isActive);
}

public class FruitMasterService(IFruitMasterRepository repository, IMapper mapper) : IFruitMasterService
{
    public async Task<PaginatedList<FruitMasterDto>> GetPagedAsync(PaginationRequest request)
    {
        var result = await repository.GetPagedAsync(request);
        return new PaginatedList<FruitMasterDto>(mapper.Map<List<FruitMasterDto>>(result.Items), result.TotalCount, result.PageNumber, result.PageSize);
    }

    public async Task<IReadOnlyList<FruitMasterDto>> GetAllActiveAsync()
    {
        var items = await repository.GetAllActiveAsync();
        return mapper.Map<List<FruitMasterDto>>(items);
    }

    public async Task<FruitMasterDto> GetByIdAsync(int fruitId)
    {
        var fruit = await repository.GetByIdAsync(fruitId) ?? throw new NotFoundException(nameof(FruitMaster), fruitId);
        return mapper.Map<FruitMasterDto>(fruit);
    }

    public async Task<Result<FruitMasterDto>> CreateAsync(CreateFruitMasterDto dto)
    {
        if (await repository.NameExistsAsync(dto.FruitName))
        {
            return Result.Failure<FruitMasterDto>("A fruit with this name already exists.");
        }

        var fruit = new FruitMaster { FruitName = dto.FruitName, Unit = dto.Unit, IsActive = true };
        fruit.FruitID = await repository.CreateAsync(fruit);
        return Result.Success(mapper.Map<FruitMasterDto>(fruit));
    }

    public async Task<Result<FruitMasterDto>> UpdateAsync(UpdateFruitMasterDto dto)
    {
        var fruit = await repository.GetByIdAsync(dto.FruitID) ?? throw new NotFoundException(nameof(FruitMaster), dto.FruitID);

        if (await repository.NameExistsAsync(dto.FruitName, dto.FruitID))
        {
            return Result.Failure<FruitMasterDto>("A fruit with this name already exists.");
        }

        fruit.FruitName = dto.FruitName;
        fruit.Unit = dto.Unit;
        await repository.UpdateAsync(fruit);
        return Result.Success(mapper.Map<FruitMasterDto>(fruit));
    }

    public async Task<Result> SetActiveAsync(int fruitId, bool isActive)
    {
        _ = await repository.GetByIdAsync(fruitId) ?? throw new NotFoundException(nameof(FruitMaster), fruitId);
        await repository.SetActiveAsync(fruitId, isActive);
        return Result.Success();
    }
}
