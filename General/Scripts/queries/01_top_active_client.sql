-- zapytanie zbierajace wszystkie konta i karty klienta
-- do jednego klienta

SELECT
    client.client_id,
    client.name,
    client.surname,
    acc.account_id,
    c.card_id
FROM
    parties.client client
JOIN
    accounts.account acc ON client.client_id = acc.client_id
LEFT JOIN
    accounts.card c ON acc.account_id = c.account_id
ORDER BY client.client_id;

SELECT
    c.name AS client_name,
    c.surname AS client_surname,
    COUNT(DISTINCT t.transaction_id) AS transactions_count
FROM
    parties.client c
JOIN
    accounts.account a ON c.client_id = a.client_id
LEFT JOIN
    accounts.card crd ON a.account_id = crd.account_id
JOIN
    transactions.transaction t ON a.account_id = t.sender_account_id OR crd.card_id = t.card_id
WHERE
    t.transaction_status_id = (
        SELECT transaction_status_id FROM transactions.transaction_statuses WHERE name = 'Zakończona'
    )
GROUP BY
    c.client_id, c.name, c.surname
ORDER BY
    transactions_count DESC
LIMIT 2;