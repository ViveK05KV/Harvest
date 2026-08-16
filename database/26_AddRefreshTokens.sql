DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'refreshtokens') THEN
        CREATE TABLE RefreshTokens (
            RefreshTokenID INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
            UserID INT NOT NULL,
            TokenHash VARCHAR(128) NOT NULL,
            ExpiresAt TIMESTAMP NOT NULL,
            CreatedAt TIMESTAMP NOT NULL DEFAULT (now() AT TIME ZONE 'utc'),
            RevokedAt TIMESTAMP NULL,
            ReplacedByTokenHash VARCHAR(128) NULL,
            CONSTRAINT FK_RefreshTokens_Users FOREIGN KEY (UserID) REFERENCES Users (UserID)
        );
        CREATE INDEX IX_RefreshTokens_TokenHash ON RefreshTokens (TokenHash);
        CREATE INDEX IX_RefreshTokens_UserID ON RefreshTokens (UserID);
    END IF;
END
$$;
