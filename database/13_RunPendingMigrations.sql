/* =====================================================================
   Fruit Wholesale Management System
   13_RunPendingMigrations.sql

   Combines every schema migration not yet applied to production
   (06 through 12, skipping 11_ClearTransactionalData.sql which deletes
   real transactional data and must never run against production) into
   one file, in the order they must run. Every step below is idempotent
   — guarded with IF NOT EXISTS / IF EXISTS checks — so it is safe to run
   this whole file even if some of these changes are already applied;
   already-applied steps just no-op.

   Run once against the production database:
     sqlcmd -S <prod-server>.database.windows.net -d FruitWholesaleDB -U <user> -P <password> -i "database\13_RunPendingMigrations.sql"
   ===================================================================== */
USE FruitWholesaleDB;
GO


/* --------------------------------------------------------------------
   06_AddDiscountColumns.sql
   Adds DiscountAmount to Collections and SupplierPayments.
   -------------------------------------------------------------------- */
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

PRINT 'Step 1/7: Discount columns ready.';
GO


/* --------------------------------------------------------------------
   07_AddCompanyLogoColumn.sql
   Adds LogoUrl to CompanySettings (narrow; widened to MAX in step 7 below).
   -------------------------------------------------------------------- */
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.CompanySettings') AND name = 'LogoUrl')
BEGIN
    ALTER TABLE dbo.CompanySettings ADD LogoUrl NVARCHAR(500) NULL;
END
GO

PRINT 'Step 2/7: CompanySettings.LogoUrl column ready.';
GO


/* --------------------------------------------------------------------
   08_AddProfitTracking.sql
   Adds weighted-average cost tracking (SupplyItems.CostBasis + FruitCostBasis).
   -------------------------------------------------------------------- */
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

PRINT 'Step 3/7: Profit tracking columns/tables ready.';
GO


/* --------------------------------------------------------------------
   09_AddReturns.sql
   Adds Shop Returns and Supplier Returns tables.
   -------------------------------------------------------------------- */
