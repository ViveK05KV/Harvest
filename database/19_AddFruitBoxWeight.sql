/* =====================================================================
   Fruit Wholesale Management System
   19_AddFruitBoxWeight.sql

   Standard box weight per fruit, so Supply (sale) entry can offer a
   "By Box" input alongside "By Kg" for TracksByBox fruits. The UI
   converts box count -> kg using this nominal weight; StockLedger and
   the FruitBoxes FIFO drain (RecalculateFruitBoxesAsync) are unchanged
   and keep working off kg exactly as before.

   FruitMaster.BoxWeightKg - nominal kg per box. Nullable; only
   meaningful for TracksByBox fruits.

   SupplyItems.BoxCount - how many boxes this sale line represents,
   when sold "by box". Nullable, display-only (kg is still the number
   of record for stock/ledger math) - mirrors PurchaseItems.BoxCount.

   Idempotent - safe to re-run against a live database.
   ===================================================================== */
USE FruitWholesaleDB;
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.FruitMaster') AND name = 'BoxWeightKg')
BEGIN
    ALTER TABLE dbo.FruitMaster ADD BoxWeightKg DECIMAL(18,3) NULL;
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.SupplyItems') AND name = 'BoxCount')
BEGIN
    ALTER TABLE dbo.SupplyItems ADD BoxCount INT NULL;
END
GO

PRINT 'Fruit box weight schema ready.';
GO
