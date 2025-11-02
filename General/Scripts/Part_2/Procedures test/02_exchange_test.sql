SELECT * FROM shared."exchangeRates";

CALL shared.sp_add_symmetrical_exchange_rate('CHF', 'PLN', 4.59, '2025-10-10');

SELECT * FROM shared."exchangeRates";