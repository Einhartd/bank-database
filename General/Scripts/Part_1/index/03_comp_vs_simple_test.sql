DROP INDEX IF EXISTS transactions.idx_test_sender_id;
DROP INDEX IF EXISTS transactions.idx_test_time;
DROP INDEX IF EXISTS transactions.idx_test_sender_time;

DISCARD ALL;

EXPLAIN ANALYZE
SELECT *
FROM transactions.transaction
WHERE sender_account_id = 1
  AND time BETWEEN '2025-01-01 00:00:00' AND '2025-01-31 23:59:59';

DROP INDEX IF EXISTS transactions.idx_test_sender_id;
DROP INDEX IF EXISTS transactions.idx_test_time;
DROP INDEX IF EXISTS transactions.idx_test_sender_time;

-- dwa proste indexy
CREATE INDEX idx_test_sender_id ON transactions.transaction(sender_account_id);
CREATE INDEX idx_test_time ON transactions.transaction(time);

ANALYZE transactions.transaction;

EXPLAIN ANALYZE
SELECT *
FROM transactions.transaction
WHERE sender_account_id = 1
  AND time BETWEEN '2025-01-01 00:00:00' AND '2025-01-31 23:59:59';

DROP INDEX transactions.idx_test_sender_id;
DROP INDEX transactions.idx_test_time;

CREATE INDEX idx_test_sender_time ON transactions.transaction(sender_account_id, time);

ANALYZE transactions.transaction;

DISCARD ALL;

EXPLAIN ANALYZE
SELECT *
FROM transactions.transaction
WHERE sender_account_id = 1
  AND time BETWEEN '2025-01-01 00:00:00' AND '2025-01-31 23:59:59';

DROP INDEX IF EXISTS transactions.idx_test_sender_id;
DROP INDEX IF EXISTS transactions.idx_test_time;
DROP INDEX IF EXISTS transactions.idx_test_sender_time;