/*
--
Procedura: transactions.sp_CreateDomesticTransfer
Opis: Tworzy przelew krajowy.
- Jeśli konto odbiorcy jest w naszym banku, wykonuje
przelew wewnętrzny (z ewentualnym przewalutowaniem).
- Jeśli konta odbiorcy nie ma w naszym banku, wykonuje
przelew zewnętrzny (obciąża nadawcę i loguje transakcję).
Uwaga! Problemy przy migracji przez plpgsql
--
*/
CREATE PROCEDURE transactions.sp_CreateDomesticTransfer(
    IN p_sender_account_id INTEGER,
    IN p_receiver_account_number VARCHAR(34),
    IN p_amount DECIMAL(12, 2),
    IN p_description TEXT,
    IN p_counterparty_name VARCHAR(100),
    IN p_transaction_type_id INTEGER
)
LANGUAGE plpgsql
AS $$
DECLARE
    -- Dane nadawcy
    v_sender_balance DECIMAL(12, 2);
    v_sender_currency_id INTEGER;

    -- Dane odbiorcy
    v_receiver_account_id INTEGER;
    v_receiver_currency_id INTEGER;
    v_receiver_amount DECIMAL(12, 2);

    -- ID słownikowe
    v_status_completed_id INTEGER;
    v_status_pending_id INTEGER;

    -- Dane do logowania
    v_exchange_id INTEGER := NULL;

BEGIN
    -- Pobranie ID statusów
    SELECT transaction_status_id INTO v_status_completed_id
    FROM transactions.transaction_statuses WHERE name = 'Zakończona' LIMIT 1;

    SELECT transaction_status_id INTO v_status_pending_id
    FROM transactions.transaction_statuses WHERE name = 'W toku' LIMIT 1;

    IF v_status_completed_id IS NULL OR v_status_pending_id IS NULL THEN
        RAISE EXCEPTION 'Krytyczny błąd: Nie zdefiniowano statusów transakcji (Zakończona/w toku).';
    END IF;

    -- 1. Walidacja kwoty
    IF p_amount <= 0 THEN
        RAISE EXCEPTION 'Kwota przelewu musi być dodatnia (%).', p_amount;
    END IF;

    SELECT
        balance, currency_id
    INTO
        v_sender_balance, v_sender_currency_id
    FROM accounts.account
    WHERE account_id = p_sender_account_id
    FOR UPDATE; -- Kluczowy element blokady

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Konto nadawcy (ID: %) nie istnieje.', p_sender_account_id;
    END IF;

    -- Sprawdzenie salda nadawcy
    IF v_sender_balance < p_amount THEN
        RAISE EXCEPTION 'Niewystarczające środki na koncie nadawcy (ID: %). Wymagane: %, Dostępne: %',
            p_sender_account_id, p_amount, v_sender_balance;
    END IF;

    -- Identyfikacja odbiorcy: Wewnętrzny czy Zewnętrzny?
    SELECT
        account_id, currency_id
    INTO
        v_receiver_account_id, v_receiver_currency_id
    FROM accounts.account
    WHERE number = p_receiver_account_number;

    IF v_receiver_account_id IS NOT NULL THEN

        -- Sprawdzenie przelewu na to samo konto
        IF v_receiver_account_id = p_sender_account_id THEN
            RAISE EXCEPTION 'Nie można wykonać przelewu na to samo konto (ID: %).', p_sender_account_id;
        END IF;

        -- 5A. Logika przewalutowania
        IF v_sender_currency_id = v_receiver_currency_id THEN
            v_receiver_amount := p_amount;
            v_exchange_id := NULL;
        ELSE
            v_receiver_amount := shared.fn_convertcurrency(p_amount, v_sender_currency_id, v_receiver_currency_id, CURRENT_DATE);

            -- Pobieramy ID kursu do logów (używając tej samej logiki co fn_ConvertCurrency)
            SELECT ex_rate_id
            INTO v_exchange_id
            FROM shared."exchangeRates"
            WHERE curr_from_id = v_sender_currency_id
              AND curr_to_id = v_receiver_currency_id
              AND date <= CURRENT_DATE
            ORDER BY
              date DESC,
              ex_rate_id DESC
            LIMIT 1;
        END IF;

        -- 6A. Wykonanie transakcji (Debet i Kredyt)

        -- Obciążenie nadawcy
        UPDATE accounts.account
        SET balance = balance - p_amount
        WHERE account_id = p_sender_account_id;

        -- Uznanie odbiorcy
        UPDATE accounts.account
        SET balance = balance + v_receiver_amount
        WHERE account_id = v_receiver_account_id;

        -- 7A. Logowanie transakcji (jako Zakończona)
        INSERT INTO transactions.transaction (
            sender_account_id, receiver_account_id, card_id, exchange_id,
            transaction_type_id, transaction_status_id, amount,
            time, description
        )
        VALUES (
            p_sender_account_id, v_receiver_account_id, NULL, v_exchange_id,
            p_transaction_type_id, v_status_completed_id, p_amount,
            NOW(), p_description
        );

    ELSE
        IF p_counterparty_name IS NULL OR p_counterparty_name = '' THEN
            RAISE EXCEPTION 'Nazwa kontrahenta (odbiorcy) jest wymagana przy przelewach zewnętrznych.';
        END IF;


        UPDATE accounts.account
        SET balance = balance - p_amount
        WHERE account_id = p_sender_account_id;

        INSERT INTO transactions.transaction (
            sender_account_id, receiver_account_id, card_id, exchange_id,
            transaction_type_id, transaction_status_id, amount,
            time, description, counterparty_name, counterparty_acc_num
        )
        VALUES (
            p_sender_account_id, NULL, NULL, NULL, -- Kluczowe: receiver_account_id i exchange_id są NULL
            p_transaction_type_id, v_status_pending_id, p_amount,
            NOW(), p_description, p_counterparty_name, p_receiver_account_number
        );

    END IF;

END;
$$;