/* =====================================================================
   Fruit Wholesale Management System
   24_FixShopSupplierStockLedgerOpeningOrder.sql

   Bug: sp_RecalculateShopLedgerBalance, sp_RecalculateSupplierLedgerBalance
   and sp_RecalculateStockLedgerBalance ordered strictly by
   (TransactionDate ASC, LedgerID/StockLedgerID ASC). The row representing
   the opening balance for a shop/supplier (TransactionType =
   'OpeningBalance', booked at creation time, or a same-day 'Adjustment' if
   no opening balance was set) - or a fruit's first stock 'Adjustment' row -
   can be stamped with a date that sorts after other, backdated entries
   for that same shop/supplier/fruit. The running balance then summed
   those earlier rows from zero before "catching up" once the opening row
   was reached, instead of starting from the opening balance as accounting
   standards require. Exact same bug class as
   16_FixCashLedgerOpeningBalanceOrder.sql, which fixed CashLedger but
   never touched these three.

   Fix: re-create the three procedures so the first-ever row for a given
   shop/supplier/fruit is always ranked first, regardless of its own
   TransactionDate (matches 03_StoredProcedures.sql - kept in sync there
   for fresh installs). Then run each one once per shop/supplier/fruit
   here to correct any RunningBalance/RunningStock values already written
   under the old, incorrect ordering.

   Idempotent - safe to re-run against a live database.
   ===================================================================== */
USE FruitWholesaleDB;
GO

IF OBJECT_ID('dbo.sp_RecalculateShopLedgerBalance', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_RecalculateShopLedgerBalance;
GO
CREATE PROCEDURE dbo.sp_RecalculateShopLedgerBalance
    @ShopID INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @FirstLedgerID BIGINT = (SELECT MIN(LedgerID) FROM dbo.ShopLedger WHERE ShopID = @ShopID);

    ;WITH Ordered AS
    (
        SELECT
            LedgerID,
            Debit,
            Credit,
            ROW_NUMBER() OVER (
                ORDER BY
                    CASE
                        WHEN LedgerID = @FirstLedgerID AND TransactionType IN ('OpeningBalance', 'Adjustment') THEN 0
                        ELSE 1
                    END,
                    TransactionDate ASC,
                    LedgerID ASC
            ) AS rn
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

IF OBJECT_ID('dbo.sp_RecalculateSupplierLedgerBalance', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_RecalculateSupplierLedgerBalance;
GO
CREATE PROCEDURE dbo.sp_RecalculateSupplierLedgerBalance
    @SupplierID INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @FirstLedgerID BIGINT = (SELECT MIN(LedgerID) FROM dbo.SupplierLedger WHERE SupplierID = @SupplierID);

    ;WITH Ordered AS
    (
        SELECT
            LedgerID,
            Debit,
            Credit,
            ROW_NUMBER() OVER (
                ORDER BY
                    CASE
                        WHEN LedgerID = @FirstLedgerID AND TransactionType IN ('OpeningBalance', 'Adjustment') THEN 0
                        ELSE 1
                    END,
                    TransactionDate ASC,
                    LedgerID ASC
            ) AS rn
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

IF OBJECT_ID('dbo.sp_RecalculateStockLedgerBalance', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_RecalculateStockLedgerBalance;
GO
CREATE PROCEDURE dbo.sp_RecalculateStockLedgerBalance
    @FruitID INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @FirstStockLedgerID BIGINT = (SELECT MIN(StockLedgerID) FROM dbo.StockLedger WHERE FruitID = @FruitID);

    ;WITH Ordered AS
    (
        SELECT
            StockLedgerID,
            QuantityIn,
            QuantityOut,
            ROW_NUMBER() OVER (
                ORDER BY
                    CASE
                        WHEN StockLedgerID = @FirstStockLedgerID AND TransactionType = 'Adjustment' THEN 0
                        ELSE 1
                    END,
                    TransactionDate ASC,
                    StockLedgerID ASC
            ) AS rn
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

PRINT 'Ledger recalculation procedures updated. Correcting existing balances...';
GO

DECLARE @ShopID INT;
DECLARE shop_cursor CURSOR LOCAL FAST_FORWARD FOR SELECT DISTINCT ShopID FROM dbo.ShopLedger;
OPEN shop_cursor;
FETCH NEXT FROM shop_cursor INTO @ShopID;
WHILE @@FETCH_STATUS = 0
BEGIN
    EXEC dbo.sp_RecalculateShopLedgerBalance @ShopID = @ShopID;
    FETCH NEXT FROM shop_cursor INTO @ShopID;
END
CLOSE shop_cursor;
DEALLOCATE shop_cursor;

DECLARE @SupplierID INT;
DECLARE supplier_cursor CURSOR LOCAL FAST_FORWARD FOR SELECT DISTINCT SupplierID FROM dbo.SupplierLedger;
OPEN supplier_cursor;
FETCH NEXT FROM supplier_cursor INTO @SupplierID;
WHILE @@FETCH_STATUS = 0
BEGIN
    EXEC dbo.sp_RecalculateSupplierLedgerBalance @SupplierID = @SupplierID;
    FETCH NEXT FROM supplier_cursor INTO @SupplierID;
END
CLOSE supplier_cursor;
DEALLOCATE supplier_cursor;

DECLARE @FruitID INT;
DECLARE fruit_cursor CURSOR LOCAL FAST_FORWARD FOR SELECT DISTINCT FruitID FROM dbo.StockLedger;
OPEN fruit_cursor;
FETCH NEXT FROM fruit_cursor INTO @FruitID;
WHILE @@FETCH_STATUS = 0
BEGIN
    EXEC dbo.sp_RecalculateStockLedgerBalance @FruitID = @FruitID;
    FETCH NEXT FROM fruit_cursor INTO @FruitID;
END
CLOSE fruit_cursor;
DEALLOCATE fruit_cursor;

PRINT 'Shop, Supplier and Stock ledger RunningBalance/RunningStock values corrected.';
GO
