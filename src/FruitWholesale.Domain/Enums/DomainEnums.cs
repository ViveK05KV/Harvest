namespace FruitWholesale.Domain.Enums;

public static class UserRoles
{
    public const string Admin = "Admin";
    public const string Manager = "Manager";
    public const string Accountant = "Accountant";
    public const string Staff = "Staff";

    public static readonly string[] All = [Admin, Manager, Accountant, Staff];
}

public static class PaymentModes
{
    public const string Cash = "Cash";
    public const string Bank = "Bank";
    public const string UPI = "UPI";
    public const string Cheque = "Cheque";

    public static readonly string[] All = [Cash, Bank, UPI, Cheque];
}

public static class LedgerTransactionTypes
{
    public const string OpeningBalance = "OpeningBalance";
    public const string Supply = "Supply";
    public const string Collection = "Collection";
    public const string Purchase = "Purchase";
    public const string SupplierPayment = "SupplierPayment";
    public const string DailyExpense = "DailyExpense";
    public const string EmployeeWorkLog = "EmployeeWorkLog";
    public const string Adjustment = "Adjustment";
    public const string ShopReturn = "ShopReturn";
    public const string SupplierReturn = "SupplierReturn";
}

public static class ReferenceTables
{
    public const string CompanySettings = "CompanySettings";
    public const string Supply = "Supply";
    public const string Collections = "Collections";
    public const string Purchase = "Purchase";
    public const string SupplierPayments = "SupplierPayments";
    public const string DailyExpense = "DailyExpense";
    public const string FruitMaster = "FruitMaster";
    public const string EmployeeWorkLog = "EmployeeWorkLog";
    public const string ShopReturns = "ShopReturns";
    public const string SupplierReturns = "SupplierReturns";
}

public static class DashboardPeriods
{
    public const string ThisWeek = "ThisWeek";
    public const string ThisMonth = "ThisMonth";
    public const string Last6Months = "Last6Months";
    public const string Last12Months = "Last12Months";

    public static readonly string[] All = [ThisWeek, ThisMonth, Last6Months, Last12Months];
}

public static class JobTypes
{
    public const string Supply = "Supply";
    public const string Collection = "Collection";
    public const string Loading = "Loading";
    public const string Other = "Other";

    public static readonly string[] All = [Supply, Collection, Loading, Other];
}

public static class FruitBoxStatuses
{
    public const string Full = "Full";
    public const string Opened = "Opened";
    public const string Empty = "Empty";
}
