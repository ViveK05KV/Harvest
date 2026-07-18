using FluentValidation;
using FruitWholesale.Application.DTOs.Supply;

namespace FruitWholesale.Application.Validators;

public class SaveSupplyItemValidator : AbstractValidator<SaveSupplyItemDto>
{
    public SaveSupplyItemValidator()
    {
        RuleFor(x => x.FruitID).GreaterThan(0);
        RuleFor(x => x.Quantity).GreaterThan(0);
        RuleFor(x => x.UnitPrice).GreaterThan(0);
    }
}

public class CreateSupplyValidator : AbstractValidator<CreateSupplyDto>
{
    public CreateSupplyValidator()
    {
        RuleFor(x => x.SupplyDate).NotEmpty();
        RuleFor(x => x.ShopID).GreaterThan(0);
        RuleFor(x => x.InvoiceNo).NotEmpty().MaximumLength(50);
        RuleFor(x => x.Remarks).MaximumLength(500);
        RuleFor(x => x.Items).NotEmpty().WithMessage("At least one item is required.");
        RuleForEach(x => x.Items).SetValidator(new SaveSupplyItemValidator());
    }
}

public class UpdateSupplyValidator : AbstractValidator<UpdateSupplyDto>
{
    public UpdateSupplyValidator()
    {
        RuleFor(x => x.SupplyID).GreaterThan(0);
        RuleFor(x => x.SupplyDate).NotEmpty();
        RuleFor(x => x.ShopID).GreaterThan(0);
        RuleFor(x => x.InvoiceNo).NotEmpty().MaximumLength(50);
        RuleFor(x => x.Remarks).MaximumLength(500);
        RuleFor(x => x.Items).NotEmpty().WithMessage("At least one item is required.");
        RuleForEach(x => x.Items).SetValidator(new SaveSupplyItemValidator());
    }
}
