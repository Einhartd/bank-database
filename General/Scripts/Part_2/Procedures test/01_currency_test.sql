BEGIN;
CALL shared.sp_add_currency('CHF', 'Frank szwajcarski');
SELECT * FROM shared.currency;
ROLLBACK;

SELECT SETVAL(
  pg_get_serial_sequence('shared.currency', 'currency_id'),
  (SELECT COALESCE(MAX(currency_id), 0) FROM shared.currency),
  true
);