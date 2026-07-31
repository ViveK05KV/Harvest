/* =====================================================================
   Fruit Wholesale Management System
   15_OptimizationIndexes.sql

   Closes index gaps found during a project-wide optimization pass:

   - ShopLedger/SupplierLedger deletes (LedgerService.DeleteLedgerEntriesAsync)
     filter by (TransactionType, ReferenceID), which the existing
     (ShopID/SupplierID, TransactionDate) indexes can't serve — every
     Supply/Collection/Purchase/SupplierPayment edit or delete was doing a
     full ledger table scan.
   - ShopMaster.LinkedSupplierID (added in 14_AddShopSupplierLink.sql) has
     no supporting index, so SupplierMasterRepository's OUTER APPLY
     reverse-lookup scans ShopMaster on every supplier list/detail call.
   - Supply/Purchase/Collections date-range trend queries (dashboard
     sales/purchases/collections trends and monthly charts) only had a
     ShopID/SupplierID-first covering index; queries with no ID filter
     had to key-lookup per row off the date-only index. Widened those to
     cover the aggregated amount column.
   - CashLedger's cash-trend query sums (CashIn - CashOut) over a date
     range; widened the date index to cover both columns.

   Idempotent — safe to re-run against a live database.
   ===================================================================== */
USE FruitWholesaleDB;
GO

DROP INDEX IF EXISTS IX_ShopLedger_TransactionType_ReferenceID ON dbo.ShopLedger;
CREATE NONCLUSTERED INDEX IX_ShopLedger_TransactionType_ReferenceID ON dbo.ShopLedger (TransactionType, ReferenceID);

DROP INDEX IF EXISTS IX_SupplierLedger_TransactionType_ReferenceID ON dbo.SupplierLedger;
CREATE NONCLUSTERED INDEX IX_SupplierLedger_TransactionType_ReferenceID ON dbo.SupplierLedger (TransactionType, ReferenceID);

DROP INDEX IF EXISTS IX_ShopMaster_LinkedSupplierID ON dbo.ShopMaster;
CREATE NONCLUSTERED INDEX IX_ShopMaster_LinkedSupplierID ON dbo.ShopMaster (LinkedSupplierID) INCLUDE (ShopName);

DROP INDEX IF EXISTS IX_Supply_SupplyDate ON dbo.Supply;
CREATE NONCLUSTERED INDEX IX_Supply_SupplyDate ON dbo.Supply (SupplyDate DESC) INCLUDE (TotalAmount);

DROP INDEX IF EXISTS IX_Purchase_PurchaseDate ON dbo.Purchase;
CREATE NONCLUSTERED INDEX IX_Purchase_PurchaseDate ON dbo.Purchase (PurchaseDate DESC) INCLUDE (TotalAmount);

DROP INDEX IF EXISTS IX_Collections_CollectionDate ON dbo.Collections;
CREATE NONCLUSTERED INDEX IX_Collections_CollectionDate ON dbo.Collections (CollectionDate DESC) INCLUDE (AmountReceived);

DROP INDEX IF EXISTS IX_CashLedger_TransactionDate ON dbo.CashLedger;
CREATE NONCLUSTERED INDEX IX_CashLedger_TransactionDate ON dbo.CashLedger (TransactionDate, CashLedgerID) INCLUDE (CashIn, CashOut);

PRINT 'Optimization indexes applied.';
GO
