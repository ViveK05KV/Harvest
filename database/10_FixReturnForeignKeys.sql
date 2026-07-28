/* =====================================================================
   Fruit Wholesale Management System
   10_FixReturnForeignKeys.sql

   ShopReturns.SupplyID and SupplierReturns.PurchaseID were originally
   created as plain (NO ACTION) foreign keys. That meant deleting a Supply
   or Purchase invoice that a later return happened to reference threw an
   FK violation instead of succeeding — the return record should survive
   deletion of the invoice it was linked to (the link is just optional
   traceability, per 09_AddReturns.sql), so these need ON DELETE SET NULL.

   Idempotent — safe to re-run against a live database.
   ===================================================================== */
USE FruitWholesaleDB;
GO

IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_ShopReturns_Supply' AND delete_referential_action = 0)
BEGIN
    ALTER TABLE dbo.ShopReturns DROP CONSTRAINT FK_ShopReturns_Supply;
    ALTER TABLE dbo.ShopReturns ADD CONSTRAINT FK_ShopReturns_Supply
        FOREIGN KEY (SupplyID) REFERENCES dbo.Supply(SupplyID) ON DELETE SET NULL;
END
GO

IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_SupplierReturns_Purchase' AND delete_referential_action = 0)
BEGIN
    ALTER TABLE dbo.SupplierReturns DROP CONSTRAINT FK_SupplierReturns_Purchase;
    ALTER TABLE dbo.SupplierReturns ADD CONSTRAINT FK_SupplierReturns_Purchase
        FOREIGN KEY (PurchaseID) REFERENCES dbo.Purchase(PurchaseID) ON DELETE SET NULL;
END
GO

PRINT 'ShopReturns/SupplierReturns foreign keys now SET NULL on delete.';
GO
