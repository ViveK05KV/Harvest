using AutoMapper;
using FruitWholesale.Application.Common.Interfaces;
using FruitWholesale.Application.DTOs.Employee;
using FruitWholesale.Domain.Entities;
using FruitWholesale.Domain.Enums;
using FruitWholesale.Shared.Exceptions;
using FruitWholesale.Shared.Results;

namespace FruitWholesale.Application.Services;

public interface IEmployeeLoanService
{
    Task<List<EmployeeLoanSummaryDto>> GetSummaryAsync();
    Task<List<EmployeeLoanHistoryRowDto>> GetHistoryAsync(int employeeId);
    Task<Result<EmployeeLoanRepaymentDto>> CreateRepaymentAsync(SaveEmployeeLoanRepaymentDto dto, int? userId);
    Task<Result<EmployeeLoanRepaymentDto>> UpdateRepaymentAsync(SaveEmployeeLoanRepaymentDto dto);
    Task DeleteRepaymentAsync(int employeeLoanRepaymentId);
    Task<Result> ApplyAdjustmentAsync(int employeeId, EmployeeLoanAdjustmentDto dto, int? userId);
    Task<Result> DeleteAdjustmentAsync(int employeeLoanAdjustmentId);
}

public class EmployeeLoanService(IEmployeeLoanRepository repository, IEmployeeRepository employeeRepository, IMapper mapper) : IEmployeeLoanService
{
    public async Task<List<EmployeeLoanSummaryDto>> GetSummaryAsync()
    {
        var employees = await employeeRepository.GetAllActiveAsync();
        var monthlyTotals = await repository.GetMonthlyPayTotalsBatchAsync();
        var repaymentTotals = await repository.GetRepaymentTotalsBatchAsync();
        var adjustmentTotals = await repository.GetAdjustmentTotalsBatchAsync();

        return employees.Select(e =>
        {
            var months = monthlyTotals.GetValueOrDefault(e.EmployeeID, []);
            var excessTotal = months.Sum(m => CalculateExcess(e, m));
            var repaid = repaymentTotals.GetValueOrDefault(e.EmployeeID, 0);
            var netAdjustment = adjustmentTotals.GetValueOrDefault(e.EmployeeID, 0);
            return new EmployeeLoanSummaryDto
            {
                EmployeeID = e.EmployeeID,
                EmployeeName = e.FullName,
                SalaryType = e.SalaryType,
                SalaryAmount = e.SalaryAmount,
                OutstandingLoan = Math.Max(0, excessTotal - repaid + netAdjustment)
            };
        }).ToList();
    }

    public async Task<List<EmployeeLoanHistoryRowDto>> GetHistoryAsync(int employeeId)
    {
        var employee = await employeeRepository.GetByIdAsync(employeeId) ?? throw new NotFoundException(nameof(Employee), employeeId);
        var months = await repository.GetMonthlyPayTotalsAsync(employeeId);
        var repayments = await repository.GetRepaymentsAsync(employeeId);
        var adjustments = await repository.GetAdjustmentsAsync(employeeId);

        var rows = new List<EmployeeLoanHistoryRowDto>();

        var today = DateTime.UtcNow.Date;
        foreach (var month in months)
        {
            var excess = CalculateExcess(employee, month);
            if (excess <= 0) continue;
            var monthEnd = new DateTime(month.Month.Year, month.Month.Month, 1).AddMonths(1).AddDays(-1);
            var isCurrentMonth = monthEnd >= today;
            rows.Add(new EmployeeLoanHistoryRowDto
            {
                // The current, still-in-progress month isn't "closed" yet - date it today
                // (not a future month-end date) and label it as running, not settled.
                TransactionDate = isCurrentMonth ? today : monthEnd,
                Particulars = isCurrentMonth ? $"Salary excess so far ({month.Month:MMMM yyyy})" : $"Salary excess ({month.Month:MMMM yyyy})",
                Debit = excess,
                Credit = 0
            });
        }

        foreach (var repayment in repayments)
        {
            rows.Add(new EmployeeLoanHistoryRowDto
            {
                TransactionDate = repayment.RepaymentDate,
                Particulars = "Loan Repayment",
                Debit = 0,
                Credit = repayment.Amount,
                EmployeeLoanRepaymentID = repayment.EmployeeLoanRepaymentID
            });
        }

        foreach (var adjustment in adjustments)
        {
            rows.Add(new EmployeeLoanHistoryRowDto
            {
                TransactionDate = adjustment.AdjustmentDate,
                Particulars = $"Adjustment{(adjustment.Narration.Length > 0 ? $" - {adjustment.Narration}" : "")}",
                Debit = adjustment.IsIncrease ? adjustment.Amount : 0,
                Credit = adjustment.IsIncrease ? 0 : adjustment.Amount,
                EmployeeLoanAdjustmentID = adjustment.EmployeeLoanAdjustmentID
            });
        }

        rows.Sort((a, b) => a.TransactionDate.CompareTo(b.TransactionDate));

        var balance = 0m;
        foreach (var row in rows)
        {
            balance += row.Debit - row.Credit;
            row.RunningBalance = balance;
        }

        return rows;
    }

