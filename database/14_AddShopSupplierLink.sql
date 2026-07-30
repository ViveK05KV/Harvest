/* =====================================================================
   Fruit Wholesale Management System
   14_AddShopSupplierLink.sql

   Adds ShopMaster.LinkedSupplierID, an optional link to a SupplierMaster
   row representing the same real-world party (a shop that we also buy
   from, i.e. a business that is both a customer and a supplier). This
   only stores the link — the Shop Ledger and Supplier Ledger stay fully
   independent (correct double-entry per side); the API computes a net
   receivable/payable position on read by combining
   GetShopOutstandingAsync and GetSupplierOutstandingAsync for the linked
   pair, so no existing ledger data or logic changes.

   Idempotent — safe to re-run against a live database.
   ===================================================================== */
USE FruitWholesaleDB;
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.ShopMaster') AND name = 'LinkedSupplierID')
BEGIN
    ALTER TABLE dbo.ShopMaster ADD LinkedSupplierID INT NULL;
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_ShopMaster_SupplierMaster')
BEGIN
    ALTER TABLE dbo.ShopMaster ADD CONSTRAINT FK_ShopMaster_SupplierMaster
        FOREIGN KEY (LinkedSupplierID) REFERENCES dbo.SupplierMaster(SupplierID);
END
GO

PRINT 'ShopMaster.LinkedSupplierID ready.';
GO
