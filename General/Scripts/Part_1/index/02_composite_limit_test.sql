DISCARD ALL;

EXPLAIN ANALYZE
SELECT transaction_id, card_id, amount
FROM transactions.transaction
WHERE
    transaction_type_id = 4
AND amount >=3000
ORDER BY amount DESC
LIMIT 10;

CREATE INDEX idx_t_id_amount ON transactions.transaction(transaction_type_id, amount);

DISCARD ALL;

EXPLAIN ANALYZE
SELECT transaction_id, card_id, amount
FROM transactions.transaction
WHERE
    transaction_type_id = 4
AND amount >=3000
ORDER BY amount DESC
LIMIT 10;

DROP INDEX IF EXISTS transactions.idx_t_id_amount;