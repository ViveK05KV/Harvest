/* =====================================================================
   Fruit Wholesale Management System
   03_StoredProcedures.sql

   PL/pgSQL functions are used only where they provide a real benefit:
     - Recalculating running balances after a backdated edit/delete
       (a set-based operation that is far cheaper done in the database
       than round-tripping every row to the application).
     - The dashboard summary, which aggregates many tables in one
       round trip.
   All other CRUD operations are handled in the Infrastructure layer via
   Dapper so business logic stays in one place (C#) and is unit-testable.
   ===================================================================== */

-- =========================================================================
-- sp_recalculate_shop_ledger_balance
-- Recomputes RunningBalance for every ShopLedger row of a shop, in date
-- order. The shop's OpeningBalance is booked as its own 'OpeningBalance'
-- ledger row at shop-creation time, so this sums strictly from zero —
-- it must NOT re-add ShopMaster.OpeningBalance, or the opening balance
-- would be double counted. Call after any insert, update or delete that
-- touches a shop's ledger with a backdated entry.
--
-- The opening-balance row is always ranked first regardless of its own
-- TransactionDate, same rule and rationale as sp_recalculate_cash_ledger_balance:
-- it can be an 'OpeningBalance' row (shop creation) or an 'Adjustment' row
-- (first-ever "Adjust Balance" entry for a shop that had no opening
-- balance set), and either way only the very first row for that shop
-- (lowest LedgerID) qualifies, so a later Adjustment doesn't wrongly
-- jump the queue.
-- =========================================================================
CREATE OR REPLACE FUNCTION sp_recalculate_shop_ledger_balance(p_shopid INT) RETURNS void AS $$
DECLARE
    v_first_ledger_id BIGINT;
BEGIN
    SELECT MIN(LedgerID) INTO v_first_ledger_id FROM ShopLedger WHERE ShopID = p_shopid;

    UPDATE ShopLedger t
    SET RunningBalance = c.NewBalance
    FROM (
        SELECT LedgerID,
               SUM(Debit - Credit) OVER (ORDER BY rn ROWS UNBOUNDED PRECEDING) AS NewBalance
        FROM (
            SELECT LedgerID, Debit, Credit,
                   ROW_NUMBER() OVER (
                       ORDER BY
                           CASE
                               WHEN LedgerID = v_first_ledger_id AND TransactionType IN ('OpeningBalance', 'Adjustment') THEN 0
                               ELSE 1
                           END,
                           TransactionDate ASC,
                           LedgerID ASC
                   ) AS rn
            FROM ShopLedger
            WHERE ShopID = p_shopid
        ) Ordered
    ) c
    WHERE c.LedgerID = t.LedgerID;
END;
$$ LANGUAGE plpgsql;

-- =========================================================================
-- sp_recalculate_supplier_ledger_balance
-- Same approach as sp_recalculate_shop_ledger_balance: the supplier's
-- OpeningBalance is booked as its own ledger row at supplier-creation
-- time, so this sums strictly from zero, and the first-ever row for that
-- supplier is always ranked first regardless of its own TransactionDate.
-- =========================================================================
CREATE OR REPLACE FUNCTION sp_recalculate_supplier_ledger_balance(p_supplierid INT) RETURNS void AS $$
DECLARE
    v_first_ledger_id BIGINT;
BEGIN
    SELECT MIN(LedgerID) INTO v_first_ledger_id FROM SupplierLedger WHERE SupplierID = p_supplierid;

    UPDATE SupplierLedger t
    SET RunningBalance = c.NewBalance
    FROM (
        SELECT LedgerID,
               SUM(Debit - Credit) OVER (ORDER BY rn ROWS UNBOUNDED PRECEDING) AS NewBalance
        FROM (
            SELECT LedgerID, Debit, Credit,
                   ROW_NUMBER() OVER (
                       ORDER BY
                           CASE
                               WHEN LedgerID = v_first_ledger_id AND TransactionType IN ('OpeningBalance', 'Adjustment') THEN 0
                               ELSE 1
                           END,
                           TransactionDate ASC,
                           LedgerID ASC
                   ) AS rn
            FROM SupplierLedger
            WHERE SupplierID = p_supplierid
        ) Ordered
    ) c
    WHERE c.LedgerID = t.LedgerID;
END;
$$ LANGUAGE plpgsql;

-- =========================================================================
-- sp_recalculate_cash_ledger_balance
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
CREATE OR REPLACE FUNCTION sp_recalculate_cash_ledger_balance() RETURNS void AS $$
DECLARE
    v_first_cash_ledger_id BIGINT;
BEGIN
    SELECT MIN(CashLedgerID) INTO v_first_cash_ledger_id FROM CashLedger;

    UPDATE CashLedger t
    SET RunningBalance = c.NewBalance
    FROM (
        SELECT CashLedgerID,
               SUM(CashIn - CashOut) OVER (ORDER BY rn ROWS UNBOUNDED PRECEDING) AS NewBalance
        FROM (
            SELECT CashLedgerID, CashIn, CashOut,
                   ROW_NUMBER() OVER (
                       ORDER BY
                           CASE
                               WHEN CashLedgerID = v_first_cash_ledger_id AND TransactionType IN ('OpeningBalance', 'Adjustment') THEN 0
                               ELSE 1
                           END,
                           TransactionDate ASC,
                           CashLedgerID ASC
                   ) AS rn
            FROM CashLedger
        ) Ordered
    ) c
    WHERE c.CashLedgerID = t.CashLedgerID;
END;
$$ LANGUAGE plpgsql;

-- =========================================================================
-- sp_recalculate_stock_ledger_balance
-- Same approach as the other ledgers: Purchase books QuantityIn, Supply
-- books QuantityOut, and this recomputes RunningStock for every row of
-- one fruit's StockLedger in date order, summing strictly from zero
-- (there is no opening-stock concept unless booked as its own
-- 'Adjustment' row, same convention as the other ledgers) - and if that
-- Adjustment happens to be the very first stock row for the fruit, it's
-- ranked first regardless of its own TransactionDate, same rule as the
-- other ledgers.
-- =========================================================================
CREATE OR REPLACE FUNCTION sp_recalculate_stock_ledger_balance(p_fruitid INT) RETURNS void AS $$
DECLARE
    v_first_stock_ledger_id BIGINT;
BEGIN
    SELECT MIN(StockLedgerID) INTO v_first_stock_ledger_id FROM StockLedger WHERE FruitID = p_fruitid;

    UPDATE StockLedger t
    SET RunningStock = c.NewStock
    FROM (
        SELECT StockLedgerID,
               SUM(QuantityIn - QuantityOut) OVER (ORDER BY rn ROWS UNBOUNDED PRECEDING) AS NewStock
        FROM (
            SELECT StockLedgerID, QuantityIn, QuantityOut,
                   ROW_NUMBER() OVER (
                       ORDER BY
                           CASE
                               WHEN StockLedgerID = v_first_stock_ledger_id AND TransactionType = 'Adjustment' THEN 0
                               ELSE 1
                           END,
                           TransactionDate ASC,
                           StockLedgerID ASC
                   ) AS rn
            FROM StockLedger
            WHERE FruitID = p_fruitid
        ) Ordered
    ) c
    WHERE c.StockLedgerID = t.StockLedgerID;
END;
$$ LANGUAGE plpgsql;

-- =========================================================================
-- sp_get_dashboard_summary
-- Single round-trip aggregate for the dashboard cards.
-- =========================================================================
CREATE OR REPLACE FUNCTION sp_get_dashboard_summary(p_today DATE)
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
