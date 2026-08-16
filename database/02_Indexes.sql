/* =====================================================================
   Fruit Wholesale Management System
   02_Indexes.sql
   Indexes to support common lookup, filter and reporting query
   patterns. Idempotent: safe to re-run against an existing schema.
   ===================================================================== */

-- Supply
DROP INDEX IF EXISTS IX_Supply_ShopID_SupplyDate;
CREATE INDEX IX_Supply_ShopID_SupplyDate ON Supply (ShopID, SupplyDate DESC) INCLUDE (TotalAmount);
DROP INDEX IF EXISTS IX_Supply_SupplyDate;
CREATE INDEX IX_Supply_SupplyDate ON Supply (SupplyDate DESC) INCLUDE (TotalAmount);
DROP INDEX IF EXISTS IX_SupplyItems_SupplyID;
CREATE INDEX IX_SupplyItems_SupplyID ON SupplyItems (SupplyID) INCLUDE (FruitID, Quantity, TotalAmount, CostBasis);
DROP INDEX IF EXISTS IX_SupplyItems_FruitID;
CREATE INDEX IX_SupplyItems_FruitID ON SupplyItems (FruitID) INCLUDE (Quantity, SupplyID);

-- Purchase
DROP INDEX IF EXISTS IX_Purchase_SupplierID_PurchaseDate;
CREATE INDEX IX_Purchase_SupplierID_PurchaseDate ON Purchase (SupplierID, PurchaseDate DESC) INCLUDE (TotalAmount);
DROP INDEX IF EXISTS IX_Purchase_PurchaseDate;
CREATE INDEX IX_Purchase_PurchaseDate ON Purchase (PurchaseDate DESC) INCLUDE (TotalAmount);
DROP INDEX IF EXISTS IX_PurchaseItems_PurchaseID;
CREATE INDEX IX_PurchaseItems_PurchaseID ON PurchaseItems (PurchaseID);
DROP INDEX IF EXISTS IX_PurchaseItems_FruitID;
CREATE INDEX IX_PurchaseItems_FruitID ON PurchaseItems (FruitID) INCLUDE (Quantity, PurchasePrice, PurchaseID);

-- Collections
DROP INDEX IF EXISTS IX_Collections_ShopID_CollectionDate;
CREATE INDEX IX_Collections_ShopID_CollectionDate ON Collections (ShopID, CollectionDate DESC);
DROP INDEX IF EXISTS IX_Collections_CollectionDate;
CREATE INDEX IX_Collections_CollectionDate ON Collections (CollectionDate DESC) INCLUDE (AmountReceived);

-- SupplierPayments
DROP INDEX IF EXISTS IX_SupplierPayments_SupplierID_PaymentDate;
CREATE INDEX IX_SupplierPayments_SupplierID_PaymentDate ON SupplierPayments (SupplierID, PaymentDate DESC);
DROP INDEX IF EXISTS IX_SupplierPayments_PaymentDate;
CREATE INDEX IX_SupplierPayments_PaymentDate ON SupplierPayments (PaymentDate DESC);

-- DailyExpense
DROP INDEX IF EXISTS IX_DailyExpense_ExpenseDate;
CREATE INDEX IX_DailyExpense_ExpenseDate ON DailyExpense (ExpenseDate DESC);
DROP INDEX IF EXISTS IX_DailyExpense_ExpenseCategoryID;
CREATE INDEX IX_DailyExpense_ExpenseCategoryID ON DailyExpense (ExpenseCategoryID);

-- Ledgers (most critical for running-balance queries and reports)
DROP INDEX IF EXISTS IX_ShopLedger_ShopID_TransactionDate;
CREATE INDEX IX_ShopLedger_ShopID_TransactionDate ON ShopLedger (ShopID, TransactionDate, LedgerID);
DROP INDEX IF EXISTS IX_SupplierLedger_SupplierID_TransactionDate;
CREATE INDEX IX_SupplierLedger_SupplierID_TransactionDate ON SupplierLedger (SupplierID, TransactionDate, LedgerID);
DROP INDEX IF EXISTS IX_CashLedger_TransactionDate;
CREATE INDEX IX_CashLedger_TransactionDate ON CashLedger (TransactionDate, CashLedgerID);
DROP INDEX IF EXISTS IX_CashLedger_ReferenceTable_ReferenceID;
CREATE INDEX IX_CashLedger_ReferenceTable_ReferenceID ON CashLedger (ReferenceTable, ReferenceID);

