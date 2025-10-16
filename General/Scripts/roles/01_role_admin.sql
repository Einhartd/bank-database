CREATE ROLE admin_role;

-- admin permissions (super user)
-- admin może robić wszystko w bazie danych, ma nielimitowany dostęp.

GRANT USAGE ON SCHEMA security, parties, accounts, transactions, loans, shared TO admin_role;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA security, parties, accounts, transactions, loans, shared TO admin_role;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA security, parties, accounts, transactions, loans, shared TO admin_role;
