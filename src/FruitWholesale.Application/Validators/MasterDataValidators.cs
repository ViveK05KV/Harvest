using FluentValidation;
using FruitWholesale.Application.DTOs.CompanySettings;
using FruitWholesale.Application.DTOs.ExpenseCategory;
using FruitWholesale.Application.DTOs.FruitMaster;
using FruitWholesale.Application.DTOs.ShopMaster;
using FruitWholesale.Application.DTOs.SupplierMaster;

namespace FruitWholesale.Application.Validators;

public class CreateFruitMasterValidator : AbstractValidator<CreateFruitMasterDto>
{
    public CreateFruitMasterValidator()
    {
        RuleFor(x => x.FruitName).NotEmpty().MaximumLength(150);
        RuleFor(x => x.Unit).NotEmpty().MaximumLength(20);
    }
}

public class UpdateFruitMasterValidator : AbstractValidator<UpdateFruitMasterDto>
{
    public UpdateFruitMasterValidator()
    {
        RuleFor(x => x.FruitID).GreaterThan(0);
        RuleFor(x => x.FruitName).NotEmpty().MaximumLength(150);
        RuleFor(x => x.Unit).NotEmpty().MaximumLength(20);
    }
}

public class CreateShopMasterValidator : AbstractValidator<CreateShopMasterDto>
{
    public CreateShopMasterValidator()
    {
        RuleFor(x => x.ShopName).NotEmpty().MaximumLength(200);
        RuleFor(x => x.Phone).MaximumLength(20);
        RuleFor(x => x.OpeningBalance).GreaterThanOrEqualTo(0);
        RuleFor(x => x.CreditLimit).GreaterThanOrEqualTo(0);
    }
}

public class UpdateShopMasterValidator : AbstractValidator<UpdateShopMasterDto>
{
    public UpdateShopMasterValidator()
    {
        RuleFor(x => x.ShopID).GreaterThan(0);
        RuleFor(x => x.ShopName).NotEmpty().MaximumLength(200);
        RuleFor(x => x.Phone).MaximumLength(20);
        RuleFor(x => x.CreditLimit).GreaterThanOrEqualTo(0);
    }
}

public class CreateSupplierMasterValidator : AbstractValidator<CreateSupplierMasterDto>
{
    public CreateSupplierMasterValidator()
    {
        RuleFor(x => x.SupplierName).NotEmpty().MaximumLength(200);
        RuleFor(x => x.Phone).MaximumLength(20);
        RuleFor(x => x.OpeningBalance).GreaterThanOrEqualTo(0);
    }
}

public class UpdateSupplierMasterValidator : AbstractValidator<UpdateSupplierMasterDto>
{
    public UpdateSupplierMasterValidator()
    {
        RuleFor(x => x.SupplierID).GreaterThan(0);
        RuleFor(x => x.SupplierName).NotEmpty().MaximumLength(200);
        RuleFor(x => x.Phone).MaximumLength(20);
    }
}

public class CreateExpenseCategoryValidator : AbstractValidator<CreateExpenseCategoryDto>
{
    public CreateExpenseCategoryValidator()
    {
        RuleFor(x => x.CategoryName).NotEmpty().MaximumLength(150);
        RuleFor(x => x.Description).MaximumLength(500);
    }
}

public class UpdateExpenseCategoryValidator : AbstractValidator<UpdateExpenseCategoryDto>
{
    public UpdateExpenseCategoryValidator()
    {
        RuleFor(x => x.ExpenseCategoryID).GreaterThan(0);
        RuleFor(x => x.CategoryName).NotEmpty().MaximumLength(150);
        RuleFor(x => x.Description).MaximumLength(500);
    }
}

public class UpsertCompanySettingsValidator : AbstractValidator<UpsertCompanySettingsDto>
{
    public UpsertCompanySettingsValidator()
    {
        RuleFor(x => x.CompanyName).NotEmpty().MaximumLength(200);
        RuleFor(x => x.Phone).MaximumLength(20);
        RuleFor(x => x.GSTNo).MaximumLength(50);
        RuleFor(x => x.OpeningCashBalance).GreaterThanOrEqualTo(0);
    }
}

public class CashAdjustmentValidator : AbstractValidator<CashAdjustmentDto>
{
    public CashAdjustmentValidator()
    {
        RuleFor(x => x.Amount).GreaterThan(0);
        RuleFor(x => x.Narration).NotEmpty().MaximumLength(500);
    }
}
