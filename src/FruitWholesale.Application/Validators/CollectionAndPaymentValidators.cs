using FluentValidation;
using FruitWholesale.Application.DTOs.Collection;
using FruitWholesale.Application.DTOs.DailyExpense;
using FruitWholesale.Application.DTOs.SupplierPayment;
using FruitWholesale.Domain.Enums;

namespace FruitWholesale.Application.Validators;

public class CreateCollectionValidator : AbstractValidator<CreateCollectionDto>
{
    public CreateCollectionValidator()
    {
        RuleFor(x => x.CollectionDate).NotEmpty();
        RuleFor(x => x.ShopID).GreaterThan(0);
        RuleFor(x => x.AmountReceived).GreaterThan(0);
        RuleFor(x => x.DiscountAmount).GreaterThanOrEqualTo(0);
        RuleFor(x => x.PaymentMode).NotEmpty().Must(m => PaymentModes.All.Contains(m)).WithMessage("Invalid payment mode.");
        RuleFor(x => x.CollectionType).NotEmpty().Must(m => CollectionTypes.All.Contains(m)).WithMessage("Invalid collection type.");
        RuleFor(x => x.TemporaryStatus).Must(m => TemporaryCollectionStatuses.All.Contains(m)).WithMessage("Invalid temporary status.");
        RuleFor(x => x.ReferenceNumber).MaximumLength(100);
        RuleFor(x => x.Remarks).MaximumLength(500);
    }
}

public class UpdateCollectionValidator : AbstractValidator<UpdateCollectionDto>
{
    public UpdateCollectionValidator()
    {
        RuleFor(x => x.CollectionID).GreaterThan(0);
        RuleFor(x => x.CollectionDate).NotEmpty();
        RuleFor(x => x.ShopID).GreaterThan(0);
        RuleFor(x => x.AmountReceived).GreaterThan(0);
        RuleFor(x => x.DiscountAmount).GreaterThanOrEqualTo(0);
        RuleFor(x => x.PaymentMode).NotEmpty().Must(m => PaymentModes.All.Contains(m)).WithMessage("Invalid payment mode.");
        RuleFor(x => x.CollectionType).NotEmpty().Must(m => CollectionTypes.All.Contains(m)).WithMessage("Invalid collection type.");
        RuleFor(x => x.TemporaryStatus).Must(m => TemporaryCollectionStatuses.All.Contains(m)).WithMessage("Invalid temporary status.");
        RuleFor(x => x.ReferenceNumber).MaximumLength(100);
        RuleFor(x => x.Remarks).MaximumLength(500);
    }
}

public class SettleCollectionsRequestValidator : AbstractValidator<SettleCollectionsRequestDto>
{
    public SettleCollectionsRequestValidator()
    {
        RuleFor(x => x.ShopID).GreaterThan(0);
        RuleFor(x => x.SettlementDate).NotEmpty();
    }
}

public class CreateSupplierPaymentValidator : AbstractValidator<CreateSupplierPaymentDto>
{
    public CreateSupplierPaymentValidator()
    {
        RuleFor(x => x.PaymentDate).NotEmpty();
        RuleFor(x => x.SupplierID).GreaterThan(0);
        RuleFor(x => x.AmountPaid).GreaterThan(0);
        RuleFor(x => x.DiscountAmount).GreaterThanOrEqualTo(0);
        RuleFor(x => x.PaymentMode).NotEmpty().Must(m => PaymentModes.All.Contains(m)).WithMessage("Invalid payment mode.");
        RuleFor(x => x.ReferenceNumber).MaximumLength(100);
        RuleFor(x => x.Remarks).MaximumLength(500);
    }
}

public class UpdateSupplierPaymentValidator : AbstractValidator<UpdateSupplierPaymentDto>
{
    public UpdateSupplierPaymentValidator()
    {
        RuleFor(x => x.SupplierPaymentID).GreaterThan(0);
        RuleFor(x => x.PaymentDate).NotEmpty();
        RuleFor(x => x.SupplierID).GreaterThan(0);
        RuleFor(x => x.AmountPaid).GreaterThan(0);
        RuleFor(x => x.DiscountAmount).GreaterThanOrEqualTo(0);
        RuleFor(x => x.PaymentMode).NotEmpty().Must(m => PaymentModes.All.Contains(m)).WithMessage("Invalid payment mode.");
        RuleFor(x => x.ReferenceNumber).MaximumLength(100);
        RuleFor(x => x.Remarks).MaximumLength(500);
    }
}

public class CreateDailyExpenseValidator : AbstractValidator<CreateDailyExpenseDto>
{
    public CreateDailyExpenseValidator()
    {
        RuleFor(x => x.ExpenseDate).NotEmpty();
        RuleFor(x => x.ExpenseCategoryID).GreaterThan(0);
        RuleFor(x => x.Amount).GreaterThan(0);
        RuleFor(x => x.PaymentMode).NotEmpty().Must(m => PaymentModes.All.Contains(m)).WithMessage("Invalid payment mode.");
        RuleFor(x => x.PaidTo).MaximumLength(200);
        RuleFor(x => x.Description).MaximumLength(500);
    }
}

public class UpdateDailyExpenseValidator : AbstractValidator<UpdateDailyExpenseDto>
{
    public UpdateDailyExpenseValidator()
    {
        RuleFor(x => x.ExpenseID).GreaterThan(0);
        RuleFor(x => x.ExpenseDate).NotEmpty();
        RuleFor(x => x.ExpenseCategoryID).GreaterThan(0);
        RuleFor(x => x.Amount).GreaterThan(0);
        RuleFor(x => x.PaymentMode).NotEmpty().Must(m => PaymentModes.All.Contains(m)).WithMessage("Invalid payment mode.");
        RuleFor(x => x.PaidTo).MaximumLength(200);
        RuleFor(x => x.Description).MaximumLength(500);
    }
}
