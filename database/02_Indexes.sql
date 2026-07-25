/* =====================================================================
   Fruit Wholesale Management System
   02_Indexes.sql
   Non-clustered indexes to support common lookup, filter and reporting
   query patterns. Idempotent: safe to re-run against an existing schema.
   ===================================================================== */
USE FruitWholesaleDB;
GO

-- Supply
DROP INDEX IF EXISTS IX_Supply_ShopID_SupplyDate ON dbo.Supply;
CREATE NONCLUSTERED INDEX IX_Supply_ShopID_SupplyDate ON dbo.Supply (ShopID, SupplyDate DESC) INCLUDE (TotalAmount);
DROP INDEX IF EXISTS IX_Supply_SupplyDate ON dbo.Supply;
CREATE NONCLUSTERED INDEX IX_Supply_SupplyDate ON dbo.Supply (SupplyDate DESC);
DROP INDEX IF EXISTS IX_SupplyItems_SupplyID ON dbo.SupplyItems;
CREATE NONCLUSTERED INDEX IX_SupplyItems_SupplyID ON dbo.SupplyItems (SupplyID);
DROP INDEX IF EXISTS IX_SupplyItems_FruitID ON dbo.SupplyItems;
CREATE NONCLUSTERED INDEX IX_SupplyItems_FruitID ON dbo.SupplyItems (FruitID);

-- Purchase
DROP INDEX IF EXISTS IX_Purchase_SupplierID_PurchaseDate ON dbo.Purchase;
CREATE NONCLUSTERED INDEX IX_Purchase_SupplierID_PurchaseDate ON dbo.Purchase (SupplierID, PurchaseDate DESC) INCLUDE (TotalAmount);
DROP INDEX IF EXISTS IX_Purchase_PurchaseDate ON dbo.Purchase;
CREATE NONCLUSTERED INDEX IX_Purchase_PurchaseDate ON dbo.Purchase (PurchaseDate DESC);
DROP INDEX IF EXISTS IX_PurchaseItems_PurchaseID ON dbo.PurchaseItems;
CREATE NONCLUSTERED INDEX IX_PurchaseItems_PurchaseID ON dbo.PurchaseItems (PurchaseID);
DROP INDEX IF EXISTS IX_PurchaseItems_FruitID ON dbo.PurchaseItems;
CREATE NONCLUSTERED INDEX IX_PurchaseItems_FruitID ON dbo.PurchaseItems (FruitID);

-- Collections
DROP INDEX IF EXISTS IX_Collections_ShopID_CollectionDate ON dbo.Collections;
CREATE NONCLUSTERED INDEX IX_Collections_ShopID_CollectionDate ON dbo.Collections (ShopID, CollectionDate DESC);
DROP INDEX IF EXISTS IX_Collections_CollectionDate ON dbo.Collections;
CREATE NONCLUSTERED INDEX IX_Collections_CollectionDate ON dbo.Collections (CollectionDate DESC);

-- SupplierPayments
DROP INDEX IF EXISTS IX_SupplierPayments_SupplierID_PaymentDate ON dbo.SupplierPayments;
CREATE NONCLUSTERED INDEX IX_SupplierPayments_SupplierID_PaymentDate ON dbo.SupplierPayments (SupplierID, PaymentDate DESC);
DROP INDEX IF EXISTS IX_SupplierPayments_PaymentDate ON dbo.SupplierPayments;
CREATE NONCLUSTERED INDEX IX_SupplierPayments_PaymentDate ON dbo.SupplierPayments (PaymentDate DESC);

-- DailyExpense
DROP INDEX IF EXISTS IX_DailyExpense_ExpenseDate ON dbo.DailyExpense;
CREATE NONCLUSTERED INDEX IX_DailyExpense_ExpenseDate ON dbo.DailyExpense (ExpenseDate DESC);
DROP INDEX IF EXISTS IX_DailyExpense_ExpenseCategoryID ON dbo.DailyExpense;
CREATE NONCLUSTERED INDEX IX_DailyExpense_ExpenseCategoryID ON dbo.DailyExpense (ExpenseCategoryID);

