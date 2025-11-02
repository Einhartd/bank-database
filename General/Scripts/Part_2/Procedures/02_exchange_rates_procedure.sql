/*
  --
  Procedura sp_AddSymmetricalExchangeRate
  Opis: Dodaje dwa rekordy kursow (glowny i odwrotny)
  zapewnia spojnosc kursow.
  Uwaga: Problemy przy migracji
  --
 */

CREATE PROCEDURE shared.sp_add_symmetrical_exchange_rate(
    p_symbol_from CHAR(3),
    p_symbol_to CHAR(3),
    p_direct_rate DECIMAL(10, 6),
    p_date DATE
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_inverse_rate DECIMAL(10, 6);
    v_count_direct INT;
    v_count_inverse INT;
    v_curr_from_id INT;
    v_curr_to_id INT;
BEGIN

    SELECT currency_id INTO v_curr_from_id
    FROM shared.currency c
    WHERE c.symbol = p_symbol_from;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Waluta źrodlowa o symbolu "%" nie istnieje w tabeli shared.currency.', p_symbol_from;
    END IF;

    SELECT currency_id INTO v_curr_to_id
    FROM shared.currency c
    WHERE c.symbol = p_symbol_to;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Waluta docelowa o symbolu "%" nie istnieje w tabeli shared.currency.', p_symbol_to;
    END IF;

    IF v_curr_from_id = v_curr_to_id THEN
        RAISE EXCEPTION 'Nie mozna dodac kursu wymiany dla tej samej waluty (%).', p_symbol_from;
    END IF;

    SELECT COUNT(*) INTO v_count_direct
    FROM shared."exchangeRates" er
    WHERE er.curr_from_id = v_curr_from_id
      AND er.curr_to_id = v_curr_to_id
      AND er.date = p_date;

    SELECT COUNT(*) INTO v_count_inverse
    FROM shared."exchangeRates" er
    WHERE er.curr_from_id = v_curr_to_id
      AND er.curr_to_id = v_curr_from_id
      AND er.date = p_date;

    IF v_count_direct = 0 AND v_count_inverse = 0 THEN

        v_inverse_rate := 1.0 / p_direct_rate;

        INSERT INTO shared."exchangeRates" (curr_from_id, curr_to_id, ex_rate, date)
        VALUES (v_curr_from_id, v_curr_to_id, p_direct_rate, p_date);

        INSERT INTO shared."exchangeRates" (curr_from_id, curr_to_id, ex_rate, date)
        VALUES (v_curr_to_id, v_curr_from_id, v_inverse_rate, p_date);

        RETURN;

    ELSIF v_count_direct = 1 AND v_count_inverse = 1 THEN
        RAISE NOTICE 'Kursy dla pary %/% na dzien % już sa. Pomijam.',
            p_symbol_from, p_symbol_to, p_date;
        RETURN;

    ELSE
        RAISE EXCEPTION 'NIESPOJNOSC DANYCH! Tabela exchangeRates jest uszkodzona dla pary %/% na dzien %.',
            p_symbol_from, p_symbol_to, p_date;
    END IF;
END;
$$;

REVOKE EXECUTE ON PROCEDURE shared.sp_add_symmetrical_exchange_rate FROM PUBLIC;

GRANT EXECUTE ON PROCEDURE shared.sp_add_symmetrical_exchange_rate TO employee_role, oliwier, admin_role;

