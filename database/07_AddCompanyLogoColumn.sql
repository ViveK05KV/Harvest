/* =====================================================================
   Fruit Wholesale Management System
   07_AddCompanyLogoColumn.sql
   Adds LogoUrl to CompanySettings for existing databases created before
   this column was added to 01_CreateDatabase_Tables.sql. Safe to re-run.
   Does not touch any existing data.
   ===================================================================== */
USE FruitWholesaleDB;
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.CompanySettings') AND name = 'LogoUrl')
BEGIN
    ALTER TABLE dbo.CompanySettings ADD LogoUrl NVARCHAR(500) NULL;
END
GO

PRINT 'Company logo column added successfully.';
GO
