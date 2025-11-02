IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'security')
BEGIN
    EXEC('CREATE SCHEMA security');
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'parties')
BEGIN
    EXEC('CREATE SCHEMA parties');
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'accounts')
BEGIN
    EXEC('CREATE SCHEMA accounts');
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'transactions')
BEGIN
    EXEC('CREATE SCHEMA transactions');
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'loans')
BEGIN
    EXEC('CREATE SCHEMA loans');
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'shared')
BEGIN
    EXEC('CREATE SCHEMA shared');
END
GO