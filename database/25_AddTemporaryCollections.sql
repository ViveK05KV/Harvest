USE FruitWholesaleDB;
GO

IF OBJECT_ID('dbo.TemporaryCollectionSettlements', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.TemporaryCollectionSettlements (
        TemporaryCollectionSettlementID INT IDENTITY PRIMARY KEY,
        ShopID INT NOT NULL,
        SettlementDate DATE NOT NULL,
        TotalAmount DECIMAL(18,2) NOT NULL,
        CreatedBy INT NULL,
        CreatedAt DATETIME2 NOT NULL CONSTRAINT DF_TemporaryCollectionSettlements_CreatedAt DEFAULT SYSUTCDATETIME(),
        CONSTRAINT FK_TemporaryCollectionSettlements_ShopMaster FOREIGN KEY (ShopID) REFERENCES dbo.ShopMaster (ShopID),
        CONSTRAINT FK_TemporaryCollectionSettlements_Users FOREIGN KEY (CreatedBy) REFERENCES dbo.Users (UserID)
    );
END
GO

IF COL_LENGTH('dbo.Collections', 'CollectionType') IS NULL
BEGIN
    ALTER TABLE dbo.Collections ADD CollectionType NVARCHAR(20) NULL;
END
GO

IF COL_LENGTH('dbo.Collections', 'TemporaryStatus') IS NULL
BEGIN
    ALTER TABLE dbo.Collections ADD TemporaryStatus NVARCHAR(20) NOT NULL CONSTRAINT DF_Collections_TemporaryStatus DEFAULT 'None';
END
GO

IF COL_LENGTH('dbo.Collections', 'SettlementID') IS NULL
BEGIN
    ALTER TABLE dbo.Collections ADD SettlementID INT NULL;
    ALTER TABLE dbo.Collections
        ADD CONSTRAINT FK_Collections_TemporaryCollectionSettlements FOREIGN KEY (SettlementID)
        REFERENCES dbo.TemporaryCollectionSettlements (TemporaryCollectionSettlementID);
END
GO

UPDATE dbo.Collections
SET CollectionType = 'Normal'
WHERE CollectionType IS NULL;
GO
