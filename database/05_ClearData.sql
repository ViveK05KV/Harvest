/* =====================================================================
   Fruit Wholesale Management System
   05_ClearData.sql
   Wipes every table back to empty except the admin login in dbo.Users.
   Deletes in dependency-safe (child-before-parent) order and resets
   identity seeds. Re-run any time you want a clean slate without
   dropping/recreating the schema.
   ===================================================================== */
USE FruitWholesaleDB;
GO

DELETE FROM dbo.CashLedger;
DELETE FROM dbo.SupplierLedger;
DELETE FROM dbo.ShopLedger;
DELETE FROM dbo.StockLedger;
DELETE FROM dbo.EmployeeWorkLog;
DELETE FROM dbo.DailyExpense;
DELETE FROM dbo.SupplierPayments;
DELETE FROM dbo.PurchaseItems;
DELETE FROM dbo.Purchase;
DELETE FROM dbo.Collections;
DELETE FROM dbo.SupplyItems;
DELETE FROM dbo.Supply;
DELETE FROM dbo.ExpenseCategory;
DELETE FROM dbo.EmployeeMaster;
DELETE FROM dbo.SupplierMaster;
DELETE FROM dbo.ShopMaster;
DELETE FROM dbo.RouteMaster;
DELETE FROM dbo.FruitMaster;
DELETE FROM dbo.CompanySettings;
DELETE FROM dbo.Users WHERE Username <> 'admin';

DBCC CHECKIDENT ('dbo.CashLedger', RESEED, 0);
DBCC CHECKIDENT ('dbo.SupplierLedger', RESEED, 0);
DBCC CHECKIDENT ('dbo.ShopLedger', RESEED, 0);
DBCC CHECKIDENT ('dbo.StockLedger', RESEED, 0);
DBCC CHECKIDENT ('dbo.EmployeeWorkLog', RESEED, 0);
DBCC CHECKIDENT ('dbo.DailyExpense', RESEED, 0);
DBCC CHECKIDENT ('dbo.SupplierPayments', RESEED, 0);
DBCC CHECKIDENT ('dbo.PurchaseItems', RESEED, 0);
DBCC CHECKIDENT ('dbo.Purchase', RESEED, 0);
DBCC CHECKIDENT ('dbo.Collections', RESEED, 0);
DBCC CHECKIDENT ('dbo.SupplyItems', RESEED, 0);
DBCC CHECKIDENT ('dbo.Supply', RESEED, 0);
DBCC CHECKIDENT ('dbo.ExpenseCategory', RESEED, 0);
DBCC CHECKIDENT ('dbo.EmployeeMaster', RESEED, 0);
DBCC CHECKIDENT ('dbo.SupplierMaster', RESEED, 0);
DBCC CHECKIDENT ('dbo.ShopMaster', RESEED, 0);
DBCC CHECKIDENT ('dbo.RouteMaster', RESEED, 0);
DBCC CHECKIDENT ('dbo.FruitMaster', RESEED, 0);
DBCC CHECKIDENT ('dbo.CompanySettings', RESEED, 0);

PRINT 'All data cleared. Only the admin login remains.';
GO
