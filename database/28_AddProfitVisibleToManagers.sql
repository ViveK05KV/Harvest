DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'companysettings' AND column_name = 'profitvisibletomanagers'
    ) THEN
        ALTER TABLE CompanySettings ADD COLUMN ProfitVisibleToManagers BOOLEAN NOT NULL DEFAULT FALSE;
    END IF;
END
$$;
