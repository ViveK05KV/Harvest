/* =====================================================================
   Fruit Wholesale Management System
   21_ChangeBoxCountToDecimal.sql

   BoxCount was INT on PurchaseItems/SupplyItems/ShopReturnItems/
   SupplierReturnItems, but fruit boxes aren't always sold/bought whole
   (e.g. half a crate) - entering 1.5 threw, since the API deserializes
   the JSON number straight into the column's CLR type. Widen to
   DECIMAL(18,3) to allow fractional box counts, matching Quantity's
   precision.

   Idempotent - safe to re-run against a live database.
   ===================================================================== */
USE FruitWholesaleDB;
GO

IF EXISTS (SELECT 1 FROM sys.columns c JOIN sys.types t ON t.user_type_id = c.user_type_id
           WHERE c.object_id = OBJECT_ID('dbo.PurchaseItems') AND c.name = 'BoxCount' AND t.name = 'int')
BEGIN
    ALTER TABLE dbo.PurchaseItems ALTER COLUMN BoxCount DECIMAL(18,3) NULL;
END
GO

IF EXISTS (SELECT 1 FROM sys.columns c JOIN sys.types t ON t.user_type_id = c.user_type_id
           WHERE c.object_id = OBJECT_ID('dbo.SupplyItems') AND c.name = 'BoxCount' AND t.name = 'int')
BEGIN
    ALTER TABLE dbo.SupplyItems ALTER COLUMN BoxCount DECIMAL(18,3) NULL;
END
GO

IF EXISTS (SELECT 1 FROM sys.columns c JOIN sys.types t ON t.user_type_id = c.user_type_id
           WHERE c.object_id = OBJECT_ID('dbo.ShopReturnItems') AND c.name = 'BoxCount' AND t.name = 'int')
BEGIN
    ALTER TABLE dbo.ShopReturnItems ALTER COLUMN BoxCount DECIMAL(18,3) NULL;
END
GO

IF EXISTS (SELECT 1 FROM sys.columns c JOIN sys.types t ON t.user_type_id = c.user_type_id
           WHERE c.object_id = OBJECT_ID('dbo.SupplierReturnItems') AND c.name = 'BoxCount' AND t.name = 'int')
BEGIN
    ALTER TABLE dbo.SupplierReturnItems ALTER COLUMN BoxCount DECIMAL(18,3) NULL;
END
GO

PRINT 'BoxCount widened to decimal on all four item tables.';
GO
