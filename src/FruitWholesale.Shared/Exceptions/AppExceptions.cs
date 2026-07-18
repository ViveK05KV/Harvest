namespace FruitWholesale.Shared.Exceptions;

public class NotFoundException(string entity, object key)
    : Exception($"{entity} with identifier '{key}' was not found.");

public class BusinessRuleException(string message) : Exception(message);

public class ValidationAppException(IDictionary<string, string[]> errors) : Exception("One or more validation errors occurred.")
{
    public IDictionary<string, string[]> Errors { get; } = errors;
}
