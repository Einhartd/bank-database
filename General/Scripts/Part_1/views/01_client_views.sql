-- Widok na dane osobowe klienta
CREATE OR REPLACE VIEW parties.view_client_profile AS
SELECT
    client_id,
    name,
    surname,
    pesel,
    email
FROM
    parties.client
WHERE
    client_id = (SELECT client_id FROM security.user WHERE login = current_user);

-- Widok na konta bankowe klienta
CREATE OR REPLACE VIEW accounts.view_client_accounts AS
SELECT
    a.account_id,
    a.number,
    a.balance,
    c.symbol AS currency,
    at.name AS account_type,
    a.client_id,
    a.currency_id
FROM
    accounts.account a
JOIN
    shared.currency c ON a.currency_id = c.currency_id
JOIN
    accounts.account_types at ON a.account_type_id = at.account_type_id
WHERE
    a.client_id = (SELECT client_id FROM security.user WHERE login = current_user);

-- Widok na karty płatnicze klienta
CREATE OR REPLACE VIEW accounts.view_client_cards AS
SELECT
    a_card.card_id,
    a_card.number,
    a_card.expiry_date,
    ct.name AS card_type,
    cs.name AS card_status
FROM
    accounts.card a_card
JOIN
    accounts.view_client_accounts client_acc ON a_card.account_id = client_acc.account_id
JOIN
    accounts.card_types ct ON a_card.card_type_id = ct.card_type_id
JOIN
    accounts.card_statuses cs ON a_card.card_status_id = cs.card_status_id;

-- Widok na kredyty klienta
CREATE OR REPLACE VIEW loans.view_client_loans AS
SELECT
    ll.loan_id,
    ll.amount,
    ll.interest_rate,
    ll.start_date,
    ls.name AS loan_status
FROM
    loans.loan ll
JOIN
    loans.loan_statuses ls ON ll.loan_status_id = ls.loan_status_id
WHERE
    client_id = (SELECT client_id FROM security.user WHERE login = current_user);

-- Widok na historię transakcji klienta
CREATE OR REPLACE VIEW transactions.view_client_transactions AS
SELECT
    t.transaction_id,
    t.amount,
    t.time,
    sender_acc.number AS sender_account_number,
    receiver_acc.number AS receiver_account_number,
    c.number AS card_number,
    ex.ex_rate AS exchange_rate,
    t.description,
    t.counterparty_name,
    t.counterparty_acc_num,
    tt.name AS transaction_type,
    ts.name AS transaction_status
FROM
    transactions.transaction t
LEFT JOIN
    accounts.account sender_acc ON t.sender_account_id = sender_acc.account_id
LEFT JOIN
    accounts.account receiver_acc ON t.receiver_account_id = receiver_acc.account_id
JOIN
    transactions.transaction_types tt ON t.transaction_type_id = tt.transaction_type_id
JOIN
    transactions.transaction_statuses ts ON t.transaction_status_id = ts.transaction_status_id
LEFT JOIN
    shared."exchangeRates" ex ON t.exchange_id = ex.ex_rate_id
LEFT JOIN
    accounts.card c on t.card_id = c.card_id
WHERE
    t.sender_account_id IN (SELECT account_id FROM accounts.view_client_accounts)
    OR t.receiver_account_id IN (SELECT account_id FROM accounts.view_client_accounts)
    OR t.card_id IN (SELECT card_id FROM accounts.view_client_cards);

-- widok dla płatności karta
CREATE OR REPLACE VIEW transactions.view_client_card_payments AS
SELECT
    t.transaction_id,
    t.amount,
    t.time,
    c.number AS card_number,
    t.description,
    t.counterparty_name,
    tt.name AS transaction_type,
    ts.name AS transaction_status
FROM
    transactions.transaction t
JOIN
    transactions.transaction_types tt ON t.transaction_type_id = tt.transaction_type_id
JOIN
    transactions.transaction_statuses ts ON t.transaction_status_id = ts.transaction_status_id
LEFT JOIN
    accounts.card c on t.card_id = c.card_id
WHERE
    t.card_id IN (SELECT card_id FROM accounts.view_client_cards);

-- widok dla samych przelewow
CREATE OR REPLACE VIEW transactions.view_client_transfers AS
SELECT
    t.transaction_id,
    t.amount,
    t.time,
    sender_acc.number    AS sender_account_number,
    receiver_acc.number  AS receiver_account_number,
    t.description,
    t.counterparty_name,
    t.counterparty_acc_num,
    tt.name AS transaction_type,
    ts.name AS transaction_status
FROM
    transactions.transaction t
LEFT JOIN
    accounts.account sender_acc ON t.sender_account_id = sender_acc.account_id
LEFT JOIN
    accounts.account receiver_acc ON t.receiver_account_id = receiver_acc.account_id
JOIN
    transactions.transaction_types tt ON t.transaction_type_id = tt.transaction_type_id
JOIN
    transactions.transaction_statuses ts ON t.transaction_status_id = ts.transaction_status_id
WHERE
    t.card_id IS NULL AND
    (t.sender_account_id IN (SELECT account_id FROM accounts.view_client_accounts)
     OR t.receiver_account_id IN (SELECT account_id FROM accounts.view_client_accounts));