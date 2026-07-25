/* =====================================================================
   Fruit Wholesale Management System
   08_AddProfitTracking.sql

   Adds weighted-average cost tracking so profit can be calculated per
   Supply line item. Idempotent — safe to re-run against a live database.

   Design: FruitCostBasis holds each fruit's current (QuantityOnHand,
   AverageCost), maintained the same way StockLedger.RunningStock is —
   recalculated by walking that fruit's Purchase/Supply history in date
   order after any write. Under weighted-average costing, only a Purchase
   changes the average cost; a Supply consumes stock at whatever the
   average cost was AT THAT MOMENT, which is why SupplyItems.CostBasis is
   a per-row snapshot rather than something recomputed live — recording it
   once means later purchases (which shift the average going forward)
   never retroactively change the profit already booked on a past sale.
   ===================================================================== */
USE FruitWholesaleDB;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.columns
    WHERE object_id = OBJECT_ID('dbo.SupplyItems') AND name = 'CostBasis'
)
BEGIN
    ALTER TABLE dbo.SupplyItems ADD CostBasis DECIMAL(18,4) NOT NULL CONSTRAINT DF_SupplyItems_CostBasis DEFAULT (0);
END
GO

IF OBJECT_ID('dbo.FruitCostBasis', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.FruitCostBasis
    (
        FruitID          INT            NOT NULL,
        QuantityOnHand   DECIMAL(18,3)  NOT NULL CONSTRAINT DF_FruitCostBasis_QuantityOnHand DEFAULT (0),
        AverageCost      DECIMAL(18,4)  NOT NULL CONSTRAINT DF_FruitCostBasis_AverageCost DEFAULT (0),
        UpdatedAt        DATETIME2      NOT NULL CONSTRAINT DF_FruitCostBasis_UpdatedAt DEFAULT (SYSUTCDATETIME()),
        CONSTRAINT PK_FruitCostBasis PRIMARY KEY CLUSTERED (FruitID),
        CONSTRAINT FK_FruitCostBasis_FruitMaster FOREIGN KEY (FruitID) REFERENCES dbo.FruitMaster(FruitID)
    );
END
GO

PRINT 'Profit tracking columns/tables ready.';
GO