IF OBJECT_ID('dbo.ShopReturns', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.ShopReturns
    (
        ShopReturnID    INT IDENTITY(1,1) NOT NULL,
        ReturnDate      DATE               NOT NULL,
        ShopID          INT                NOT NULL,
        SupplyID        INT                NULL,
        ReferenceNo     NVARCHAR(50)       NOT NULL,
        Remarks         NVARCHAR(500)      NULL,
        TotalAmount     DECIMAL(18,2)      NOT NULL CONSTRAINT DF_ShopReturns_TotalAmount DEFAULT (0),
        CreatedBy       INT                NULL,
        CreatedAt       DATETIME2          NOT NULL CONSTRAINT DF_ShopReturns_CreatedAt DEFAULT (SYSUTCDATETIME()),
        UpdatedAt       DATETIME2          NULL,
        CONSTRAINT PK_ShopReturns PRIMARY KEY CLUSTERED (ShopReturnID),
        CONSTRAINT UQ_ShopReturns_ReferenceNo UNIQUE (ReferenceNo),
        CONSTRAINT FK_ShopReturns_ShopMaster FOREIGN KEY (ShopID) REFERENCES dbo.ShopMaster(ShopID),
        CONSTRAINT FK_ShopReturns_Supply FOREIGN KEY (SupplyID) REFERENCES dbo.Supply(SupplyID) ON DELETE SET NULL,
        CONSTRAINT FK_ShopReturns_Users FOREIGN KEY (CreatedBy) REFERENCES dbo.Users(UserID)
    );
END
GO

IF OBJECT_ID('dbo.ShopReturnItems', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.ShopReturnItems
    (
        ShopReturnItemID INT IDENTITY(1,1) NOT NULL,
        ShopReturnID      INT               NOT NULL,
        FruitID           INT               NOT NULL,
        Quantity          DECIMAL(18,3)     NOT NULL,
        UnitPrice         DECIMAL(18,2)     NOT NULL,
        TotalAmount       DECIMAL(18,2)     NOT NULL,
        CostBasis         DECIMAL(18,4)     NOT NULL CONSTRAINT DF_ShopReturnItems_CostBasis DEFAULT (0),
        CONSTRAINT PK_ShopReturnItems PRIMARY KEY CLUSTERED (ShopReturnItemID),
        CONSTRAINT FK_ShopReturnItems_ShopReturns FOREIGN KEY (ShopReturnID) REFERENCES dbo.ShopReturns(ShopReturnID) ON DELETE CASCADE,
        CONSTRAINT FK_ShopReturnItems_FruitMaster FOREIGN KEY (FruitID) REFERENCES dbo.FruitMaster(FruitID)
    );
END
GO

IF OBJECT_ID('dbo.SupplierReturns', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.SupplierReturns
    (
        SupplierReturnID INT IDENTITY(1,1) NOT NULL,
        ReturnDate        DATE               NOT NULL,
        SupplierID        INT                NOT NULL,
        PurchaseID        INT                NULL,
        ReferenceNo       NVARCHAR(50)       NOT NULL,
        Remarks           NVARCHAR(500)      NULL,
        TotalAmount       DECIMAL(18,2)      NOT NULL CONSTRAINT DF_SupplierReturns_TotalAmount DEFAULT (0),
        CreatedBy         INT                NULL,
        CreatedAt         DATETIME2          NOT NULL CONSTRAINT DF_SupplierReturns_CreatedAt DEFAULT (SYSUTCDATETIME()),
        UpdatedAt         DATETIME2          NULL,
        CONSTRAINT PK_SupplierReturns PRIMARY KEY CLUSTERED (SupplierReturnID),
        CONSTRAINT UQ_SupplierReturns_ReferenceNo UNIQUE (ReferenceNo),
        CONSTRAINT FK_SupplierReturns_SupplierMaster FOREIGN KEY (SupplierID) REFERENCES dbo.SupplierMaster(SupplierID),
        CONSTRAINT FK_SupplierReturns_Purchase FOREIGN KEY (PurchaseID) REFERENCES dbo.Purchase(PurchaseID) ON DELETE SET NULL,
        CONSTRAINT FK_SupplierReturns_Users FOREIGN KEY (CreatedBy) REFERENCES dbo.Users(UserID)
    );
END
GO

IF OBJECT_ID('dbo.SupplierReturnItems', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.SupplierReturnItems
    (
        SupplierReturnItemID INT IDENTITY(1,1) NOT NULL,
        SupplierReturnID      INT               NOT NULL,
        FruitID                INT               NOT NULL,
        Quantity               DECIMAL(18,3)     NOT NULL,
        UnitPrice              DECIMAL(18,2)     NOT NULL,
        TotalAmount            DECIMAL(18,2)     NOT NULL,
        CostBasis              DECIMAL(18,4)     NOT NULL CONSTRAINT DF_SupplierReturnItems_CostBasis DEFAULT (0),
        CONSTRAINT PK_SupplierReturnItems PRIMARY KEY CLUSTERED (SupplierReturnItemID),
        CONSTRAINT FK_SupplierReturnItems_SupplierReturns FOREIGN KEY (SupplierReturnID) REFERENCES dbo.SupplierReturns(SupplierReturnID) ON DELETE CASCADE,
        CONSTRAINT FK_SupplierReturnItems_FruitMaster FOREIGN KEY (FruitID) REFERENCES dbo.FruitMaster(FruitID)
    );
END
GO

PRINT 'Step 4/7: Shop Returns / Supplier Returns tables ready.';
GO


/* --------------------------------------------------------------------
   Returns indexes (from 02_Indexes.sql) — must run after the tables
   above exist. DROP/CREATE pattern, safe to re-run.
   -------------------------------------------------------------------- */
DROP INDEX IF EXISTS IX_ShopReturns_ShopID_ReturnDate ON dbo.ShopReturns;
CREATE NONCLUSTERED INDEX IX_ShopReturns_ShopID_ReturnDate ON dbo.ShopReturns (ShopID, ReturnDate DESC) INCLUDE (TotalAmount);
DROP INDEX IF EXISTS IX_ShopReturnItems_FruitID ON dbo.ShopReturnItems;
CREATE NONCLUSTERED INDEX IX_ShopReturnItems_FruitID ON dbo.ShopReturnItems (FruitID) INCLUDE (Quantity, CostBasis, ShopReturnID);
DROP INDEX IF EXISTS IX_SupplierReturns_SupplierID_ReturnDate ON dbo.SupplierReturns;
CREATE NONCLUSTERED INDEX IX_SupplierReturns_SupplierID_ReturnDate ON dbo.SupplierReturns (SupplierID, ReturnDate DESC) INCLUDE (TotalAmount);
DROP INDEX IF EXISTS IX_SupplierReturnItems_FruitID ON dbo.SupplierReturnItems;
CREATE NONCLUSTERED INDEX IX_SupplierReturnItems_FruitID ON dbo.SupplierReturnItems (FruitID) INCLUDE (Quantity, SupplierReturnID);
GO

PRINT 'Step 5/7: Returns indexes ready.';
GO


/* --------------------------------------------------------------------
   10_FixReturnForeignKeys.sql
   ShopReturns.SupplyID / SupplierReturns.PurchaseID must be ON DELETE
   SET NULL so deleting the original invoice doesn't fail with an FK
   violation once a return references it.
   -------------------------------------------------------------------- */
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

PRINT 'Step 6/7: ShopReturns/SupplierReturns foreign keys now SET NULL on delete.';
GO


/* --------------------------------------------------------------------
   12_WidenCompanyLogoColumn.sql
   Widens CompanySettings.LogoUrl to NVARCHAR(MAX) — the logo is now
   stored as a base64 data URI in the DB instead of a file on the API
   container's local disk (that disk is ephemeral on Azure Container
   Apps: uploaded files were lost on every restart/redeploy).
   -------------------------------------------------------------------- */
IF EXISTS (
    SELECT 1 FROM sys.columns
    WHERE object_id = OBJECT_ID('dbo.CompanySettings') AND name = 'LogoUrl' AND max_length <> -1
)
BEGIN
    ALTER TABLE dbo.CompanySettings ALTER COLUMN LogoUrl NVARCHAR(MAX) NULL;
END
GO

PRINT 'Step 7/7: CompanySettings.LogoUrl widened to NVARCHAR(MAX).';
GO

PRINT 'All pending migrations applied successfully.';
GO
