using AutoMapper;
using FruitWholesale.Application.Common.Interfaces;
using FruitWholesale.Application.DTOs.RouteMaster;
using FruitWholesale.Domain.Entities;
using FruitWholesale.Shared.Exceptions;
using FruitWholesale.Shared.Pagination;
using FruitWholesale.Shared.Results;

namespace FruitWholesale.Application.Services;

public interface IRouteMasterService
{
    Task<PaginatedList<RouteMasterDto>> GetPagedAsync(PaginationRequest request);
    Task<IReadOnlyList<RouteMasterDto>> GetAllActiveAsync();
    Task<RouteMasterDto> GetByIdAsync(int routeId);
    Task<Result<RouteMasterDto>> CreateAsync(CreateRouteMasterDto dto);
    Task<Result<RouteMasterDto>> UpdateAsync(UpdateRouteMasterDto dto);
    Task<Result> SetActiveAsync(int routeId, bool isActive);
}

public class RouteMasterService(IRouteRepository repository, IMapper mapper) : IRouteMasterService
{
    public async Task<PaginatedList<RouteMasterDto>> GetPagedAsync(PaginationRequest request)
    {
        var result = await repository.GetPagedAsync(request);
        var dtos = await EnrichWithShopCountAsync(result.Items);
        return new PaginatedList<RouteMasterDto>(dtos, result.TotalCount, result.PageNumber, result.PageSize);
    }

    public async Task<IReadOnlyList<RouteMasterDto>> GetAllActiveAsync()
    {
        var items = await repository.GetAllActiveAsync();
        return await EnrichWithShopCountAsync(items);
    }

    public async Task<RouteMasterDto> GetByIdAsync(int routeId)
    {
        var route = await repository.GetByIdAsync(routeId) ?? throw new NotFoundException(nameof(RouteMaster), routeId);
        var dto = mapper.Map<RouteMasterDto>(route);
        dto.ShopCount = await repository.GetShopCountAsync(routeId);
        return dto;
    }

    public async Task<Result<RouteMasterDto>> CreateAsync(CreateRouteMasterDto dto)
    {
        if (await repository.NameExistsAsync(dto.RouteName))
        {
            return Result.Failure<RouteMasterDto>("A route with this name already exists.");
        }

        var route = new RouteMaster { RouteName = dto.RouteName, Description = dto.Description, IsActive = true };
        route.RouteID = await repository.CreateAsync(route);
        return Result.Success(mapper.Map<RouteMasterDto>(route));
    }

    public async Task<Result<RouteMasterDto>> UpdateAsync(UpdateRouteMasterDto dto)
    {
        var route = await repository.GetByIdAsync(dto.RouteID) ?? throw new NotFoundException(nameof(RouteMaster), dto.RouteID);

        if (await repository.NameExistsAsync(dto.RouteName, dto.RouteID))
        {
            return Result.Failure<RouteMasterDto>("A route with this name already exists.");
        }

        route.RouteName = dto.RouteName;
        route.Description = dto.Description;
        await repository.UpdateAsync(route);

        var result = mapper.Map<RouteMasterDto>(route);
        result.ShopCount = await repository.GetShopCountAsync(route.RouteID);
        return Result.Success(result);
    }

    public async Task<Result> SetActiveAsync(int routeId, bool isActive)
    {
        _ = await repository.GetByIdAsync(routeId) ?? throw new NotFoundException(nameof(RouteMaster), routeId);
        await repository.SetActiveAsync(routeId, isActive);
        return Result.Success();
    }

    private async Task<List<RouteMasterDto>> EnrichWithShopCountAsync(IEnumerable<RouteMaster> routes)
    {
        var dtos = new List<RouteMasterDto>();
        foreach (var route in routes)
        {
            var dto = mapper.Map<RouteMasterDto>(route);
            dto.ShopCount = await repository.GetShopCountAsync(route.RouteID);
            dtos.Add(dto);
        }
        return dtos;
    }
}
