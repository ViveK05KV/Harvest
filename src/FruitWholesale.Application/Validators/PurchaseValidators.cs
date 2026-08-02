using FluentValidation;
using FruitWholesale.Application.DTOs.Purchase;

namespace FruitWholesale.Application.Validators;

public class SavePurchaseItemValidator : AbstractValidator<SavePurchaseItemDto>
{
    public SavePurchaseItemValidator()
    {
        RuleFor(x => x.FruitID).GreaterThan(0);
        RuleFor(x => x.Quantity).GreaterThan(0);
        RuleFor(x => x.PurchasePrice).GreaterThan(0);
        RuleFor(x => x.BoxCount).GreaterThan(0).When(x => x.BoxCount.HasValue);
    }
}

public class CreatePurchaseValidator : AbstractValidator<CreatePurchaseDto>
{
    public CreatePurchaseValidator()
    {
        RuleFor(x => x.PurchaseDate).NotEmpty();
        RuleFor(x => x.SupplierID).GreaterThan(0);
        RuleFor(x => x.InvoiceNo).NotEmpty().MaximumLength(50);
        RuleFor(x => x.Remarks).MaximumLength(500);
        RuleFor(x => x.Items).NotEmpty().WithMessage("At least one item is required.");
        RuleForEach(x => x.Items).SetValidator(new SavePurchaseItemValidator());
    }
}

public class UpdatePurchaseValidator : AbstractValidator<UpdatePurchaseDto>
{
    public UpdatePurchaseValidator()
    {
        RuleFor(x => x.PurchaseID).GreaterThan(0);
        RuleFor(x => x.PurchaseDate).NotEmpty();
        RuleFor(x => x.SupplierID).GreaterThan(0);
        RuleFor(x => x.InvoiceNo).NotEmpty().MaximumLength(50);
        RuleFor(x => x.Remarks).MaximumLength(500);
        RuleFor(x => x.Items).NotEmpty().WithMessage("At least one item is required.");
        RuleForEach(x => x.Items).SetValidator(new SavePurchaseItemValidator());
    }
}
