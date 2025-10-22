-- test dla indeksu prostego
DISCARD ALL;

EXPLAIN ANALYZE
SELECT transaction_id
FROM transactions.transaction
WHERE time BETWEEN '2025-10-10 10:00:00' AND '2025-10-15 11:00:00'
ORDER BY time DESC
LIMIT 10;

CREATE INDEX idx_transaction_time
ON transactions.transaction(time);

DISCARD ALL;

EXPLAIN ANALYZE
SELECT transaction_id
FROM transactions.transaction
WHERE time BETWEEN '2025-10-10 10:00:00' AND '2025-10-15 11:00:00'
ORDER BY time DESC
LIMIT 10;

DROP INDEX IF EXISTS transactions.idx_transaction_time;