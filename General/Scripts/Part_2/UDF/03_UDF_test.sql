

-- testy dla udf konwertujacej waluty
BEGIN;
DO $$
DECLARE
    v_result DECIMAL(12,2);
BEGIN

    SELECT shared.fn_convert_currency(100.00, 1, 1, '2025-10-10')
    INTO v_result;
    RAISE NOTICE 'Test 1 (PLN-PLN): %', v_result;

    SELECT shared.fn_convert_currency(100.00, 2, 1, '2025-10-10')
    INTO v_result;
    RAISE NOTICE 'Test 2 (EUR-PLN): %', v_result;

    SELECT shared.fn_convert_currency(100.00, 1, 2, '2025-10-10')
    INTO v_result;
    RAISE NOTICE 'Test 3 (PLN-EUR): %', v_result;

    BEGIN
        PERFORM shared.fn_convert_currency(100.00, 1, 99, '2025-10-10');
    EXCEPTION
        WHEN raise_exception THEN
            RAISE NOTICE 'Test 4 (PLN-UNKNOWN): %', 'Exception';
    END;

END;
$$;
ROLLBACK;

-- test dla udf sumujacej salda kont danego klienta
BEGIN;
DO $$
DECLARE
    v_total_balance DECIMAL(12,2);

BEGIN

    SELECT accounts.fn_get_client_total_balance(1,1,'2025-10-10')
    INTO v_total_balance;
    RAISE NOTICE 'Test client 1 PLN (saldo = 8820): %', v_total_balance;

    SELECT accounts.fn_get_client_total_balance(3,1,'2025-10-10')
    INTO v_total_balance;
    RAISE NOTICE 'Test client 3 EUR-PLN (saldo = 13603.19): %', v_total_balance;

END;

$$;
ROLLBACK;