    public async Task<Result<EmployeeLoanRepaymentDto>> CreateRepaymentAsync(SaveEmployeeLoanRepaymentDto dto, int? userId)
    {
        var validation = Validate(dto);
        if (validation is not null) return Result.Failure<EmployeeLoanRepaymentDto>(validation);

        var repayment = new EmployeeLoanRepayment
        {
            EmployeeID = dto.EmployeeID,
            RepaymentDate = dto.RepaymentDate,
            Amount = dto.Amount,
            PaymentMode = dto.PaymentMode,
            Remarks = dto.Remarks,
            CreatedBy = userId
        };

        repayment.EmployeeLoanRepaymentID = await repository.CreateRepaymentAsync(repayment);
        var created = await repository.GetRepaymentByIdAsync(repayment.EmployeeLoanRepaymentID);
        return Result.Success(mapper.Map<EmployeeLoanRepaymentDto>(created));
    }

    public async Task<Result<EmployeeLoanRepaymentDto>> UpdateRepaymentAsync(SaveEmployeeLoanRepaymentDto dto)
    {
        var validation = Validate(dto);
        if (validation is not null) return Result.Failure<EmployeeLoanRepaymentDto>(validation);

        _ = await repository.GetRepaymentByIdAsync(dto.EmployeeLoanRepaymentID) ?? throw new NotFoundException(nameof(EmployeeLoanRepayment), dto.EmployeeLoanRepaymentID);

        var repayment = new EmployeeLoanRepayment
        {
            EmployeeLoanRepaymentID = dto.EmployeeLoanRepaymentID,
            EmployeeID = dto.EmployeeID,
            RepaymentDate = dto.RepaymentDate,
            Amount = dto.Amount,
            PaymentMode = dto.PaymentMode,
            Remarks = dto.Remarks
        };

        await repository.UpdateRepaymentAsync(repayment);
        var updated = await repository.GetRepaymentByIdAsync(dto.EmployeeLoanRepaymentID);
        return Result.Success(mapper.Map<EmployeeLoanRepaymentDto>(updated));
    }

    public async Task DeleteRepaymentAsync(int employeeLoanRepaymentId)
    {
        _ = await repository.GetRepaymentByIdAsync(employeeLoanRepaymentId) ?? throw new NotFoundException(nameof(EmployeeLoanRepayment), employeeLoanRepaymentId);
        await repository.DeleteRepaymentAsync(employeeLoanRepaymentId);
    }

    public async Task<Result> ApplyAdjustmentAsync(int employeeId, EmployeeLoanAdjustmentDto dto, int? userId)
    {
        if (dto.Amount <= 0) return Result.Failure("Adjustment amount must be greater than zero.");
        if (string.IsNullOrWhiteSpace(dto.Narration)) return Result.Failure("Narration is required.");

        _ = await employeeRepository.GetByIdAsync(employeeId) ?? throw new NotFoundException(nameof(Employee), employeeId);

        await repository.CreateAdjustmentAsync(new EmployeeLoanAdjustment
        {
            EmployeeID = employeeId,
            AdjustmentDate = DateTime.UtcNow.Date,
            Amount = dto.Amount,
            IsIncrease = dto.IsIncrease,
            Narration = dto.Narration,
            CreatedBy = userId
        });
        return Result.Success();
    }

    public async Task<Result> DeleteAdjustmentAsync(int employeeLoanAdjustmentId)
    {
        _ = await repository.GetAdjustmentByIdAsync(employeeLoanAdjustmentId) ?? throw new NotFoundException(nameof(EmployeeLoanAdjustment), employeeLoanAdjustmentId);
        await repository.DeleteAdjustmentAsync(employeeLoanAdjustmentId);
        return Result.Success();
    }

    private static decimal CalculateExcess(Employee employee, EmployeeMonthlyPayTotal month)
    {
        var threshold = employee.SalaryType == SalaryTypes.Daily
            ? employee.SalaryAmount * month.DaysWorked
            : employee.SalaryAmount;
        return Math.Max(0, month.TotalPaid - threshold);
    }

    private static string? Validate(SaveEmployeeLoanRepaymentDto dto)
    {
        if (dto.EmployeeID <= 0) return "Employee is required.";
        if (dto.Amount <= 0) return "Amount must be greater than zero.";
        if (!PaymentModes.All.Contains(dto.PaymentMode)) return "Invalid payment mode.";
        return null;
    }
}
