-- sp - stored procedure
/*
  --
  Procedura sp_AddCurrency
  Opis: Dodaje nową walutę do tabeli slownikowej 'currency'.
  Sprawdza unikalnosc symbolu i nazwy
  Uwaga: Problemy przy migracji
  --
 */
CREATE PROCEDURE shared.sp_add_currency(
    p_symbol CHAR(3),
    p_name VARCHAR(34)
)
LANGUAGE plpgsql
AS $$
BEGIN

    IF EXISTS (SELECT 1 FROM shared.currency
                    WHERE symbol = p_symbol) THEN
        RAISE EXCEPTION 'Waluta o symbolu "%" juz istnieje.', p_symbol;
    END IF;

    IF EXISTS (SELECT 1 FROM shared.currency
                    WHERE name = p_name) THEN
        RAISE EXCEPTION 'Waluta o nazwie "%" juz istnieje.', p_name;
    END IF;

    INSERT INTO shared.currency (symbol, name)
    VALUES (p_symbol, p_name);

    RAISE NOTICE 'Umieszczono nowa walute: % (%)', p_name, p_symbol;
END;
$$;

REVOKE EXECUTE ON PROCEDURE shared.sp_add_currency FROM PUBLIC;

GRANT EXECUTE ON PROCEDURE shared.sp_add_currency TO employee_role, oliwier, admin_role;