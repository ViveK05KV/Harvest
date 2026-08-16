USE FruitWholesaleDB;
GO

IF OBJECT_ID('dbo.RefreshTokens', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.RefreshTokens (
        RefreshTokenID INT IDENTITY PRIMARY KEY,
        UserID INT NOT NULL,
        TokenHash NVARCHAR(128) NOT NULL,
        ExpiresAt DATETIME2 NOT NULL,
        CreatedAt DATETIME2 NOT NULL CONSTRAINT DF_RefreshTokens_CreatedAt DEFAULT SYSUTCDATETIME(),
        RevokedAt DATETIME2 NULL,
        ReplacedByTokenHash NVARCHAR(128) NULL,
        CONSTRAINT FK_RefreshTokens_Users FOREIGN KEY (UserID) REFERENCES dbo.Users (UserID)
    );
    CREATE INDEX IX_RefreshTokens_TokenHash ON dbo.RefreshTokens (TokenHash);
    CREATE INDEX IX_RefreshTokens_UserID ON dbo.RefreshTokens (UserID);
END
GO
