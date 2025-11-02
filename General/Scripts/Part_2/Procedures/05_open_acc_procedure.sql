/*
 --
 Procedura: accounts.sp_OpenAccount
 Opis: Otwiera nowe konto dla klienta
 Uwaga! problem przy migracji
 --
*/

CREATE PROCEDURE accounts.sp_open_account(
    p_client_id INT,
    p_currency_symbol CHAR(3),
    p_account_type_name VARCHAR(30),
    p_number VARCHAR(34),
    p_initial_balance DECIMAL(12, 2) DEFAULT 0.00
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_currency_id INT;
    v_account_type_id INT;
BEGIN

    SELECT currency_id INTO v_currency_id
    FROM shared.currency
    WHERE symbol = p_currency_symbol;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Waluta o symbolu "%" nie istnieje.', p_currency_symbol;
    END IF;

    SELECT account_type_id INTO v_account_type_id
    FROM accounts.account_types
    WHERE name = p_account_type_name;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Typ konta o nazwie "%" nie istnieje.', p_account_type_name;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM parties.client WHERE client_id = p_client_id) THEN
        RAISE EXCEPTION 'Klient o ID % nie istnieje.', p_client_id;
    END IF;

    IF EXISTS (SELECT 1 FROM accounts.account WHERE number = p_number) THEN
        RAISE EXCEPTION 'Numer konta "%" jest już zajęty.', p_number;
    END IF;


    INSERT INTO accounts.account (client_id, currency_id, account_type_id, number, balance)
    VALUES (p_client_id, v_currency_id, v_account_type_id, p_number, p_initial_balance);

    RAISE NOTICE 'Pomyślnie utworzono konto % (%) dla klienta ID %.',
        p_number, p_account_type_name, p_client_id;

END;
$$;

REVOKE EXECUTE ON PROCEDURE accounts.sp_open_account FROM PUBLIC;

GRANT EXECUTE ON PROCEDURE accounts.sp_open_account TO employee_role, admin_role, oliwier;