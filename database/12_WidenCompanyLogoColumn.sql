/* =====================================================================
   Fruit Wholesale Management System
   12_WidenCompanyLogoColumn.sql
   Widens CompanySettings.LogoUrl from NVARCHAR(500) to NVARCHAR(MAX).
   The logo is now stored as a base64 data URI in this column instead of
   a file path, since the API runs on Azure Container Apps where the
   local filesystem is ephemeral (uploaded files were lost on every
   restart/redeploy/replica reschedule). NVARCHAR(500) can't hold an
   encoded image. Safe to re-run; does not touch existing data.
   ===================================================================== */
USE FruitWholesaleDB;
GO

IF EXISTS (
    SELECT 1 FROM sys.columns
    WHERE object_id = OBJECT_ID('dbo.CompanySettings') AND name = 'LogoUrl' AND max_length <> -1
)
BEGIN
    ALTER TABLE dbo.CompanySettings ALTER COLUMN LogoUrl NVARCHAR(MAX) NULL;
END
GO

PRINT 'CompanySettings.LogoUrl widened to NVARCHAR(MAX) successfully.';
GO
