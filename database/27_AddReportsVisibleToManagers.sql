DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'companysettings' AND column_name = 'reportsvisibletomanagers'
    ) THEN
        ALTER TABLE CompanySettings ADD COLUMN ReportsVisibleToManagers BOOLEAN NOT NULL DEFAULT FALSE;
    END IF;
END
$$;
