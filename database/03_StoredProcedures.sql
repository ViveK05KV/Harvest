/* =====================================================================
   Fruit Wholesale Management System
   03_StoredProcedures.sql

   Stored procedures are used only where they provide a real benefit:
     - Recalculating running balances after a backdated edit/delete
       (a set-based cursor operation that is far cheaper done in T-SQL
       than round-tripping every row to the application).
     - The dashboard summary, which aggregates many tables in one
       round trip.
   All other CRUD operations are handled in the Infrastructure layer via
   Dapper so business logic stays in one place (C#) and is unit-testable.
   ===================================================================== */
USE FruitWholesaleDB;
GO

-- =========================================================================
-- sp_RecalculateShopLedgerBalance
-- Recomputes RunningBalance for every ShopLedger row of a shop, in date
-- order. The shop's OpeningBalance is booked as its own 'OpeningBalance'
-- ledger row at shop-creation time, so this sums strictly from zero —
-- it must NOT re-add ShopMaster.OpeningBalance, or the opening balance
-- would be double counted. Call after any insert, update or delete that
-- touches a shop's ledger with a backdated entry.
-- =========================================================================
IF OBJECT_ID('dbo.sp_RecalculateShopLedgerBalance', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_RecalculateShopLedgerBalance;
GO
CREATE PROCEDURE dbo.sp_RecalculateShopLedgerBalance
    @ShopID INT
AS
BEGIN
    SET NOCOUNT ON;

    ;WITH Ordered AS
    (
        SELECT
            LedgerID,
            Debit,
            Credit,
            ROW_NUMBER() OVER (ORDER BY TransactionDate ASC, LedgerID ASC) AS rn
        FROM dbo.ShopLedger
        WHERE ShopID = @ShopID
    )
    SELECT * INTO #ShopLedgerCalc FROM Ordered;

    UPDATE t
    SET t.RunningBalance = c.NewBalance
    FROM dbo.ShopLedger t
    INNER JOIN
    (
        SELECT
            LedgerID,
            SUM(Debit - Credit) OVER (ORDER BY rn ROWS UNBOUNDED PRECEDING) AS NewBalance
        FROM #ShopLedgerCalc
    ) c ON c.LedgerID = t.LedgerID;

    DROP TABLE #ShopLedgerCalc;
END
GO

-- =========================================================================
-- sp_RecalculateSupplierLedgerBalance
-- Same approach as sp_RecalculateShopLedgerBalance: the supplier's
-- OpeningBalance is booked as its own ledger row at supplier-creation
-- time, so this sums strictly from zero.
-- =========================================================================
IF OBJECT_ID('dbo.sp_RecalculateSupplierLedgerBalance', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_RecalculateSupplierLedgerBalance;
GO
CREATE PROCEDURE dbo.sp_RecalculateSupplierLedgerBalance
    @SupplierID INT
AS
BEGIN
    SET NOCOUNT ON;

    ;WITH Ordered AS
    (
        SELECT
            LedgerID,
            Debit,
            Credit,
            ROW_NUMBER() OVER (ORDER BY TransactionDate ASC, LedgerID ASC) AS rn
        FROM dbo.SupplierLedger
        WHERE SupplierID = @SupplierID
    )
    SELECT * INTO #SupplierLedgerCalc FROM Ordered;

    UPDATE t
    SET t.RunningBalance = c.NewBalance
    FROM dbo.SupplierLedger t
    INNER JOIN
    (
        SELECT
            LedgerID,
            SUM(Debit - Credit) OVER (ORDER BY rn ROWS UNBOUNDED PRECEDING) AS NewBalance
        FROM #SupplierLedgerCalc
    ) c ON c.LedgerID = t.LedgerID;

    DROP TABLE #SupplierLedgerCalc;
END
GO

-- =========================================================================
-- sp_RecalculateCashLedgerBalance
-- Recomputes RunningBalance for the entire CashLedger. The company's
-- OpeningCashBalance is booked as its own 'OpeningBalance' CashLedger
-- row when the company profile is created, so this sums strictly from
-- zero across all rows (including that opening row).
--
-- The opening-balance row is always ranked first regardless of its own
-- TransactionDate. Two ways it can end up in the table:
--   1. TransactionType = 'OpeningBalance', inserted once at company-profile
--      creation time, stamped with that day's date.
--   2. TransactionType = 'Adjustment', entered later by an admin via
--      "Adjust Balance" as the very first cash transaction the business
--      ever recorded in the system (no company OpeningCashBalance was set
--      at setup time, so this Adjustment row IS the opening balance in
--      substance, per the "very first transaction ever created" rule).
-- Either way, if the business already had backdated transactions entered
-- around the same time, a plain date sort can push this row after them,
-- making the ledger run negative until it "catches up" at the end. An
-- opening balance is conceptually the state of the account before any
-- transaction, so it must anchor the sequence first no matter when the
-- row itself was created - but only the very first row overall (lowest
-- CashLedgerID) qualifies, so an ordinary Adjustment made later doesn't
-- wrongly jump the queue.
-- =========================================================================
IF OBJECT_ID('dbo.sp_RecalculateCashLedgerBalance', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_RecalculateCashLedgerBalance;
GO
CREATE PROCEDURE dbo.sp_RecalculateCashLedgerBalance
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @FirstCashLedgerID BIGINT = (SELECT MIN(CashLedgerID) FROM dbo.CashLedger);

    ;WITH Ordered AS
    (
        SELECT
            CashLedgerID,
            CashIn,
            CashOut,
            ROW_NUMBER() OVER (
                ORDER BY
                    CASE
                        WHEN CashLedgerID = @FirstCashLedgerID AND TransactionType IN ('OpeningBalance', 'Adjustment') THEN 0
                        ELSE 1
                    END,
                    TransactionDate ASC,
                    CashLedgerID ASC
            ) AS rn
        FROM dbo.CashLedger
    )
    SELECT * INTO #CashLedgerCalc FROM Ordered;

    UPDATE t
    SET t.RunningBalance = c.NewBalance
    FROM dbo.CashLedger t
    INNER JOIN
    (
        SELECT
            CashLedgerID,
            SUM(CashIn - CashOut) OVER (ORDER BY rn ROWS UNBOUNDED PRECEDING) AS NewBalance
        FROM #CashLedgerCalc
    ) c ON c.CashLedgerID = t.CashLedgerID;

    DROP TABLE #CashLedgerCalc;
END
GO

-- =========================================================================
-- sp_RecalculateStockLedgerBalance
-- Same approach as the other ledgers: Purchase books QuantityIn, Supply
-- books QuantityOut, and this recomputes RunningStock for every row of
-- one fruit's StockLedger in date order, summing strictly from zero
-- (there is no opening-stock concept unless booked as its own
-- 'Adjustment' row, same convention as the other ledgers).
-- =========================================================================
IF OBJECT_ID('dbo.sp_RecalculateStockLedgerBalance', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_RecalculateStockLedgerBalance;
GO
CREATE PROCEDURE dbo.sp_RecalculateStockLedgerBalance
    @FruitID INT
AS
BEGIN
    SET NOCOUNT ON;

    ;WITH Ordered AS
    (
        SELECT
            StockLedgerID,
            QuantityIn,
            QuantityOut,
            ROW_NUMBER() OVER (ORDER BY TransactionDate ASC, StockLedgerID ASC) AS rn
        FROM dbo.StockLedger
        WHERE FruitID = @FruitID
    )
    SELECT * INTO #StockLedgerCalc FROM Ordered;

    UPDATE t
    SET t.RunningStock = c.NewStock
    FROM dbo.StockLedger t
    INNER JOIN
    (
        SELECT
            StockLedgerID,
            SUM(QuantityIn - QuantityOut) OVER (ORDER BY rn ROWS UNBOUNDED PRECEDING) AS NewStock
        FROM #StockLedgerCalc
    ) c ON c.StockLedgerID = t.StockLedgerID;

    DROP TABLE #StockLedgerCalc;
END
GO

-- =========================================================================
-- sp_GetDashboardSummary
-- Single round-trip aggregate for the dashboard cards.
-- =========================================================================
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
        @TodayCollection        AS TodayCollection,
        @TodaySales              AS TodaySales,
        @TodayPurchases          AS TodayPurchases,
        @TodayExpenses            AS TodayExpenses,
        @CustomerOutstanding      AS CustomerOutstanding,
        @SupplierOutstanding      AS SupplierOutstanding,
        (@CurrentCashBalance + @CustomerOutstanding - @SupplierOutstanding) AS NetBusinessWorth;
END
GO

PRINT 'Stored procedures created successfully.';
GO