-- Masters (search / active filters)
DROP INDEX IF EXISTS IX_ShopMaster_ShopName;
CREATE INDEX IX_ShopMaster_ShopName ON ShopMaster (ShopName) INCLUDE (IsActive);
DROP INDEX IF EXISTS IX_ShopMaster_RouteID;
CREATE INDEX IX_ShopMaster_RouteID ON ShopMaster (RouteID);
DROP INDEX IF EXISTS IX_SupplierMaster_SupplierName;
CREATE INDEX IX_SupplierMaster_SupplierName ON SupplierMaster (SupplierName) INCLUDE (IsActive);
-- IX_FruitMaster_FruitName removed: redundant with UQ_FruitMaster_FruitName, which already
-- indexes FruitName (see 01_CreateDatabase_Tables.sql). Keeping both duplicated write cost
-- for no read benefit on a small master table.
DROP INDEX IF EXISTS IX_FruitMaster_FruitName;

-- Employees & Routes
DROP INDEX IF EXISTS IX_EmployeeMaster_FullName;
CREATE INDEX IX_EmployeeMaster_FullName ON EmployeeMaster (FullName) INCLUDE (IsActive);
-- IX_RouteMaster_RouteName removed: redundant with UQ_RouteMaster_RouteName (same reasoning
-- as IX_FruitMaster_FruitName above).
DROP INDEX IF EXISTS IX_RouteMaster_RouteName;

-- EmployeeWorkLog
DROP INDEX IF EXISTS IX_EmployeeWorkLog_EmployeeID_WorkDate;
CREATE INDEX IX_EmployeeWorkLog_EmployeeID_WorkDate ON EmployeeWorkLog (EmployeeID, WorkDate DESC);
DROP INDEX IF EXISTS IX_EmployeeWorkLog_WorkDate;
CREATE INDEX IX_EmployeeWorkLog_WorkDate ON EmployeeWorkLog (WorkDate DESC);
DROP INDEX IF EXISTS IX_EmployeeWorkLog_RouteID;
CREATE INDEX IX_EmployeeWorkLog_RouteID ON EmployeeWorkLog (RouteID);

-- StockLedger
DROP INDEX IF EXISTS IX_StockLedger_FruitID_TransactionDate;
CREATE INDEX IX_StockLedger_FruitID_TransactionDate ON StockLedger (FruitID, TransactionDate, StockLedgerID);
DROP INDEX IF EXISTS IX_StockLedger_ReferenceTable_ReferenceID;
CREATE INDEX IX_StockLedger_ReferenceTable_ReferenceID ON StockLedger (ReferenceTable, ReferenceID);

-- ShopReturns / SupplierReturns
DROP INDEX IF EXISTS IX_ShopReturns_ShopID_ReturnDate;
CREATE INDEX IX_ShopReturns_ShopID_ReturnDate ON ShopReturns (ShopID, ReturnDate DESC) INCLUDE (TotalAmount);
DROP INDEX IF EXISTS IX_ShopReturnItems_FruitID;
CREATE INDEX IX_ShopReturnItems_FruitID ON ShopReturnItems (FruitID) INCLUDE (Quantity, CostBasis, ShopReturnID);
DROP INDEX IF EXISTS IX_SupplierReturns_SupplierID_ReturnDate;
CREATE INDEX IX_SupplierReturns_SupplierID_ReturnDate ON SupplierReturns (SupplierID, ReturnDate DESC) INCLUDE (TotalAmount);
DROP INDEX IF EXISTS IX_SupplierReturnItems_FruitID;
CREATE INDEX IX_SupplierReturnItems_FruitID ON SupplierReturnItems (FruitID) INCLUDE (Quantity, SupplierReturnID);
