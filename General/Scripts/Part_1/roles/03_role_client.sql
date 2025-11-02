CREATE ROLE client_role;

-- UPRAWNIENIA KLIENTA (ograniczone do widoków)
    -- Ograniczony dostęp do odczytu częsci danych w tabelach
    -- login i client_id w security.user

GRANT USAGE ON SCHEMA security, parties, accounts, loans, transactions, shared TO client_role;

GRANT SELECT (client_id, login) ON security.user TO client_role;

GRANT SELECT ON parties.view_client_profile TO client_role;
GRANT SELECT ON accounts.view_client_accounts TO client_role;
GRANT SELECT ON accounts.view_client_cards TO client_role;
GRANT SELECT ON loans.view_client_loans TO client_role;
GRANT SELECT ON transactions.view_client_transactions TO client_role;
GRANT SELECT ON transactions.view_client_card_payments TO client_role;
GRANT SELECT ON transactions.view_client_transfers TO client_role;
