-- Indeksy dla kluczy obcych (jeśli nie są tworzone automatycznie)
CREATE INDEX idx_user_employee_id ON security.user (employee_id);
CREATE INDEX idx_user_client_id ON security.user (client_id);

CREATE INDEX idx_loginHistory_user_id ON security."loginHistory" (user_id);
CREATE INDEX idx_loginHistory_action_type_id ON security."loginHistory" (action_type_id);

CREATE INDEX idx_employee_position_id ON parties.employee (position_id);

CREATE INDEX idx_account_client_id ON accounts.account (client_id);
CREATE INDEX idx_account_currency_id ON accounts.account (currency_id);
CREATE INDEX idx_account_type_id ON accounts.account (account_type_id);

CREATE INDEX idx_card_account_id ON accounts.card (account_id);
CREATE INDEX idx_card_type_id ON accounts.card (card_type_id);
CREATE INDEX idx_card_status_id ON accounts.card (card_status_id);

CREATE INDEX idx_loan_client_id ON loans.loan (client_id);
CREATE INDEX idx_loan_employee_id ON loans.loan (employee_id);
CREATE INDEX idx_loan_status_id ON loans.loan (loan_status_id);

CREATE INDEX idx_transaction_sender_id ON transactions.transaction (sender_account_id);
CREATE INDEX idx_transaction_receiver_id ON transactions.transaction (receiver_account_id);
CREATE INDEX idx_transaction_card_id ON transactions.transaction (card_id);
CREATE INDEX idx_transaction_type_id ON transactions.transaction (transaction_type_id);
CREATE INDEX idx_transaction_status_id ON transactions.transaction (transaction_status_id);
CREATE INDEX idx_exchange_id ON transactions.transaction (exchange_id);


