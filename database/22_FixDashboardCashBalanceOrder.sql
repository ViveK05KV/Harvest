/* =====================================================================
   Fruit Wholesale Management System
   22_FixDashboardCashBalanceOrder.sql

   Bug: sp_GetDashboardSummary picked CurrentCashBalance via naive
   ORDER BY TransactionDate DESC, CashLedgerID DESC. Same class of bug
   fixed for the Cash Ledger page (16_FixCashLedgerOpeningBalanceOrder.sql
   / GetCurrentCashBalanceAsync) but never applied here: the opening
   balance/adjustment row can carry a later TransactionDate than
   backdated historical entries, so the naive ordering could resurface
   the opening row's balance as "current" on the Dashboard while the
   Cash Ledger page (already fixed) showed the correct final balance.

   Fix: re-create the procedure ranking that row first regardless of its
   own TransactionDate, matching 03_StoredProcedures.sql (kept in sync
   there for fresh installs) and the other two already-fixed call sites.

   Idempotent — safe to re-run against a live database.
   ===================================================================== */
USE FruitWholesaleDB;
GO

IF OBJECT_ID('dbo.sp_GetDashboardSummary', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_GetDashboardSummary;
GO
CREATE PROCEDURE dbo.sp_GetDashboardSummary
    @Today DATE
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @FirstCashLedgerID BIGINT = (SELECT MIN(CashLedgerID) FROM dbo.CashLedger);
    DECLARE @CurrentCashBalance DECIMAL(18,2) =
        ISNULL((
            SELECT TOP 1 RunningBalance
            FROM dbo.CashLedger
            ORDER BY
                CASE
                    WHEN CashLedgerID = @FirstCashLedgerID AND TransactionType IN ('OpeningBalance', 'Adjustment') THEN 0
                    ELSE 1
                END DESC,
                TransactionDate DESC,
                CashLedgerID DESC
        ), ISNULL((SELECT TOP 1 OpeningCashBalance FROM dbo.CompanySettings ORDER BY CompanyID), 0));

    DECLARE @TodayCollection DECIMAL(18,2) = ISNULL((SELECT SUM(AmountReceived) FROM dbo.Collections WHERE CollectionDate = @Today), 0);
    DECLARE @TodaySales       DECIMAL(18,2) = ISNULL((SELECT SUM(TotalAmount) FROM dbo.Supply WHERE SupplyDate = @Today), 0);
    DECLARE @TodayPurchases   DECIMAL(18,2) = ISNULL((SELECT SUM(TotalAmount) FROM dbo.Purchase WHERE PurchaseDate = @Today), 0);
    DECLARE @TodayExpenses    DECIMAL(18,2) = ISNULL((SELECT SUM(Amount) FROM dbo.DailyExpense WHERE ExpenseDate = @Today), 0);

    DECLARE @CustomerOutstanding DECIMAL(18,2) = ISNULL((
        SELECT SUM(latest.RunningBalance)
        FROM dbo.ShopMaster s
        OUTER APPLY (
            SELECT TOP 1 RunningBalance
            FROM dbo.ShopLedger sl
            WHERE sl.ShopID = s.ShopID
            ORDER BY sl.TransactionDate DESC, sl.LedgerID DESC
        ) latest
        WHERE s.IsActive = 1
    ), 0);

    DECLARE @SupplierOutstanding DECIMAL(18,2) = ISNULL((
        SELECT SUM(latest.RunningBalance)
        FROM dbo.SupplierMaster sp
        OUTER APPLY (
            SELECT TOP 1 RunningBalance
            FROM dbo.SupplierLedger spl
            WHERE spl.SupplierID = sp.SupplierID
            ORDER BY spl.TransactionDate DESC, spl.LedgerID DESC
        ) latest
        WHERE sp.IsActive = 1
    ), 0);

    SELECT
        @CurrentCashBalance    AS CurrentCashBalance,
        @TodayCollection       AS TodayCollection,
        @TodaySales            AS TodaySales,
        @TodayPurchases        AS TodayPurchases,
        @TodayExpenses         AS TodayExpenses,
        @CustomerOutstanding   AS CustomerOutstanding,
        @SupplierOutstanding   AS SupplierOutstanding,
        (@CurrentCashBalance + @CustomerOutstanding - @SupplierOutstanding) AS NetBusinessWorth;
END
GO

PRINT 'sp_GetDashboardSummary updated to fix Dashboard current cash balance ordering.';
GO
