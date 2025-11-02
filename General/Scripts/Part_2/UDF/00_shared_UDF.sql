-- problematyczny przy migracji (z powodu plpgsql)
-- udf do konwersji walut
-- udf dostepny dla wszystkich
CREATE FUNCTION shared.fn_convert_currency(
    p_amount DECIMAL(12, 2),
    p_curr_from_id INT,
    p_curr_to_id INT,
    p_rate_date DATE
)
RETURNS DECIMAL(12, 2)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER -- potrzebna do chwilowego podniesienia uprawnien
AS $$
DECLARE
    v_rate DECIMAL(10, 6);
BEGIN
    IF p_curr_from_id = p_curr_to_id THEN
        RETURN p_amount;
    END IF;

-- Znajdź najnowszy kurs BEZPOŚREDNI (na dzień p_rate_date lub wcześniej)
    SELECT ex_rate INTO v_rate
    FROM shared."exchangeRates" er
    WHERE er.curr_from_id = p_curr_from_id
      AND er.curr_to_id = p_curr_to_id
      AND er.date <= p_rate_date
    ORDER BY er.date DESC
    LIMIT 1;

    IF FOUND THEN
        RETURN ROUND(p_amount * v_rate, 2);
    END IF;

    -- Jeśli nie ma kursu bezpośredniego, znajdź najnowszy kurs ODWROTNY
    SELECT (1.0 / er.ex_rate) INTO v_rate
    FROM shared."exchangeRates" er
    WHERE er.curr_from_id = p_curr_to_id
      AND er.curr_to_id = p_curr_from_id
      AND er.date <= p_rate_date
    ORDER BY er.date DESC
    LIMIT 1;

    IF FOUND THEN
        RETURN ROUND(p_amount * v_rate, 2);
    END IF;

    -- if there is still no exchange, abend
    RAISE EXCEPTION 'Brak zdefiniowanego kursu wymiany';
END;
$$;