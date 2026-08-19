using FluentValidation;
using FruitWholesale.Application.DTOs.Auth;

namespace FruitWholesale.Application.Validators;

public class LoginRequestValidator : AbstractValidator<LoginRequestDto>
{
    public LoginRequestValidator()
    {
        RuleFor(x => x.Username).NotEmpty().MaximumLength(100);
        RuleFor(x => x.Password).NotEmpty();
    }
}

public class ChangePasswordRequestValidator : AbstractValidator<ChangePasswordRequestDto>
{
    public ChangePasswordRequestValidator()
    {
        RuleFor(x => x.CurrentPassword).NotEmpty();
        RuleFor(x => x.NewPassword).NotEmpty().MinimumLength(6).MaximumLength(100);
    }
}

public class ChangeUsernameRequestValidator : AbstractValidator<ChangeUsernameRequestDto>
{
    public ChangeUsernameRequestValidator()
    {
        RuleFor(x => x.NewUsername).NotEmpty().MaximumLength(100).Matches("^[a-zA-Z0-9._-]+$")
            .WithMessage("Username can only contain letters, digits, dots, underscores and hyphens.");
        RuleFor(x => x.CurrentPassword).NotEmpty();
    }
}
