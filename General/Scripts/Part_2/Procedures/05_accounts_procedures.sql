/*
 --
 Procedura: accounts.sp_OpenAccount
 Opis: Otwiera nowe konto dla klienta
 Uwaga! problem przy migracji
 --
*/

CREATE PROCEDURE accounts.sp_OpenAccount(
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


/*
--
Procedura: accounts.sp_IssueNewCard
Opis: Dodaje (wydaje) nową kartę płatniczą i przypisuje ją
do istniejącego konta klienta.
Uwaga! Problem przy migracji
--
 */
CREATE PROCEDURE accounts.sp_IssueNewCard(
    p_account_id INT,
    p_card_type_name VARCHAR(30),
    p_number VARCHAR(19),
    p_expiry_date DATE
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_card_type_id INT;
    v_card_status_id INT;
    v_default_status_name VARCHAR(30) := 'Zablokowana';
BEGIN

    SELECT card_type_id INTO v_card_type_id
    FROM accounts.card_types
    WHERE name = p_card_type_name;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Typ karty o nazwie "%" nie istnieje.', p_card_type_name;
    END IF;

    SELECT card_status_id INTO v_card_status_id
    FROM accounts.card_statuses
    WHERE name = v_default_status_name;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'BŁĄD KONFIGURACJI: Domyślny status karty "%" nie istnieje w bazie.', v_default_status_name;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM accounts.account WHERE account_id = p_account_id) THEN
        RAISE EXCEPTION 'Konto o ID % nie istnieje.', p_account_id;
    END IF;

    IF EXISTS (SELECT 1 FROM accounts.card WHERE number = p_number) THEN
        RAISE EXCEPTION 'Karta o numerze "%" jest już zarejestrowana w systemie.', p_number;
    END IF;

    IF p_expiry_date < CURRENT_DATE THEN
        RAISE EXCEPTION 'Nie można wydac karty. Podana data ważności (%) juz minela.', p_expiry_date;
    END IF;

    INSERT INTO accounts.card (
        account_id,
        card_type_id,
        card_status_id,
        number,
        expiry_date
    )
    VALUES (
        p_account_id,
        v_card_type_id,
        v_card_status_id,
        p_number,
        p_expiry_date
    );

    RAISE NOTICE 'Pomyślnie wydano nową kartę (Typ: %) dla konta ID %. Karta oczekuje na aktywację.',
        p_card_type_name, p_account_id;

END;
$$;