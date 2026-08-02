/* =====================================================================
   Fruit Wholesale Management System
   16_FixCashLedgerOpeningBalanceOrder.sql

   Bug: sp_RecalculateCashLedgerBalance ordered strictly by
   (TransactionDate ASC, CashLedgerID ASC). The row representing the
   opening balance — either TransactionType = 'OpeningBalance' (set at
   company-profile creation) or the very first CashLedger row ever
   inserted if it's a manual 'Adjustment' entered later via "Adjust
   Balance" — can be stamped with a date/time that sorts after other
   already-entered (backdated) transactions. The running balance then
   summed those earlier transactions from zero (going negative) before
   finally "catching up" once the opening row was reached, instead of
   starting from the opening balance as accounting standards require.

   Fix: re-create the procedure so that row is always ranked first,
   regardless of its own TransactionDate (matches 03_StoredProcedures.sql
   — kept in sync there for fresh installs). Then run it once here to
   correct any RunningBalance values already written to the table under
   the old, incorrect ordering.

   Idempotent — safe to re-run against a live database.
   ===================================================================== */
USE FruitWholesaleDB;
GO

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

PRINT 'sp_RecalculateCashLedgerBalance updated. Recalculating existing CashLedger rows...';
GO

EXEC dbo.sp_RecalculateCashLedgerBalance;
GO

PRINT 'CashLedger RunningBalance values corrected.';
GO