-- Ledgers (most critical for running-balance queries and reports)
DROP INDEX IF EXISTS IX_ShopLedger_ShopID_TransactionDate ON dbo.ShopLedger;
CREATE NONCLUSTERED INDEX IX_ShopLedger_ShopID_TransactionDate ON dbo.ShopLedger (ShopID, TransactionDate, LedgerID);
DROP INDEX IF EXISTS IX_SupplierLedger_SupplierID_TransactionDate ON dbo.SupplierLedger;
CREATE NONCLUSTERED INDEX IX_SupplierLedger_SupplierID_TransactionDate ON dbo.SupplierLedger (SupplierID, TransactionDate, LedgerID);
DROP INDEX IF EXISTS IX_CashLedger_TransactionDate ON dbo.CashLedger;
CREATE NONCLUSTERED INDEX IX_CashLedger_TransactionDate ON dbo.CashLedger (TransactionDate, CashLedgerID);
DROP INDEX IF EXISTS IX_CashLedger_ReferenceTable_ReferenceID ON dbo.CashLedger;
CREATE NONCLUSTERED INDEX IX_CashLedger_ReferenceTable_ReferenceID ON dbo.CashLedger (ReferenceTable, ReferenceID);

-- Masters (search / active filters)
DROP INDEX IF EXISTS IX_ShopMaster_ShopName ON dbo.ShopMaster;
CREATE NONCLUSTERED INDEX IX_ShopMaster_ShopName ON dbo.ShopMaster (ShopName) INCLUDE (IsActive);
DROP INDEX IF EXISTS IX_ShopMaster_RouteID ON dbo.ShopMaster;
CREATE NONCLUSTERED INDEX IX_ShopMaster_RouteID ON dbo.ShopMaster (RouteID);
DROP INDEX IF EXISTS IX_SupplierMaster_SupplierName ON dbo.SupplierMaster;
CREATE NONCLUSTERED INDEX IX_SupplierMaster_SupplierName ON dbo.SupplierMaster (SupplierName) INCLUDE (IsActive);
DROP INDEX IF EXISTS IX_FruitMaster_FruitName ON dbo.FruitMaster;
CREATE NONCLUSTERED INDEX IX_FruitMaster_FruitName ON dbo.FruitMaster (FruitName) INCLUDE (IsActive);

-- Employees & Routes
DROP INDEX IF EXISTS IX_EmployeeMaster_FullName ON dbo.EmployeeMaster;
CREATE NONCLUSTERED INDEX IX_EmployeeMaster_FullName ON dbo.EmployeeMaster (FullName) INCLUDE (IsActive);
DROP INDEX IF EXISTS IX_RouteMaster_RouteName ON dbo.RouteMaster;
CREATE NONCLUSTERED INDEX IX_RouteMaster_RouteName ON dbo.RouteMaster (RouteName) INCLUDE (IsActive);

-- EmployeeWorkLog
DROP INDEX IF EXISTS IX_EmployeeWorkLog_EmployeeID_WorkDate ON dbo.EmployeeWorkLog;
CREATE NONCLUSTERED INDEX IX_EmployeeWorkLog_EmployeeID_WorkDate ON dbo.EmployeeWorkLog (EmployeeID, WorkDate DESC);
DROP INDEX IF EXISTS IX_EmployeeWorkLog_WorkDate ON dbo.EmployeeWorkLog;
CREATE NONCLUSTERED INDEX IX_EmployeeWorkLog_WorkDate ON dbo.EmployeeWorkLog (WorkDate DESC);
DROP INDEX IF EXISTS IX_EmployeeWorkLog_RouteID ON dbo.EmployeeWorkLog;
CREATE NONCLUSTERED INDEX IX_EmployeeWorkLog_RouteID ON dbo.EmployeeWorkLog (RouteID);

-- StockLedger
DROP INDEX IF EXISTS IX_StockLedger_FruitID_TransactionDate ON dbo.StockLedger;
CREATE NONCLUSTERED INDEX IX_StockLedger_FruitID_TransactionDate ON dbo.StockLedger (FruitID, TransactionDate, StockLedgerID);
DROP INDEX IF EXISTS IX_StockLedger_ReferenceTable_ReferenceID ON dbo.StockLedger;
CREATE NONCLUSTERED INDEX IX_StockLedger_ReferenceTable_ReferenceID ON dbo.StockLedger (ReferenceTable, ReferenceID);

PRINT 'Indexes created successfully.';
GO
