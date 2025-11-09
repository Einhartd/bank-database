
-- tworzenie loginow na poziomie serwera (master)
USE master;

IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = 'azielinski')
BEGIN
    CREATE LOGIN azielinski WITH PASSWORD = 'test', CHECK_POLICY = OFF;
END

IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = 'employee')
BEGIN
    CREATE LOGIN employee WITH PASSWORD = 'test', CHECK_POLICY = OFF;
END

IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = 'admin')
BEGIN
    CREATE LOGIN "admin" WITH PASSWORD = 'test', CHECK_POLICY = OFF;
END

-- CHECK_POLICY = OFF pozwala na proste hasło 'test' i wyłącza sprawdzanie polityki haseł Windows


USE bank_db_manual;


-- tworzenie uzytkownikow bazy na poziomie bazy danych
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'azielinski')
BEGIN
    CREATE USER azielinski FOR LOGIN azielinski;
END

IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'employee')
BEGIN
    CREATE USER employee FOR LOGIN employee;
END

IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'admin')
BEGIN
    CREATE USER "admin" FOR LOGIN "admin";
END




-- utworzenie rol na poziomie bazy danych
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'admin_role' AND type = 'R')
BEGIN
    CREATE ROLE admin_role;
END

IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'employee_role' AND type = 'R')
BEGIN
    CREATE ROLE employee_role;
END

IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'client_role' AND type = 'R')
BEGIN
    CREATE ROLE client_role;
END


-- admin_role (dajemy pełną kontrolę nad schematami)
GRANT CONTROL ON SCHEMA::security TO admin_role;
GRANT CONTROL ON SCHEMA::parties TO admin_role;
GRANT CONTROL ON SCHEMA::accounts TO admin_role;
GRANT CONTROL ON SCHEMA::transactions TO admin_role;
GRANT CONTROL ON SCHEMA::loans TO admin_role;
GRANT CONTROL ON SCHEMA::shared TO admin_role;


-- employee_role (dajemy bardziej szczegółowe prawa)
GRANT SELECT, EXECUTE, UPDATE ON SCHEMA::parties TO employee_role;
GRANT SELECT, EXECUTE ON SCHEMA::security TO employee_role;
GRANT SELECT, EXECUTE, UPDATE ON SCHEMA::loans TO employee_role;
GRANT SELECT, EXECUTE ON SCHEMA::transactions TO employee_role;
GRANT SELECT, EXECUTE ON SCHEMA::shared TO employee_role;


-- client_role (podobne prawa jak employee, ale na innych schematach) [do usuniecia]
GRANT SELECT, EXECUTE ON SCHEMA::security TO client_role;
GRANT SELECT, EXECUTE ON SCHEMA::parties TO client_role;
GRANT SELECT, EXECUTE ON SCHEMA::accounts TO client_role;
GRANT SELECT, EXECUTE ON SCHEMA::loans TO client_role;
GRANT SELECT, EXECUTE ON SCHEMA::transactions TO client_role;
GRANT SELECT, EXECUTE ON SCHEMA::shared TO client_role;

-- dodanie uzytkownikow do rol
ALTER ROLE client_role ADD MEMBER azielinski;
ALTER ROLE admin_role ADD MEMBER "admin";
ALTER ROLE employee_role ADD MEMBER employee;