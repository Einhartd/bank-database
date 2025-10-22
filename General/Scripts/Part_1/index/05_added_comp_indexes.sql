-- Indeksy kompozytowe dla częstych, złożonych zapytań
CREATE INDEX idx_exchangeRates_from_to_id ON shared."exchangeRates" (curr_from_id, curr_to_id);
CREATE INDEX idx_client_surname_name ON parties.client (surname, name);
CREATE INDEX idx_loginHistory_user_time ON security."loginHistory" (user_id, login_time DESC);
CREATE INDEX idx_transaction_sender_time ON transactions.transaction (sender_account_id, time DESC);
CREATE INDEX idx_transaction_receiver_time ON transactions.transaction (receiver_account_id, time DESC);
CREATE INDEX idx_exchangeRates_pair_date ON shared."exchangeRates" (curr_from_id, curr_to_id, date DESC);