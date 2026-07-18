/* =====================================================================
   Fruit Wholesale Management System
   06_AddDiscountColumns.sql
   Adds DiscountAmount to Collections and SupplierPayments for existing
   databases created before this column was added to
   01_CreateDatabase_Tables.sql. Safe to re-run. Does not touch any
   existing data — a fresh install via 01_CreateDatabase_Tables.sql
   already includes these columns and does not need this script.
   ===================================================================== */
USE FruitWholesaleDB;
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.Collections') AND name = 'DiscountAmount')
BEGIN
    ALTER TABLE dbo.Collections ADD DiscountAmount DECIMAL(18,2) NOT NULL CONSTRAINT DF_Collections_DiscountAmount DEFAULT (0);
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.SupplierPayments') AND name = 'DiscountAmount')
BEGIN
    ALTER TABLE dbo.SupplierPayments ADD DiscountAmount DECIMAL(18,2) NOT NULL CONSTRAINT DF_SupplierPayments_DiscountAmount DEFAULT (0);
END
GO

PRINT 'Discount columns added successfully.';
GO
