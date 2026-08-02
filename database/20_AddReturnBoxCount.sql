/* =====================================================================
   Fruit Wholesale Management System
   20_AddReturnBoxCount.sql

   Box-count support on Shop Returns and Supplier Returns, mirroring
   PurchaseItems.BoxCount / SupplyItems.BoxCount. Same nominal-weight
   pricing model: BoxCount is display/pricing input only, Quantity (kg)
   stays the number of record for stock math.

   ShopReturnItems.BoxCount - a shop return adds stock back, so it is
   treated like a Purchase (box-in) event in RecalculateFruitBoxesAsync.

   SupplierReturnItems.BoxCount - a supplier return removes stock, so
   it is treated like a Supply (kg-out FIFO drain) event; BoxCount there
   only drives the "price per box" amount calc, not the drain itself.

   Idempotent - safe to re-run against a live database.
   ===================================================================== */
USE FruitWholesaleDB;
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.ShopReturnItems') AND name = 'BoxCount')
BEGIN
    ALTER TABLE dbo.ShopReturnItems ADD BoxCount INT NULL;
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.SupplierReturnItems') AND name = 'BoxCount')
BEGIN
    ALTER TABLE dbo.SupplierReturnItems ADD BoxCount INT NULL;
END
GO

PRINT 'Return box count schema ready.';
GO
