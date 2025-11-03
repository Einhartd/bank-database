USE bank_db_manual;
GO

SELECT
    roles.name AS RoleName,
    members.name AS MemberName
FROM sys.database_role_members AS rm
JOIN sys.database_principals AS roles ON rm.role_principal_id = roles.principal_id
JOIN sys.database_principals AS members ON rm.member_principal_id = members.principal_id
WHERE roles.name IN ('admin_role', 'employee_role', 'client_role');

SELECT name, type_desc, default_database_name
FROM sys.server_principals
WHERE type = 'S';

USE bank_db_manual;
GO

SELECT name, type_desc, default_schema_name
FROM sys.database_principals
WHERE type = 'S';