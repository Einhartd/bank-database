DELETE FROM shared."exchangeRates"
WHERE date = '2025-10-31';

DO $$
DECLARE
    v_seq_name TEXT;
    v_next_val BIGINT;
BEGIN
    -- 1. Dynamiczne pobranie nazwy sekwencji
    SELECT pg_get_serial_sequence('shared."exchangeRates"', 'ex_rate_id')
    INTO v_seq_name;

    IF v_seq_name IS NULL THEN
        RAISE EXCEPTION 'Nie można znaleźć sekwencji dla shared."exchangeRates".ex_rate_id';
    END IF;

    -- 2. Obliczenie następnej wartości (tutaj wykonuje się Twój SELECT)
    SELECT COALESCE(MAX(ex_rate_id), 0) + 1
    INTO v_next_val
    FROM shared."exchangeRates";

    -- 3. Dynamiczne wykonanie polecenia ALTER SEQUENCE z konkretną liczbą
    RAISE NOTICE 'Resetowanie sekwencji: % do wartości: %', v_seq_name, v_next_val;
    EXECUTE format('ALTER SEQUENCE %s RESTART WITH %s', v_seq_name, v_next_val);

END $$;