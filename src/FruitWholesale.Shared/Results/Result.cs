namespace FruitWholesale.Shared.Results;

public class Result
{
    public bool IsSuccess { get; }
    public string? Error { get; }
    public string[] Errors { get; }

    protected Result(bool isSuccess, string? error, string[]? errors = null)
    {
        IsSuccess = isSuccess;
        Error = error;
        Errors = errors ?? (error is null ? [] : [error]);
    }

    public static Result Success() => new(true, null);
    public static Result Failure(string error) => new(false, error);

    public static Result<T> Success<T>(T value) => Result<T>.Success(value);
    public static Result<T> Failure<T>(string error) => Result<T>.Failure(error);
}

public class Result<T> : Result
{
    public T? Value { get; }

    private Result(bool isSuccess, T? value, string? error, string[]? errors = null)
        : base(isSuccess, error, errors)
    {
        Value = value;
    }

    public static Result<T> Success(T value) => new(true, value, null);
    public new static Result<T> Failure(string error) => new(false, default, error);
}
