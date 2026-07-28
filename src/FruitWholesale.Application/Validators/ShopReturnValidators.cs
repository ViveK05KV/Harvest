using FluentValidation;
using FruitWholesale.Application.DTOs.ShopReturn;

namespace FruitWholesale.Application.Validators;

public class SaveShopReturnItemValidator : AbstractValidator<SaveShopReturnItemDto>
{
    public SaveShopReturnItemValidator()
    {
        RuleFor(x => x.FruitID).GreaterThan(0);
        RuleFor(x => x.Quantity).GreaterThan(0);
        RuleFor(x => x.UnitPrice).GreaterThan(0);
    }
}

public class CreateShopReturnValidator : AbstractValidator<CreateShopReturnDto>
{
    public CreateShopReturnValidator()
    {
        RuleFor(x => x.ReturnDate).NotEmpty();
        RuleFor(x => x.ShopID).GreaterThan(0);
        RuleFor(x => x.ReferenceNo).NotEmpty().MaximumLength(50);
        RuleFor(x => x.Remarks).MaximumLength(500);
        RuleFor(x => x.Items).NotEmpty().WithMessage("At least one item is required.");
        RuleForEach(x => x.Items).SetValidator(new SaveShopReturnItemValidator());
    }
}

public class UpdateShopReturnValidator : AbstractValidator<UpdateShopReturnDto>
{
    public UpdateShopReturnValidator()
    {
        RuleFor(x => x.ShopReturnID).GreaterThan(0);
        RuleFor(x => x.ReturnDate).NotEmpty();
        RuleFor(x => x.ShopID).GreaterThan(0);
        RuleFor(x => x.ReferenceNo).NotEmpty().MaximumLength(50);
        RuleFor(x => x.Remarks).MaximumLength(500);
        RuleFor(x => x.Items).NotEmpty().WithMessage("At least one item is required.");
        RuleForEach(x => x.Items).SetValidator(new SaveShopReturnItemValidator());
    }
}
