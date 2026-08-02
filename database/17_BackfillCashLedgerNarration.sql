/* =====================================================================
   Fruit Wholesale Management System
   17_BackfillCashLedgerNarration.sql

   DailyExpenseRepository/CollectionRepository/SupplierPaymentRepository
   used to write generic Cash Ledger narration ("Expense: <PaidTo>" with
   PaidTo often blank, "Collection from shop (ID 5)", "Payment to
   supplier (ID 4)") instead of the actual category/shop/supplier name.
   The application code is now fixed for new/edited entries; this
   backfills the narration already stored on existing CashLedger rows so
   the ledger reads correctly without requiring every old entry to be
   manually re-saved.

   Idempotent — safe to re-run against a live database.
   ===================================================================== */
USE FruitWholesaleDB;
GO

UPDATE cl
SET cl.Narration = c.CategoryName + CASE WHEN NULLIF(LTRIM(RTRIM(de.PaidTo)), '') IS NULL THEN '' ELSE ' - ' + de.PaidTo END
FROM dbo.CashLedger cl
INNER JOIN dbo.DailyExpense de ON de.ExpenseID = cl.ReferenceID
INNER JOIN dbo.ExpenseCategory c ON c.ExpenseCategoryID = de.ExpenseCategoryID
WHERE cl.TransactionType = 'DailyExpense' AND cl.ReferenceTable = 'DailyExpense';
GO

UPDATE cl
SET cl.Narration = 'Payment to ' + s.SupplierName
FROM dbo.CashLedger cl
INNER JOIN dbo.SupplierMaster s ON s.SupplierID = cl.ReferenceID
WHERE cl.TransactionType = 'SupplierPayment' AND cl.ReferenceTable = 'SupplierPayments';
GO

UPDATE cl
SET cl.Narration = 'Collection from ' + sh.ShopName
FROM dbo.CashLedger cl
INNER JOIN dbo.ShopMaster sh ON sh.ShopID = cl.ReferenceID
WHERE cl.TransactionType = 'Collection' AND cl.ReferenceTable = 'Collections';
GO

PRINT 'CashLedger narration backfilled for existing DailyExpense/SupplierPayment/Collection rows.';
GO
