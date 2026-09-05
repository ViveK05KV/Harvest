namespace FruitWholesale.Application.DTOs.Employee;

public class EmployeeLoanSummaryDto
{
    public int EmployeeID { get; set; }
    public string EmployeeName { get; set; } = string.Empty;
    public string SalaryType { get; set; } = string.Empty;
    public decimal SalaryAmount { get; set; }
    public decimal OutstandingLoan { get; set; }
}

/// <summary>
/// One row in an employee's loan history - either a synthetic "month's pay
/// exceeded salary" debit (computed live, never stored) or a real
/// EmployeeLoanRepayment credit. Rows are merged and sorted by date, with
/// RunningBalance accumulated across the whole list.
/// </summary>
public class EmployeeLoanHistoryRowDto
{
    public DateTime TransactionDate { get; set; }
    public string Particulars { get; set; } = string.Empty;
    public decimal Debit { get; set; }
    public decimal Credit { get; set; }
    public decimal RunningBalance { get; set; }
    /// <summary>Set only for repayment rows - lets the UI offer delete on that row.</summary>
    public int? EmployeeLoanRepaymentID { get; set; }
    /// <summary>Set only for manual adjustment rows - lets the UI offer delete on that row.</summary>
    public int? EmployeeLoanAdjustmentID { get; set; }
}

/// <summary>Posts a manual correction to an employee's outstanding loan (mirrors ShopBalanceAdjustment). No cash moves - pure bookkeeping.</summary>
public class EmployeeLoanAdjustmentDto
{
    public decimal Amount { get; set; }
    public bool IsIncrease { get; set; }
    public string Narration { get; set; } = string.Empty;
}

public class EmployeeLoanRepaymentDto
{
    public int EmployeeLoanRepaymentID { get; set; }
    public int EmployeeID { get; set; }
    public string EmployeeName { get; set; } = string.Empty;
    public DateTime RepaymentDate { get; set; }
    public decimal Amount { get; set; }
    public string PaymentMode { get; set; } = string.Empty;
    public string? Remarks { get; set; }
}

public class SaveEmployeeLoanRepaymentDto
{
    public int EmployeeLoanRepaymentID { get; set; }
    public int EmployeeID { get; set; }
    public DateTime RepaymentDate { get; set; }
    public decimal Amount { get; set; }
    public string PaymentMode { get; set; } = string.Empty;
    public string? Remarks { get; set; }
}

/// <summary>Internal read model for a completed calendar month's pay total for one employee (not exposed via the API).</summary>
public class EmployeeMonthlyPayTotal
{
    public DateTime Month { get; set; }
    public decimal TotalPaid { get; set; }
    public int DaysWorked { get; set; }
}
