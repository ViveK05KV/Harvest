using FluentValidation;
using FruitWholesale.Application.DTOs.Employee;
using FruitWholesale.Application.DTOs.RouteMaster;
using FruitWholesale.Application.DTOs.Stock;

namespace FruitWholesale.Application.Validators;

public class CreateRouteMasterValidator : AbstractValidator<CreateRouteMasterDto>
{
    public CreateRouteMasterValidator()
    {
        RuleFor(x => x.RouteName).NotEmpty().MaximumLength(150);
        RuleFor(x => x.Description).MaximumLength(500);
    }
}

public class UpdateRouteMasterValidator : AbstractValidator<UpdateRouteMasterDto>
{
    public UpdateRouteMasterValidator()
    {
        RuleFor(x => x.RouteID).GreaterThan(0);
        RuleFor(x => x.RouteName).NotEmpty().MaximumLength(150);
        RuleFor(x => x.Description).MaximumLength(500);
    }
}

public class CreateEmployeeValidator : AbstractValidator<CreateEmployeeDto>
{
    public CreateEmployeeValidator()
    {
        RuleFor(x => x.FullName).NotEmpty().MaximumLength(150);
        RuleFor(x => x.Phone).MaximumLength(20);
    }
}

public class UpdateEmployeeValidator : AbstractValidator<UpdateEmployeeDto>
{
    public UpdateEmployeeValidator()
    {
        RuleFor(x => x.EmployeeID).GreaterThan(0);
        RuleFor(x => x.FullName).NotEmpty().MaximumLength(150);
        RuleFor(x => x.Phone).MaximumLength(20);
    }
}

public class SaveEmployeeWorkLogValidator : AbstractValidator<SaveEmployeeWorkLogDto>
{
    public SaveEmployeeWorkLogValidator()
    {
        RuleFor(x => x.EmployeeID).GreaterThan(0);
        RuleFor(x => x.JobType).NotEmpty().MaximumLength(30);
        RuleFor(x => x.Amount).GreaterThanOrEqualTo(0);
        RuleFor(x => x.PaymentMode).NotEmpty().MaximumLength(30);
        RuleFor(x => x.Remarks).MaximumLength(500);
    }
}

public class StockAdjustmentValidator : AbstractValidator<StockAdjustmentDto>
{
    public StockAdjustmentValidator()
    {
        RuleFor(x => x.FruitID).GreaterThan(0);
        RuleFor(x => x.Quantity).GreaterThan(0);
        RuleFor(x => x.Narration).NotEmpty().MaximumLength(500);
    }
}
