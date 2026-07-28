/* =====================================================================
   Fruit Wholesale Management System
   11_ClearTransactionalData.sql

   Wipes all transactional/derived data (Supply, Purchase, Collections,
   SupplierPayments, DailyExpense, EmployeeWorkLog, ShopReturns,
   SupplierReturns, and every ledger table) while preserving Masters
   (ShopMaster, SupplierMaster, FruitMaster, RouteMaster, EmployeeMaster,
   ExpenseCategory, CompanySettings, Users). Deletes in dependency-safe
   (child-before-parent) order and resets identity seeds on the tables
   it touches. Re-run any time you want a clean slate for transaction
   data without losing your master records.
   ===================================================================== */
USE FruitWholesaleDB;
GO

DELETE FROM dbo.ShopReturnItems;
DELETE FROM dbo.ShopReturns;
DELETE FROM dbo.SupplierReturnItems;
DELETE FROM dbo.SupplierReturns;
DELETE FROM dbo.StockLedger;
DELETE FROM dbo.FruitCostBasis;
DELETE FROM dbo.CashLedger;
DELETE FROM dbo.SupplierLedger;
DELETE FROM dbo.ShopLedger;
DELETE FROM dbo.EmployeeWorkLog;
DELETE FROM dbo.DailyExpense;
DELETE FROM dbo.SupplierPayments;
DELETE FROM dbo.PurchaseItems;
DELETE FROM dbo.Purchase;
DELETE FROM dbo.Collections;
DELETE FROM dbo.SupplyItems;
DELETE FROM dbo.Supply;

DBCC CHECKIDENT ('dbo.ShopReturnItems', RESEED, 0);
DBCC CHECKIDENT ('dbo.ShopReturns', RESEED, 0);
DBCC CHECKIDENT ('dbo.SupplierReturnItems', RESEED, 0);
DBCC CHECKIDENT ('dbo.SupplierReturns', RESEED, 0);
DBCC CHECKIDENT ('dbo.StockLedger', RESEED, 0);
DBCC CHECKIDENT ('dbo.CashLedger', RESEED, 0);
DBCC CHECKIDENT ('dbo.SupplierLedger', RESEED, 0);
DBCC CHECKIDENT ('dbo.ShopLedger', RESEED, 0);
DBCC CHECKIDENT ('dbo.EmployeeWorkLog', RESEED, 0);
DBCC CHECKIDENT ('dbo.DailyExpense', RESEED, 0);
DBCC CHECKIDENT ('dbo.SupplierPayments', RESEED, 0);
DBCC CHECKIDENT ('dbo.PurchaseItems', RESEED, 0);
DBCC CHECKIDENT ('dbo.Purchase', RESEED, 0);
DBCC CHECKIDENT ('dbo.Collections', RESEED, 0);
DBCC CHECKIDENT ('dbo.SupplyItems', RESEED, 0);
DBCC CHECKIDENT ('dbo.Supply', RESEED, 0);

PRINT 'All transactional data cleared. Masters left untouched.';
GO
