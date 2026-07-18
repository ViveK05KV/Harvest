using AutoMapper;
using FruitWholesale.Application.DTOs.Collection;
using FruitWholesale.Application.DTOs.CompanySettings;
using FruitWholesale.Application.DTOs.DailyExpense;
using FruitWholesale.Application.DTOs.Employee;
using FruitWholesale.Application.DTOs.ExpenseCategory;
using FruitWholesale.Application.DTOs.FruitMaster;
using FruitWholesale.Application.DTOs.Ledger;
using FruitWholesale.Application.DTOs.Purchase;
using FruitWholesale.Application.DTOs.RouteMaster;
using FruitWholesale.Application.DTOs.ShopMaster;
using FruitWholesale.Application.DTOs.Stock;
using FruitWholesale.Application.DTOs.Supply;
using FruitWholesale.Application.DTOs.SupplierMaster;
using FruitWholesale.Application.DTOs.SupplierPayment;
using FruitWholesale.Application.DTOs.Users;
using FruitWholesale.Domain.Entities;

namespace FruitWholesale.Application.Common.Mapping;

public class MappingProfile : Profile
{
    public MappingProfile()
    {
        CreateMap<User, UserDto>();
        CreateMap<Domain.Entities.CompanySettings, CompanySettingsDto>();
        CreateMap<FruitMaster, FruitMasterDto>();

        CreateMap<ShopMaster, ShopMasterDto>()
            .ForMember(d => d.CurrentOutstanding, o => o.Ignore());
        CreateMap<SupplierMaster, SupplierMasterDto>()
            .ForMember(d => d.CurrentOutstanding, o => o.Ignore());

        CreateMap<ExpenseCategory, ExpenseCategoryDto>();

        CreateMap<Supply, SupplyDto>();
        CreateMap<Supply, SupplyListItemDto>();
        CreateMap<SupplyItem, SupplyItemDto>();
        CreateMap<SaveSupplyItemDto, SupplyItem>();

        CreateMap<Purchase, PurchaseDto>();
        CreateMap<Purchase, PurchaseListItemDto>();
        CreateMap<PurchaseItem, PurchaseItemDto>();
        CreateMap<SavePurchaseItemDto, PurchaseItem>();

        CreateMap<Collection, CollectionDto>();
        CreateMap<SupplierPayment, SupplierPaymentDto>();
        CreateMap<DailyExpense, DailyExpenseDto>();

        CreateMap<ShopLedger, ShopLedgerDto>();
        CreateMap<SupplierLedger, SupplierLedgerDto>();
        CreateMap<CashLedger, CashLedgerDto>();
        CreateMap<StockLedger, StockLedgerDto>();

        CreateMap<RouteMaster, RouteMasterDto>()
            .ForMember(d => d.ShopCount, o => o.Ignore());

        CreateMap<Employee, EmployeeDto>();
        CreateMap<EmployeeWorkLog, EmployeeWorkLogDto>();
    }
}
