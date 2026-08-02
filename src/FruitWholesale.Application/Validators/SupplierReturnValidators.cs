using FluentValidation;
using FruitWholesale.Application.DTOs.SupplierReturn;

namespace FruitWholesale.Application.Validators;

public class SaveSupplierReturnItemValidator : AbstractValidator<SaveSupplierReturnItemDto>
{
    public SaveSupplierReturnItemValidator()
    {
        RuleFor(x => x.FruitID).GreaterThan(0);
        RuleFor(x => x.Quantity).GreaterThan(0);
        RuleFor(x => x.UnitPrice).GreaterThan(0);
        RuleFor(x => x.BoxCount).GreaterThan(0).When(x => x.BoxCount.HasValue);
    }
}

public class CreateSupplierReturnValidator : AbstractValidator<CreateSupplierReturnDto>
{
    public CreateSupplierReturnValidator()
    {
        RuleFor(x => x.ReturnDate).NotEmpty();
        RuleFor(x => x.SupplierID).GreaterThan(0);
        RuleFor(x => x.ReferenceNo).NotEmpty().MaximumLength(50);
        RuleFor(x => x.Remarks).MaximumLength(500);
        RuleFor(x => x.Items).NotEmpty().WithMessage("At least one item is required.");
        RuleForEach(x => x.Items).SetValidator(new SaveSupplierReturnItemValidator());
    }
}

public class UpdateSupplierReturnValidator : AbstractValidator<UpdateSupplierReturnDto>
{
    public UpdateSupplierReturnValidator()
    {
        RuleFor(x => x.SupplierReturnID).GreaterThan(0);
        RuleFor(x => x.ReturnDate).NotEmpty();
        RuleFor(x => x.SupplierID).GreaterThan(0);
        RuleFor(x => x.ReferenceNo).NotEmpty().MaximumLength(50);
        RuleFor(x => x.Remarks).MaximumLength(500);
        RuleFor(x => x.Items).NotEmpty().WithMessage("At least one item is required.");
        RuleForEach(x => x.Items).SetValidator(new SaveSupplierReturnItemValidator());
    }
}
