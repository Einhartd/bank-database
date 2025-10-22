-- Roles for the database
CREATE ROLE admin_role;
CREATE ROLE client_role;
CREATE ROLE employee_role;

CREATE USER "azielinski" WITH PASSWORD 'test';
CREATE USER "employee" WITH PASSWORD 'test';
CREATE USER "admin" WITH PASSWORD 'test';

GRANT client_role TO azielinski;
GRANT admin_role TO "admin";
GRANT employee_role TO employee;