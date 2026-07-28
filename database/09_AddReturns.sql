/* =====================================================================
   Fruit Wholesale Management System
   09_AddReturns.sql

   Adds Shop Returns (a shop sends fruit back to us, after a Supply
   invoice) and Supplier Returns (we send fruit back to a supplier, after
   a Purchase invoice). Modeled as their own dated documents rather than
   edits to the original invoice, so the original bill stays an accurate
   record of what was actually billed and the return is its own auditable
   transaction — the same convention Collections/SupplierPayments already
   use (they don't touch the invoices they're paying against either).

   Cost-basis symmetry with the existing Purchase/Supply replay in
   LedgerService.RecalculateFruitCostBasisAsync:
     - A Shop Return puts stock back IN, so it behaves like a Purchase in
       the weighted-average replay: ShopReturnItems.CostBasis is an INPUT
       (set once at creation, defaulted from the original SupplyItem's
       CostBasis when linked, otherwise the fruit's current average cost)
       that blends into the average cost going forward, same role as
       PurchaseItems.PurchasePrice.
     - A Supplier Return takes stock back OUT, so it behaves like a
       Supply: SupplierReturnItems.CostBasis is an OUTPUT the replay
       snapshots on its way past, same role as SupplyItems.CostBasis.

   Idempotent — safe to re-run against a live database.
   ===================================================================== */
USE FruitWholesaleDB;
GO

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

PRINT 'Shop Returns / Supplier Returns tables ready. Run 02_Indexes.sql to (re)apply their indexes.';
GO
