GRANT SELECT ON security.[user] (client_id, login) TO client_role;

-- 2. Uprawnienia SELECT do konkretnych widoków
GRANT SELECT ON parties.view_client_profile TO client_role;
GRANT SELECT ON accounts.view_client_accounts TO client_role;
GRANT SELECT ON accounts.view_client_cards TO client_role;
GRANT SELECT ON loans.view_client_loans TO client_role;
GRANT SELECT ON transactions.view_client_transactions TO client_role;
GRANT SELECT ON transactions.view_client_card_payments TO client_role;
GRANT SELECT ON transactions.view_client_transfers TO client_role;