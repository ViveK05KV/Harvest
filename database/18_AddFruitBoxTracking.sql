/* =====================================================================
   Fruit Wholesale Management System
   18_AddFruitBoxTracking.sql

   Dual-unit stock tracking for fruits sold both as whole boxes and by
   loose weight (e.g. apples: ~18kg boxes, but customers can also buy a
   few kg out of an opened box). StockLedger keeps tracking total kg
   exactly as before - untouched. This adds a thin, opt-in layer on top
   that answers "how many physical boxes" independently of "how many kg."

   FruitMaster.TracksByBox - opt-in flag per fruit; fruits that don't
   sell by the box are completely unaffected by any of this.

   PurchaseItems.BoxCount - how many physical boxes this purchase line
   represents. Nullable - only meaningful for TracksByBox fruits. Each
   box's starting weight is Quantity / BoxCount (an average, since real
   boxes vary: one might be 17.5kg, another 18.4kg).

   FruitBoxes - one row per physical box. RemainingWeightKg drains as
   kg get sold; Status flips Full -> Opened -> Empty. Rebuilt from
   scratch by LedgerService.RecalculateFruitBoxesAsync on every
   Purchase/Supply write for a TracksByBox fruit (same event-replay
   approach already used for FruitCostBasis), so it never needs manual
   reconciliation after edits or deletes.

   Idempotent - safe to re-run against a live database.
   ===================================================================== */
USE FruitWholesaleDB;
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.FruitMaster') AND name = 'TracksByBox')
BEGIN
    ALTER TABLE dbo.FruitMaster ADD TracksByBox BIT NOT NULL CONSTRAINT DF_FruitMaster_TracksByBox DEFAULT (0);
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.PurchaseItems') AND name = 'BoxCount')
BEGIN
    ALTER TABLE dbo.PurchaseItems ADD BoxCount INT NULL;
END
GO

IF OBJECT_ID('dbo.FruitBoxes', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.FruitBoxes
    (
        FruitBoxID         INT IDENTITY(1,1) NOT NULL,
        FruitID            INT               NOT NULL,
        PurchaseID         INT               NULL,
        InitialWeightKg    DECIMAL(18,3)     NOT NULL,
        RemainingWeightKg  DECIMAL(18,3)     NOT NULL,
        Status             NVARCHAR(10)      NOT NULL, -- Full | Opened | Empty
        CreatedAt          DATETIME2         NOT NULL CONSTRAINT DF_FruitBoxes_CreatedAt DEFAULT (SYSUTCDATETIME()),
        UpdatedAt          DATETIME2         NULL,
        CONSTRAINT PK_FruitBoxes PRIMARY KEY CLUSTERED (FruitBoxID),
        CONSTRAINT FK_FruitBoxes_FruitMaster FOREIGN KEY (FruitID) REFERENCES dbo.FruitMaster(FruitID),
        CONSTRAINT FK_FruitBoxes_Purchase FOREIGN KEY (PurchaseID) REFERENCES dbo.Purchase(PurchaseID) ON DELETE SET NULL
    );

    CREATE NONCLUSTERED INDEX IX_FruitBoxes_FruitID_Status ON dbo.FruitBoxes (FruitID, Status) INCLUDE (RemainingWeightKg);
END
GO

PRINT 'Fruit box tracking schema ready.';
GO
