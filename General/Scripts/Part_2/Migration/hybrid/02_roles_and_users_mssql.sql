CREATE ROLE admin_role;
GO

CREATE ROLE employee_role;
GO

CREATE ROLE client_role;
GO


-- Grant schema usage (SELECT, INSERT, UPDATE, DELETE on all tables)
GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA::security TO admin_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA::parties TO admin_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA::accounts TO admin_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA::transactions TO admin_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA::loans TO admin_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA::shared TO admin_role;
GO

-- Grant EXECUTE on all stored procedures and functions
GRANT EXECUTE ON SCHEMA::security TO admin_role;
GRANT EXECUTE ON SCHEMA::parties TO admin_role;
GRANT EXECUTE ON SCHEMA::accounts TO admin_role;
GRANT EXECUTE ON SCHEMA::transactions TO admin_role;
GRANT EXECUTE ON SCHEMA::loans TO admin_role;
GRANT EXECUTE ON SCHEMA::shared TO admin_role;
GO

-- Grant ALTER on all sequences
GRANT ALTER ON SCHEMA::security TO admin_role;
GRANT ALTER ON SCHEMA::parties TO admin_role;
GRANT ALTER ON SCHEMA::accounts TO admin_role;
GRANT ALTER ON SCHEMA::transactions TO admin_role;
GRANT ALTER ON SCHEMA::loans TO admin_role;
GRANT ALTER ON SCHEMA::shared TO admin_role;
GO


-- Employee can:
-- - Create client accounts
-- - Manage client data
-- - Process loan applications
-- - View other employees

-- Parties schema
GRANT SELECT, INSERT ON parties.client TO employee_role;
GRANT UPDATE ON parties.client TO employee_role;  -- Note: SQL Server doesn't support column-level UPDATE in GRANT statements the same way
GRANT SELECT ON parties.employee TO employee_role;
GRANT SELECT ON parties.positions TO employee_role;
GO

-- Security schema
GRANT INSERT ON security.[user] TO employee_role;
GRANT SELECT ON security.[user] TO employee_role;
GRANT SELECT ON security.loginHistory TO employee_role;
GRANT SELECT ON security.login_action_types TO employee_role;
GO

-- Accounts schema
GRANT SELECT ON accounts.account TO employee_role;
GRANT UPDATE ON accounts.account TO employee_role;
GRANT SELECT ON accounts.card TO employee_role;
GRANT UPDATE ON accounts.card TO employee_role;
GRANT SELECT ON accounts.account_types TO employee_role;
GRANT SELECT ON accounts.card_types TO employee_role;
GRANT SELECT ON accounts.card_statuses TO employee_role;
GO

-- Loans schema
GRANT SELECT, INSERT, UPDATE ON loans.loan TO employee_role;
GRANT SELECT ON loans.loan_statuses TO employee_role;
GO

-- Transactions and Shared (read-only)
GRANT SELECT ON SCHEMA::transactions TO employee_role;
GRANT SELECT ON SCHEMA::shared TO employee_role;
GO

-- Grant EXECUTE on specific procedures/functions
-- fn.convert_currency
GRANT EXECUTE ON shared.fn_convert_currency TO employee_role;
GRANT EXECUTE ON shared.fn_convert_currency TO client_role;
GRANT EXECUTE ON shared.fn_convert_currency TO admin_role;


GRANT EXECUTE ON accounts.fn_get_client_total_balance TO employee_role;
GRANT EXECUTE ON accounts.fn_get_client_total_balance TO admin_role;

GRANT EXECUTE ON accounts.fn_get_my_total_balance TO client_role;




-- procedures
GRANT EXECUTE ON shared.sp_add_currency TO employee_role;
GRANT EXECUTE ON shared.sp_add_currency TO admin_role;

GRANT EXECUTE ON parties.sp_add_new_employee TO admin_role;

GRANT EXECUTE ON shared.sp_add_symmetrical_exchange_rate TO employee_role, admin_role;

GRANT EXECUTE ON accounts.sp_open_account TO employee_role, admin_role;

GRANT EXECUTE ON accounts.sp_issue_new_card TO employee_role, admin_role;
-- =============================================
-- Client Role Permissions
-- =============================================
-- Client has limited access, mostly through views

-- Security (limited)
GRANT SELECT (client_id, login) ON security.[user] TO client_role;

-- Views
GRANT SELECT ON parties.view_client_profile TO client_role;
GRANT SELECT ON accounts.view_client_accounts TO client_role;
GRANT SELECT ON accounts.view_client_cards TO client_role;
GRANT SELECT ON loans.view_client_loans TO client_role;
GRANT SELECT ON transactions.view_client_transactions TO client_role;
GRANT SELECT ON transactions.view_client_card_payments TO client_role;
GRANT SELECT ON transactions.view_client_transfers TO client_role;
GO

-- Functions
-- GRANT EXECUTE ON accounts.fn_get_my_total_balance TO client_role;
GO


-- These are server-level accounts that can connect to SQL Server

CREATE LOGIN [azielinski] WITH PASSWORD = N'test', CHECK_POLICY = OFF;
GO

CREATE LOGIN [employee] WITH PASSWORD = N'test', CHECK_POLICY = OFF;
GO

CREATE LOGIN [admin] WITH PASSWORD = N'test', CHECK_POLICY = OFF;
GO


-- Map server logins to database users

CREATE USER [azielinski] FOR LOGIN [azielinski];
GO

CREATE USER [employee] FOR LOGIN [employee];
GO

CREATE USER [admin] FOR LOGIN [admin];
GO

-- =============================================
-- Assign Users to Roles
-- =============================================

ALTER ROLE client_role ADD MEMBER [azielinski];
GO

ALTER ROLE employee_role ADD MEMBER [employee];
GO

ALTER ROLE admin_role ADD MEMBER [admin];
GO

