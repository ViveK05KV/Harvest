/* =====================================================================
   Fruit Wholesale Management System
   29_AddDashboardSalaryTracking.sql

   Adds TodaySalary to sp_get_dashboard_summary (SUM of EmployeeWorkLog.Amount
   for today) so the Dashboard's Expenses tile and Net Profit figures can
   include salary paid alongside DailyExpense, not just DailyExpense alone.

   Idempotent — safe to re-run. Postgres refuses CREATE OR REPLACE when the
   RETURNS TABLE column set changes (adding TodaySalary here), so the old
   signature must be dropped first.
   ===================================================================== */

DROP FUNCTION IF EXISTS sp_get_dashboard_summary(DATE);

CREATE FUNCTION sp_get_dashboard_summary(p_today DATE)
RETURNS TABLE (
    CurrentCashBalance    DECIMAL(18,2),
    TodayCollection       DECIMAL(18,2),
    TodaySales            DECIMAL(18,2),
    TodayPurchases        DECIMAL(18,2),
    TodayExpenses         DECIMAL(18,2),
    TodaySalary           DECIMAL(18,2),
    CustomerOutstanding   DECIMAL(18,2),
    SupplierOutstanding   DECIMAL(18,2),
    NetBusinessWorth      DECIMAL(18,2)
) AS $$
DECLARE
    v_first_cash_ledger_id BIGINT;
    v_current_cash_balance DECIMAL(18,2);
    v_today_collection DECIMAL(18,2);
    v_today_sales DECIMAL(18,2);
    v_today_purchases DECIMAL(18,2);
    v_today_expenses DECIMAL(18,2);
    v_today_salary DECIMAL(18,2);
    v_customer_outstanding DECIMAL(18,2);
    v_supplier_outstanding DECIMAL(18,2);
BEGIN
    SELECT MIN(CashLedgerID) INTO v_first_cash_ledger_id FROM CashLedger;

    SELECT COALESCE((
        SELECT RunningBalance
        FROM CashLedger
        ORDER BY
            CASE
                WHEN CashLedgerID = v_first_cash_ledger_id AND TransactionType IN ('OpeningBalance', 'Adjustment') THEN 0
                ELSE 1
            END DESC,
            TransactionDate DESC,
            CashLedgerID DESC
        LIMIT 1
    ), COALESCE((SELECT OpeningCashBalance FROM CompanySettings ORDER BY CompanyID LIMIT 1), 0))
    INTO v_current_cash_balance;

    SELECT COALESCE(SUM(AmountReceived), 0) INTO v_today_collection FROM Collections WHERE CollectionDate = p_today;
    SELECT COALESCE(SUM(TotalAmount), 0) INTO v_today_sales FROM Supply WHERE SupplyDate = p_today;
    SELECT COALESCE(SUM(TotalAmount), 0) INTO v_today_purchases FROM Purchase WHERE PurchaseDate = p_today;
    SELECT COALESCE(SUM(Amount), 0) INTO v_today_expenses FROM DailyExpense WHERE ExpenseDate = p_today;
    SELECT COALESCE(SUM(Amount), 0) INTO v_today_salary FROM EmployeeWorkLog WHERE WorkDate = p_today;

    SELECT COALESCE(SUM(latest.RunningBalance), 0) INTO v_customer_outstanding
    FROM ShopMaster s
    LEFT JOIN LATERAL (
        SELECT sl.RunningBalance
        FROM ShopLedger sl
        WHERE sl.ShopID = s.ShopID
        ORDER BY sl.TransactionDate DESC, sl.LedgerID DESC
        LIMIT 1
    ) latest ON TRUE
    WHERE s.IsActive = TRUE;

    SELECT COALESCE(SUM(latest.RunningBalance), 0) INTO v_supplier_outstanding
    FROM SupplierMaster sp
    LEFT JOIN LATERAL (
        SELECT spl.RunningBalance
        FROM SupplierLedger spl
        WHERE spl.SupplierID = sp.SupplierID
        ORDER BY spl.TransactionDate DESC, spl.LedgerID DESC
        LIMIT 1
    ) latest ON TRUE
    WHERE sp.IsActive = TRUE;

    RETURN QUERY SELECT
        v_current_cash_balance,
        v_today_collection,
        v_today_sales,
        v_today_purchases,
        v_today_expenses,
        v_today_salary,
        v_customer_outstanding,
        v_supplier_outstanding,
        (v_current_cash_balance + v_customer_outstanding - v_supplier_outstanding);
END;
$$ LANGUAGE plpgsql;
