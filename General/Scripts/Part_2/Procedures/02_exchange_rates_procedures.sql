/*
  --
  Procedura sp_AddSymmetricalExchangeRate
  Opis: Dodaje dwa rekordy kursow (glowny i odwrotny)
  zapewnia spojnosc kursow.
  Uwaga: Problemy przy migracji
  --
 */

CREATE OR REPLACE PROCEDURE shared.sp_AddSymmetricalExchangeRate(
    p_curr_from_id INT,
    p_curr_to_id INT,
    p_direct_rate DECIMAL(10, 6),
    p_date DATE
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_inverse_rate DECIMAL(10, 6);
    v_count_direct INT;
    v_count_inverse INT;
BEGIN

    SELECT COUNT(*) INTO v_count_direct
    FROM shared."exchangeRates" er
    WHERE er.curr_from_id = p_curr_from_id
      AND er.curr_to_id = p_curr_to_id
      AND er.date = p_date;

    SELECT COUNT(*) INTO v_count_inverse
    FROM shared."exchangeRates" er
    WHERE er.curr_from_id = p_curr_to_id
      AND er.curr_to_id = p_curr_from_id
      AND er.date = p_date;

    IF v_count_direct = 0 AND v_count_inverse = 0 THEN

        RAISE NOTICE 'Stan 1: Brak kursow dla pary %/%. Dodajemy oba rekordy.',
            p_curr_from_id, p_curr_to_id;

        v_inverse_rate := 1.0 / p_direct_rate;

        INSERT INTO shared."exchangeRates" (curr_from_id, curr_to_id, ex_rate, date)
        VALUES (p_curr_from_id, p_curr_to_id, p_direct_rate, p_date);

        INSERT INTO shared."exchangeRates" (curr_from_id, curr_to_id, ex_rate, date)
        VALUES (p_curr_to_id, p_curr_from_id, v_inverse_rate, p_date);

        RETURN;

    ELSIF v_count_direct = 1 AND v_count_inverse = 1 THEN
        RAISE NOTICE 'Stan 2: Kursy dla pary %/% na dzien % już sa. Pomijam.',
            p_curr_from_id, p_curr_to_id, p_date;
        RETURN;

    ELSE
        RAISE EXCEPTION 'NIESPOJNOSC DANYCH! Tabela exchangeRates jest uszkodzona dla pary %/% na dzien %. ',
            'Znaleziono % rekordów bezpośrednich i % odwrotnych. Operacja przerwana.',
            p_curr_from_id, p_curr_to_id, p_date, v_count_direct, v_count_inverse;
    END IF;
END;
$$;

