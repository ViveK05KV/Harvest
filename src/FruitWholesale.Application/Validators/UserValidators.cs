using FluentValidation;
using FruitWholesale.Application.DTOs.Users;
using FruitWholesale.Domain.Enums;

namespace FruitWholesale.Application.Validators;

public class CreateUserValidator : AbstractValidator<CreateUserDto>
{
    public CreateUserValidator()
    {
        RuleFor(x => x.FullName).NotEmpty().MaximumLength(150);
        RuleFor(x => x.Username).NotEmpty().MaximumLength(100).Matches("^[a-zA-Z0-9._-]+$")
            .WithMessage("Username can only contain letters, digits, dots, underscores and hyphens.");
        RuleFor(x => x.Password).NotEmpty().MinimumLength(6).MaximumLength(100);
        RuleFor(x => x.Role).NotEmpty().Must(r => UserRoles.All.Contains(r)).WithMessage("Invalid role.");
    }
}

public class UpdateUserValidator : AbstractValidator<UpdateUserDto>
{
    public UpdateUserValidator()
    {
        RuleFor(x => x.UserID).GreaterThan(0);
        RuleFor(x => x.FullName).NotEmpty().MaximumLength(150);
        RuleFor(x => x.Role).NotEmpty().Must(r => UserRoles.All.Contains(r)).WithMessage("Invalid role.");
    }
}
