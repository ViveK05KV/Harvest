/* =====================================================================
   Fruit Wholesale Management System
   05_ClearData.sql
   Wipes every table back to empty except the admin login in Users.
   Deletes in dependency-safe (child-before-parent) order and resets
   identity sequences. Re-run any time you want a clean slate without
   dropping/recreating the schema.
   ===================================================================== */

DELETE FROM CashLedger;
DELETE FROM SupplierLedger;
DELETE FROM ShopLedger;
DELETE FROM FruitBoxes;
DELETE FROM StockLedger;
DELETE FROM FruitCostBasis;
DELETE FROM ShopReturnItems;
DELETE FROM ShopReturns;
DELETE FROM SupplierReturnItems;
DELETE FROM SupplierReturns;
DELETE FROM EmployeeWorkLog;
DELETE FROM DailyExpense;
DELETE FROM SupplierPayments;
DELETE FROM PurchaseItems;
DELETE FROM Purchase;
DELETE FROM Collections;
DELETE FROM TemporaryCollectionSettlements;
DELETE FROM SupplyItems;
DELETE FROM Supply;
DELETE FROM ExpenseCategory;
DELETE FROM EmployeeMaster;
DELETE FROM SupplierMaster;
DELETE FROM ShopMaster;
DELETE FROM RouteMaster;
DELETE FROM FruitMaster;
DELETE FROM CompanySettings;
DELETE FROM RefreshTokens;
DELETE FROM Users WHERE Username <> 'admin';

-- Looked up via pg_get_serial_sequence() rather than hardcoded "table_column_seq" names:
-- Postgres silently truncates auto-generated identity sequence names over 63 bytes
-- (e.g. TemporaryCollectionSettlements + its PK column overflows that limit), so a
-- literal ALTER SEQUENCE name can silently point at a sequence that doesn't exist.
DO $$
DECLARE
    t text;
BEGIN
    FOREACH t IN ARRAY ARRAY[
        'CashLedger', 'SupplierLedger', 'ShopLedger', 'FruitBoxes', 'StockLedger',
        'ShopReturnItems', 'ShopReturns', 'SupplierReturnItems', 'SupplierReturns',
        'EmployeeWorkLog', 'DailyExpense', 'SupplierPayments', 'PurchaseItems', 'Purchase',
        'Collections', 'TemporaryCollectionSettlements', 'SupplyItems', 'Supply',
        'ExpenseCategory', 'EmployeeMaster', 'SupplierMaster', 'ShopMaster', 'RouteMaster',
        'FruitMaster', 'CompanySettings', 'RefreshTokens'
    ]
    LOOP
        EXECUTE format(
            'SELECT setval(pg_get_serial_sequence(%L, column_name), 1, false) FROM information_schema.columns WHERE table_name = %L AND column_default LIKE %L',
            lower(t), lower(t), 'nextval%'
        );
    END LOOP;
END
$$;
