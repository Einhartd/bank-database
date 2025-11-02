--
-- PostgreSQL database dump
--

\restrict 0OzkYLgFTRWcwjaZOfsvg2Fr8QpEbsib8gqPdMSw3XcpIxgDoZ9CtwgYypFKj61

-- Dumped from database version 16.10 (Ubuntu 16.10-0ubuntu0.24.04.1)
-- Dumped by pg_dump version 16.10 (Ubuntu 16.10-0ubuntu0.24.04.1)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: accounts; Type: SCHEMA; Schema: -; Owner: oliwier
--

CREATE SCHEMA accounts;


ALTER SCHEMA accounts OWNER TO oliwier;

--
-- Name: loans; Type: SCHEMA; Schema: -; Owner: oliwier
--

CREATE SCHEMA loans;


ALTER SCHEMA loans OWNER TO oliwier;

--
-- Name: parties; Type: SCHEMA; Schema: -; Owner: oliwier
--

CREATE SCHEMA parties;


ALTER SCHEMA parties OWNER TO oliwier;

--
-- Name: security; Type: SCHEMA; Schema: -; Owner: oliwier
--

CREATE SCHEMA security;


ALTER SCHEMA security OWNER TO oliwier;

--
-- Name: shared; Type: SCHEMA; Schema: -; Owner: oliwier
--

CREATE SCHEMA shared;


ALTER SCHEMA shared OWNER TO oliwier;

--
-- Name: transactions; Type: SCHEMA; Schema: -; Owner: oliwier
--

CREATE SCHEMA transactions;


ALTER SCHEMA transactions OWNER TO oliwier;

--
-- Name: fn_check_account_empty(); Type: FUNCTION; Schema: accounts; Owner: oliwier
--

CREATE FUNCTION accounts.fn_check_account_empty() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN

    IF OLD.balance != 0.00 THEN

        RAISE EXCEPTION 'Błąd: Saldo konta (ID: %) nie wynosi 0 (%). Nie mozna usunac konta.',
                         OLD.account_id, OLD.balance;
    END IF;

    RETURN OLD;
END;
$$;


ALTER FUNCTION accounts.fn_check_account_empty() OWNER TO oliwier;

--
-- Name: fn_check_balance_not_negative(); Type: FUNCTION; Schema: accounts; Owner: oliwier
--

CREATE FUNCTION accounts.fn_check_balance_not_negative() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN

    IF NEW.balance < 0.00 THEN

        RAISE EXCEPTION 'Błąd: Saldo konta (ID: %) nie może być ujemne. Próba ustawienia na %.',
                         NEW.account_id, NEW.balance;
    END IF;

    RETURN NEW;
END;
$$;


ALTER FUNCTION accounts.fn_check_balance_not_negative() OWNER TO oliwier;

--
-- Name: fn_get_client_total_balance(integer, integer, date); Type: FUNCTION; Schema: accounts; Owner: oliwier
--

CREATE FUNCTION accounts.fn_get_client_total_balance(p_client_id integer, p_target_currency_id integer, p_calculation_date date) RETURNS numeric
    LANGUAGE sql STABLE
    AS $$
    SELECT COALESCE(
                SUM(
                    shared.fn_convert_currency(
                    a.balance,
                    a.currency_id,
                    p_target_currency_id,
                    p_calculation_date
                    )
                ),
                0.00)
    FROM
        accounts.account a
    WHERE
        a.client_id = p_client_id;
$$;


ALTER FUNCTION accounts.fn_get_client_total_balance(p_client_id integer, p_target_currency_id integer, p_calculation_date date) OWNER TO oliwier;

--
-- Name: fn_get_my_total_balance(integer, date); Type: FUNCTION; Schema: accounts; Owner: oliwier
--

CREATE FUNCTION accounts.fn_get_my_total_balance(p_target_currency_id integer, p_calculation_date date) RETURNS numeric
    LANGUAGE sql STABLE
    AS $$
    SELECT COALESCE(
                SUM(
                    shared.fn_convert_currency(
                        v.balance,
                        v.currency_id,
                        p_target_currency_id,
                        p_calculation_date
                    )
                ),
                0.00)
    FROM
        accounts.view_client_accounts v;
$$;


ALTER FUNCTION accounts.fn_get_my_total_balance(p_target_currency_id integer, p_calculation_date date) OWNER TO oliwier;

--
-- Name: sp_issue_new_card(integer, character varying, character varying, date); Type: PROCEDURE; Schema: accounts; Owner: oliwier
--

CREATE PROCEDURE accounts.sp_issue_new_card(IN p_account_id integer, IN p_card_type_name character varying, IN p_number character varying, IN p_expiry_date date)
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


ALTER PROCEDURE accounts.sp_issue_new_card(IN p_account_id integer, IN p_card_type_name character varying, IN p_number character varying, IN p_expiry_date date) OWNER TO oliwier;

--
-- Name: sp_open_account(integer, character, character varying, character varying, numeric); Type: PROCEDURE; Schema: accounts; Owner: oliwier
--

CREATE PROCEDURE accounts.sp_open_account(IN p_client_id integer, IN p_currency_symbol character, IN p_account_type_name character varying, IN p_number character varying, IN p_initial_balance numeric DEFAULT 0.00)
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


ALTER PROCEDURE accounts.sp_open_account(IN p_client_id integer, IN p_currency_symbol character, IN p_account_type_name character varying, IN p_number character varying, IN p_initial_balance numeric) OWNER TO oliwier;

--
-- Name: sp_add_new_employee(character varying, character varying, character varying); Type: PROCEDURE; Schema: parties; Owner: oliwier
--

CREATE PROCEDURE parties.sp_add_new_employee(IN p_name character varying, IN p_surname character varying, IN p_position_name character varying)
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_position_id INT;
BEGIN
    SELECT position_id INTO v_position_id
    FROM parties.positions
    WHERE name = p_position_name;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Nie można dodac pracownika. Stanowisko o nazwie "%" nie istnieje.', p_position_name;
    END IF;

    INSERT INTO parties.employee (name, surname, position_id)
    VALUES (p_name, p_surname, v_position_id);

    RAISE NOTICE 'Pomyslnie dodano pracownika: % % (Stanowisko: %)', p_name, p_surname, p_position_name;
END;
$$;


ALTER PROCEDURE parties.sp_add_new_employee(IN p_name character varying, IN p_surname character varying, IN p_position_name character varying) OWNER TO oliwier;

--
-- Name: fn_convert_currency(numeric, integer, integer, date); Type: FUNCTION; Schema: shared; Owner: oliwier
--

CREATE FUNCTION shared.fn_convert_currency(p_amount numeric, p_curr_from_id integer, p_curr_to_id integer, p_rate_date date) RETURNS numeric
    LANGUAGE plpgsql STABLE SECURITY DEFINER
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


ALTER FUNCTION shared.fn_convert_currency(p_amount numeric, p_curr_from_id integer, p_curr_to_id integer, p_rate_date date) OWNER TO oliwier;

--
-- Name: sp_add_currency(character, character varying); Type: PROCEDURE; Schema: shared; Owner: oliwier
--

CREATE PROCEDURE shared.sp_add_currency(IN p_symbol character, IN p_name character varying)
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


ALTER PROCEDURE shared.sp_add_currency(IN p_symbol character, IN p_name character varying) OWNER TO oliwier;

--
-- Name: sp_add_symmetrical_exchange_rate(character, character, numeric, date); Type: PROCEDURE; Schema: shared; Owner: oliwier
--

CREATE PROCEDURE shared.sp_add_symmetrical_exchange_rate(IN p_symbol_from character, IN p_symbol_to character, IN p_direct_rate numeric, IN p_date date)
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


ALTER PROCEDURE shared.sp_add_symmetrical_exchange_rate(IN p_symbol_from character, IN p_symbol_to character, IN p_direct_rate numeric, IN p_date date) OWNER TO oliwier;

--
-- Name: sp_create_domestic_transfer(integer, character varying, numeric, text, character varying, integer); Type: PROCEDURE; Schema: transactions; Owner: oliwier
--

CREATE PROCEDURE transactions.sp_create_domestic_transfer(IN p_sender_account_id integer, IN p_receiver_account_number character varying, IN p_amount numeric, IN p_description text, IN p_counterparty_name character varying, IN p_transaction_type_id integer)
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
            v_receiver_amount := shared.fn_convert_currency(p_amount, v_sender_currency_id, v_receiver_currency_id, CURRENT_DATE);

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


ALTER PROCEDURE transactions.sp_create_domestic_transfer(IN p_sender_account_id integer, IN p_receiver_account_number character varying, IN p_amount numeric, IN p_description text, IN p_counterparty_name character varying, IN p_transaction_type_id integer) OWNER TO oliwier;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: account; Type: TABLE; Schema: accounts; Owner: oliwier
--

CREATE TABLE accounts.account (
    account_id integer NOT NULL,
    client_id integer NOT NULL,
    currency_id integer NOT NULL,
    account_type_id integer NOT NULL,
    number character varying(34) NOT NULL,
    balance numeric(12,2) NOT NULL
);


ALTER TABLE accounts.account OWNER TO oliwier;

--
-- Name: account_account_id_seq; Type: SEQUENCE; Schema: accounts; Owner: oliwier
--

CREATE SEQUENCE accounts.account_account_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE accounts.account_account_id_seq OWNER TO oliwier;

--
-- Name: account_account_id_seq; Type: SEQUENCE OWNED BY; Schema: accounts; Owner: oliwier
--

ALTER SEQUENCE accounts.account_account_id_seq OWNED BY accounts.account.account_id;


--
-- Name: account_types; Type: TABLE; Schema: accounts; Owner: oliwier
--

CREATE TABLE accounts.account_types (
    account_type_id integer NOT NULL,
    name character varying(30) NOT NULL
);


ALTER TABLE accounts.account_types OWNER TO oliwier;

--
-- Name: account_types_account_type_id_seq; Type: SEQUENCE; Schema: accounts; Owner: oliwier
--

CREATE SEQUENCE accounts.account_types_account_type_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE accounts.account_types_account_type_id_seq OWNER TO oliwier;

--
-- Name: account_types_account_type_id_seq; Type: SEQUENCE OWNED BY; Schema: accounts; Owner: oliwier
--

ALTER SEQUENCE accounts.account_types_account_type_id_seq OWNED BY accounts.account_types.account_type_id;


--
-- Name: card; Type: TABLE; Schema: accounts; Owner: oliwier
--

CREATE TABLE accounts.card (
    card_id integer NOT NULL,
    account_id integer NOT NULL,
    card_type_id integer NOT NULL,
    card_status_id integer NOT NULL,
    number character varying(19) NOT NULL,
    expiry_date date NOT NULL
);


ALTER TABLE accounts.card OWNER TO oliwier;

--
-- Name: card_card_id_seq; Type: SEQUENCE; Schema: accounts; Owner: oliwier
--

CREATE SEQUENCE accounts.card_card_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE accounts.card_card_id_seq OWNER TO oliwier;

--
-- Name: card_card_id_seq; Type: SEQUENCE OWNED BY; Schema: accounts; Owner: oliwier
--

ALTER SEQUENCE accounts.card_card_id_seq OWNED BY accounts.card.card_id;


--
-- Name: card_statuses; Type: TABLE; Schema: accounts; Owner: oliwier
--

CREATE TABLE accounts.card_statuses (
    card_status_id integer NOT NULL,
    name character varying(30) NOT NULL
);


ALTER TABLE accounts.card_statuses OWNER TO oliwier;

--
-- Name: card_statuses_card_status_id_seq; Type: SEQUENCE; Schema: accounts; Owner: oliwier
--

CREATE SEQUENCE accounts.card_statuses_card_status_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE accounts.card_statuses_card_status_id_seq OWNER TO oliwier;

--
-- Name: card_statuses_card_status_id_seq; Type: SEQUENCE OWNED BY; Schema: accounts; Owner: oliwier
--

ALTER SEQUENCE accounts.card_statuses_card_status_id_seq OWNED BY accounts.card_statuses.card_status_id;


--
-- Name: card_types; Type: TABLE; Schema: accounts; Owner: oliwier
--

CREATE TABLE accounts.card_types (
    card_type_id integer NOT NULL,
    name character varying(30) NOT NULL
);


ALTER TABLE accounts.card_types OWNER TO oliwier;

--
-- Name: card_types_card_type_id_seq; Type: SEQUENCE; Schema: accounts; Owner: oliwier
--

CREATE SEQUENCE accounts.card_types_card_type_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE accounts.card_types_card_type_id_seq OWNER TO oliwier;

--
-- Name: card_types_card_type_id_seq; Type: SEQUENCE OWNED BY; Schema: accounts; Owner: oliwier
--

ALTER SEQUENCE accounts.card_types_card_type_id_seq OWNED BY accounts.card_types.card_type_id;


--
-- Name: user; Type: TABLE; Schema: security; Owner: oliwier
--

CREATE TABLE security."user" (
    user_id integer NOT NULL,
    employee_id integer,
    client_id integer,
    login character varying(20) NOT NULL,
    password character varying(60) NOT NULL,
    CONSTRAINT chk_user_role CHECK ((((employee_id IS NOT NULL) AND (client_id IS NULL)) OR ((employee_id IS NULL) AND (client_id IS NOT NULL))))
);


ALTER TABLE security."user" OWNER TO oliwier;

--
-- Name: currency; Type: TABLE; Schema: shared; Owner: oliwier
--

CREATE TABLE shared.currency (
    currency_id integer NOT NULL,
    symbol character(3) NOT NULL,
    name character varying(34) NOT NULL
);


ALTER TABLE shared.currency OWNER TO oliwier;

--
-- Name: view_client_accounts; Type: VIEW; Schema: accounts; Owner: oliwier
--

CREATE VIEW accounts.view_client_accounts AS
 SELECT a.account_id,
    a.number,
    a.balance,
    c.symbol AS currency,
    at.name AS account_type,
    a.client_id,
    a.currency_id
   FROM ((accounts.account a
     JOIN shared.currency c ON ((a.currency_id = c.currency_id)))
     JOIN accounts.account_types at ON ((a.account_type_id = at.account_type_id)))
  WHERE (a.client_id = ( SELECT "user".client_id
           FROM security."user"
          WHERE (("user".login)::text = CURRENT_USER)));


ALTER VIEW accounts.view_client_accounts OWNER TO oliwier;

--
-- Name: view_client_cards; Type: VIEW; Schema: accounts; Owner: oliwier
--

CREATE VIEW accounts.view_client_cards AS
 SELECT a_card.card_id,
    a_card.number,
    a_card.expiry_date,
    ct.name AS card_type,
    cs.name AS card_status
   FROM (((accounts.card a_card
     JOIN accounts.view_client_accounts client_acc ON ((a_card.account_id = client_acc.account_id)))
     JOIN accounts.card_types ct ON ((a_card.card_type_id = ct.card_type_id)))
     JOIN accounts.card_statuses cs ON ((a_card.card_status_id = cs.card_status_id)));


ALTER VIEW accounts.view_client_cards OWNER TO oliwier;

--
-- Name: loan; Type: TABLE; Schema: loans; Owner: oliwier
--

CREATE TABLE loans.loan (
    loan_id integer NOT NULL,
    client_id integer NOT NULL,
    loan_status_id integer NOT NULL,
    employee_id integer NOT NULL,
    amount numeric(12,2) NOT NULL,
    interest_rate numeric(5,2) NOT NULL,
    start_date date NOT NULL
);


ALTER TABLE loans.loan OWNER TO oliwier;

--
-- Name: loan_loan_id_seq; Type: SEQUENCE; Schema: loans; Owner: oliwier
--

CREATE SEQUENCE loans.loan_loan_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE loans.loan_loan_id_seq OWNER TO oliwier;

--
-- Name: loan_loan_id_seq; Type: SEQUENCE OWNED BY; Schema: loans; Owner: oliwier
--

ALTER SEQUENCE loans.loan_loan_id_seq OWNED BY loans.loan.loan_id;


--
-- Name: loan_statuses; Type: TABLE; Schema: loans; Owner: oliwier
--

CREATE TABLE loans.loan_statuses (
    loan_status_id integer NOT NULL,
    name character varying(30) NOT NULL
);


ALTER TABLE loans.loan_statuses OWNER TO oliwier;

--
-- Name: loan_statuses_loan_status_id_seq; Type: SEQUENCE; Schema: loans; Owner: oliwier
--

CREATE SEQUENCE loans.loan_statuses_loan_status_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE loans.loan_statuses_loan_status_id_seq OWNER TO oliwier;

--
-- Name: loan_statuses_loan_status_id_seq; Type: SEQUENCE OWNED BY; Schema: loans; Owner: oliwier
--

ALTER SEQUENCE loans.loan_statuses_loan_status_id_seq OWNED BY loans.loan_statuses.loan_status_id;


--
-- Name: view_client_loans; Type: VIEW; Schema: loans; Owner: oliwier
--

CREATE VIEW loans.view_client_loans AS
 SELECT ll.loan_id,
    ll.amount,
    ll.interest_rate,
    ll.start_date,
    ls.name AS loan_status
   FROM (loans.loan ll
     JOIN loans.loan_statuses ls ON ((ll.loan_status_id = ls.loan_status_id)))
  WHERE (ll.client_id = ( SELECT "user".client_id
           FROM security."user"
          WHERE (("user".login)::text = CURRENT_USER)));


ALTER VIEW loans.view_client_loans OWNER TO oliwier;

--
-- Name: client; Type: TABLE; Schema: parties; Owner: oliwier
--

CREATE TABLE parties.client (
    client_id integer NOT NULL,
    name character varying(20) NOT NULL,
    surname character varying(60) NOT NULL,
    pesel character(11) NOT NULL,
    email character varying(80) NOT NULL
);


ALTER TABLE parties.client OWNER TO oliwier;

--
-- Name: client_client_id_seq; Type: SEQUENCE; Schema: parties; Owner: oliwier
--

CREATE SEQUENCE parties.client_client_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE parties.client_client_id_seq OWNER TO oliwier;

--
-- Name: client_client_id_seq; Type: SEQUENCE OWNED BY; Schema: parties; Owner: oliwier
--

ALTER SEQUENCE parties.client_client_id_seq OWNED BY parties.client.client_id;


--
-- Name: employee; Type: TABLE; Schema: parties; Owner: oliwier
--

CREATE TABLE parties.employee (
    employee_id integer NOT NULL,
    position_id integer NOT NULL,
    name character varying(20) NOT NULL,
    surname character varying(60) NOT NULL
);


ALTER TABLE parties.employee OWNER TO oliwier;

--
-- Name: employee_employee_id_seq; Type: SEQUENCE; Schema: parties; Owner: oliwier
--

CREATE SEQUENCE parties.employee_employee_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE parties.employee_employee_id_seq OWNER TO oliwier;

--
-- Name: employee_employee_id_seq; Type: SEQUENCE OWNED BY; Schema: parties; Owner: oliwier
--

ALTER SEQUENCE parties.employee_employee_id_seq OWNED BY parties.employee.employee_id;


--
-- Name: positions; Type: TABLE; Schema: parties; Owner: oliwier
--

CREATE TABLE parties.positions (
    position_id integer NOT NULL,
    name character varying(30) NOT NULL
);


ALTER TABLE parties.positions OWNER TO oliwier;

--
-- Name: positions_position_id_seq; Type: SEQUENCE; Schema: parties; Owner: oliwier
--

CREATE SEQUENCE parties.positions_position_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE parties.positions_position_id_seq OWNER TO oliwier;

--
-- Name: positions_position_id_seq; Type: SEQUENCE OWNED BY; Schema: parties; Owner: oliwier
--

ALTER SEQUENCE parties.positions_position_id_seq OWNED BY parties.positions.position_id;


--
-- Name: view_client_profile; Type: VIEW; Schema: parties; Owner: oliwier
--

CREATE VIEW parties.view_client_profile AS
 SELECT client_id,
    name,
    surname,
    pesel,
    email
   FROM parties.client
  WHERE (client_id = ( SELECT "user".client_id
           FROM security."user"
          WHERE (("user".login)::text = CURRENT_USER)));


ALTER VIEW parties.view_client_profile OWNER TO oliwier;

--
-- Name: loginHistory; Type: TABLE; Schema: security; Owner: oliwier
--

CREATE TABLE security."loginHistory" (
    login_id integer NOT NULL,
    user_id integer NOT NULL,
    action_type_id integer NOT NULL,
    login_time timestamp without time zone NOT NULL,
    ip_adres character varying(45) NOT NULL
);


ALTER TABLE security."loginHistory" OWNER TO oliwier;

--
-- Name: loginHistory_login_id_seq; Type: SEQUENCE; Schema: security; Owner: oliwier
--

CREATE SEQUENCE security."loginHistory_login_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE security."loginHistory_login_id_seq" OWNER TO oliwier;

--
-- Name: loginHistory_login_id_seq; Type: SEQUENCE OWNED BY; Schema: security; Owner: oliwier
--

ALTER SEQUENCE security."loginHistory_login_id_seq" OWNED BY security."loginHistory".login_id;


--
-- Name: login_action_types; Type: TABLE; Schema: security; Owner: oliwier
--

CREATE TABLE security.login_action_types (
    action_type_id integer NOT NULL,
    name character varying(30) NOT NULL
);


ALTER TABLE security.login_action_types OWNER TO oliwier;

--
-- Name: login_action_types_action_type_id_seq; Type: SEQUENCE; Schema: security; Owner: oliwier
--

CREATE SEQUENCE security.login_action_types_action_type_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE security.login_action_types_action_type_id_seq OWNER TO oliwier;

--
-- Name: login_action_types_action_type_id_seq; Type: SEQUENCE OWNED BY; Schema: security; Owner: oliwier
--

ALTER SEQUENCE security.login_action_types_action_type_id_seq OWNED BY security.login_action_types.action_type_id;


--
-- Name: user_user_id_seq; Type: SEQUENCE; Schema: security; Owner: oliwier
--

CREATE SEQUENCE security.user_user_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE security.user_user_id_seq OWNER TO oliwier;

--
-- Name: user_user_id_seq; Type: SEQUENCE OWNED BY; Schema: security; Owner: oliwier
--

ALTER SEQUENCE security.user_user_id_seq OWNED BY security."user".user_id;


--
-- Name: currency_currency_id_seq; Type: SEQUENCE; Schema: shared; Owner: oliwier
--

CREATE SEQUENCE shared.currency_currency_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE shared.currency_currency_id_seq OWNER TO oliwier;

--
-- Name: currency_currency_id_seq; Type: SEQUENCE OWNED BY; Schema: shared; Owner: oliwier
--

ALTER SEQUENCE shared.currency_currency_id_seq OWNED BY shared.currency.currency_id;


--
-- Name: exchangeRates; Type: TABLE; Schema: shared; Owner: oliwier
--

CREATE TABLE shared."exchangeRates" (
    ex_rate_id integer NOT NULL,
    curr_from_id integer NOT NULL,
    curr_to_id integer NOT NULL,
    ex_rate numeric(10,6) NOT NULL,
    date date NOT NULL
);


ALTER TABLE shared."exchangeRates" OWNER TO oliwier;

--
-- Name: exchangeRates_ex_rate_id_seq; Type: SEQUENCE; Schema: shared; Owner: oliwier
--

CREATE SEQUENCE shared."exchangeRates_ex_rate_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE shared."exchangeRates_ex_rate_id_seq" OWNER TO oliwier;

--
-- Name: exchangeRates_ex_rate_id_seq; Type: SEQUENCE OWNED BY; Schema: shared; Owner: oliwier
--

ALTER SEQUENCE shared."exchangeRates_ex_rate_id_seq" OWNED BY shared."exchangeRates".ex_rate_id;


--
-- Name: transaction; Type: TABLE; Schema: transactions; Owner: oliwier
--

CREATE TABLE transactions.transaction (
    transaction_id integer NOT NULL,
    sender_account_id integer,
    receiver_account_id integer,
    card_id integer,
    exchange_id integer,
    transaction_type_id integer NOT NULL,
    transaction_status_id integer NOT NULL,
    amount numeric(12,2) NOT NULL,
    "time" timestamp without time zone NOT NULL,
    description text,
    counterparty_name character varying(100),
    counterparty_acc_num character varying(34)
);


ALTER TABLE transactions.transaction OWNER TO oliwier;

--
-- Name: transaction_statuses; Type: TABLE; Schema: transactions; Owner: oliwier
--

CREATE TABLE transactions.transaction_statuses (
    transaction_status_id integer NOT NULL,
    name character varying(30) NOT NULL
);


ALTER TABLE transactions.transaction_statuses OWNER TO oliwier;

--
-- Name: transaction_statuses_transaction_status_id_seq; Type: SEQUENCE; Schema: transactions; Owner: oliwier
--

CREATE SEQUENCE transactions.transaction_statuses_transaction_status_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE transactions.transaction_statuses_transaction_status_id_seq OWNER TO oliwier;

--
-- Name: transaction_statuses_transaction_status_id_seq; Type: SEQUENCE OWNED BY; Schema: transactions; Owner: oliwier
--

ALTER SEQUENCE transactions.transaction_statuses_transaction_status_id_seq OWNED BY transactions.transaction_statuses.transaction_status_id;


--
-- Name: transaction_transaction_id_seq; Type: SEQUENCE; Schema: transactions; Owner: oliwier
--

CREATE SEQUENCE transactions.transaction_transaction_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE transactions.transaction_transaction_id_seq OWNER TO oliwier;

--
-- Name: transaction_transaction_id_seq; Type: SEQUENCE OWNED BY; Schema: transactions; Owner: oliwier
--

ALTER SEQUENCE transactions.transaction_transaction_id_seq OWNED BY transactions.transaction.transaction_id;


--
-- Name: transaction_types; Type: TABLE; Schema: transactions; Owner: oliwier
--

CREATE TABLE transactions.transaction_types (
    transaction_type_id integer NOT NULL,
    name character varying(30) NOT NULL
);


ALTER TABLE transactions.transaction_types OWNER TO oliwier;

--
-- Name: transaction_types_transaction_type_id_seq; Type: SEQUENCE; Schema: transactions; Owner: oliwier
--

CREATE SEQUENCE transactions.transaction_types_transaction_type_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE transactions.transaction_types_transaction_type_id_seq OWNER TO oliwier;

--
-- Name: transaction_types_transaction_type_id_seq; Type: SEQUENCE OWNED BY; Schema: transactions; Owner: oliwier
--

ALTER SEQUENCE transactions.transaction_types_transaction_type_id_seq OWNED BY transactions.transaction_types.transaction_type_id;


--
-- Name: view_client_card_payments; Type: VIEW; Schema: transactions; Owner: oliwier
--

CREATE VIEW transactions.view_client_card_payments AS
 SELECT t.transaction_id,
    t.amount,
    t."time",
    c.number AS card_number,
    t.description,
    t.counterparty_name,
    tt.name AS transaction_type,
    ts.name AS transaction_status
   FROM (((transactions.transaction t
     JOIN transactions.transaction_types tt ON ((t.transaction_type_id = tt.transaction_type_id)))
     JOIN transactions.transaction_statuses ts ON ((t.transaction_status_id = ts.transaction_status_id)))
     LEFT JOIN accounts.card c ON ((t.card_id = c.card_id)))
  WHERE (t.card_id IN ( SELECT view_client_cards.card_id
           FROM accounts.view_client_cards));


ALTER VIEW transactions.view_client_card_payments OWNER TO oliwier;

--
-- Name: view_client_transactions; Type: VIEW; Schema: transactions; Owner: oliwier
--

CREATE VIEW transactions.view_client_transactions AS
 SELECT t.transaction_id,
    t.amount,
    t."time",
    sender_acc.number AS sender_account_number,
    receiver_acc.number AS receiver_account_number,
    c.number AS card_number,
    ex.ex_rate AS exchange_rate,
    t.description,
    t.counterparty_name,
    t.counterparty_acc_num,
    tt.name AS transaction_type,
    ts.name AS transaction_status
   FROM ((((((transactions.transaction t
     LEFT JOIN accounts.account sender_acc ON ((t.sender_account_id = sender_acc.account_id)))
     LEFT JOIN accounts.account receiver_acc ON ((t.receiver_account_id = receiver_acc.account_id)))
     JOIN transactions.transaction_types tt ON ((t.transaction_type_id = tt.transaction_type_id)))
     JOIN transactions.transaction_statuses ts ON ((t.transaction_status_id = ts.transaction_status_id)))
     LEFT JOIN shared."exchangeRates" ex ON ((t.exchange_id = ex.ex_rate_id)))
     LEFT JOIN accounts.card c ON ((t.card_id = c.card_id)))
  WHERE ((t.sender_account_id IN ( SELECT view_client_accounts.account_id
           FROM accounts.view_client_accounts)) OR (t.receiver_account_id IN ( SELECT view_client_accounts.account_id
           FROM accounts.view_client_accounts)) OR (t.card_id IN ( SELECT view_client_cards.card_id
           FROM accounts.view_client_cards)));


ALTER VIEW transactions.view_client_transactions OWNER TO oliwier;

--
-- Name: view_client_transfers; Type: VIEW; Schema: transactions; Owner: oliwier
--

CREATE VIEW transactions.view_client_transfers AS
 SELECT t.transaction_id,
    t.amount,
    t."time",
    sender_acc.number AS sender_account_number,
    receiver_acc.number AS receiver_account_number,
    t.description,
    t.counterparty_name,
    t.counterparty_acc_num,
    tt.name AS transaction_type,
    ts.name AS transaction_status
   FROM ((((transactions.transaction t
     LEFT JOIN accounts.account sender_acc ON ((t.sender_account_id = sender_acc.account_id)))
     LEFT JOIN accounts.account receiver_acc ON ((t.receiver_account_id = receiver_acc.account_id)))
     JOIN transactions.transaction_types tt ON ((t.transaction_type_id = tt.transaction_type_id)))
     JOIN transactions.transaction_statuses ts ON ((t.transaction_status_id = ts.transaction_status_id)))
  WHERE ((t.card_id IS NULL) AND ((t.sender_account_id IN ( SELECT view_client_accounts.account_id
           FROM accounts.view_client_accounts)) OR (t.receiver_account_id IN ( SELECT view_client_accounts.account_id
           FROM accounts.view_client_accounts))));


ALTER VIEW transactions.view_client_transfers OWNER TO oliwier;

--
-- Name: account account_id; Type: DEFAULT; Schema: accounts; Owner: oliwier
--

ALTER TABLE ONLY accounts.account ALTER COLUMN account_id SET DEFAULT nextval('accounts.account_account_id_seq'::regclass);


--
-- Name: account_types account_type_id; Type: DEFAULT; Schema: accounts; Owner: oliwier
--

ALTER TABLE ONLY accounts.account_types ALTER COLUMN account_type_id SET DEFAULT nextval('accounts.account_types_account_type_id_seq'::regclass);


--
-- Name: card card_id; Type: DEFAULT; Schema: accounts; Owner: oliwier
--

ALTER TABLE ONLY accounts.card ALTER COLUMN card_id SET DEFAULT nextval('accounts.card_card_id_seq'::regclass);


--
-- Name: card_statuses card_status_id; Type: DEFAULT; Schema: accounts; Owner: oliwier
--

ALTER TABLE ONLY accounts.card_statuses ALTER COLUMN card_status_id SET DEFAULT nextval('accounts.card_statuses_card_status_id_seq'::regclass);


--
-- Name: card_types card_type_id; Type: DEFAULT; Schema: accounts; Owner: oliwier
--

ALTER TABLE ONLY accounts.card_types ALTER COLUMN card_type_id SET DEFAULT nextval('accounts.card_types_card_type_id_seq'::regclass);


--
-- Name: loan loan_id; Type: DEFAULT; Schema: loans; Owner: oliwier
--

ALTER TABLE ONLY loans.loan ALTER COLUMN loan_id SET DEFAULT nextval('loans.loan_loan_id_seq'::regclass);


--
-- Name: loan_statuses loan_status_id; Type: DEFAULT; Schema: loans; Owner: oliwier
--

ALTER TABLE ONLY loans.loan_statuses ALTER COLUMN loan_status_id SET DEFAULT nextval('loans.loan_statuses_loan_status_id_seq'::regclass);


--
-- Name: client client_id; Type: DEFAULT; Schema: parties; Owner: oliwier
--

ALTER TABLE ONLY parties.client ALTER COLUMN client_id SET DEFAULT nextval('parties.client_client_id_seq'::regclass);


--
-- Name: employee employee_id; Type: DEFAULT; Schema: parties; Owner: oliwier
--

ALTER TABLE ONLY parties.employee ALTER COLUMN employee_id SET DEFAULT nextval('parties.employee_employee_id_seq'::regclass);


--
-- Name: positions position_id; Type: DEFAULT; Schema: parties; Owner: oliwier
--

ALTER TABLE ONLY parties.positions ALTER COLUMN position_id SET DEFAULT nextval('parties.positions_position_id_seq'::regclass);


--
-- Name: loginHistory login_id; Type: DEFAULT; Schema: security; Owner: oliwier
--

ALTER TABLE ONLY security."loginHistory" ALTER COLUMN login_id SET DEFAULT nextval('security."loginHistory_login_id_seq"'::regclass);


--
-- Name: login_action_types action_type_id; Type: DEFAULT; Schema: security; Owner: oliwier
--

ALTER TABLE ONLY security.login_action_types ALTER COLUMN action_type_id SET DEFAULT nextval('security.login_action_types_action_type_id_seq'::regclass);


--
-- Name: user user_id; Type: DEFAULT; Schema: security; Owner: oliwier
--

ALTER TABLE ONLY security."user" ALTER COLUMN user_id SET DEFAULT nextval('security.user_user_id_seq'::regclass);


--
-- Name: currency currency_id; Type: DEFAULT; Schema: shared; Owner: oliwier
--

ALTER TABLE ONLY shared.currency ALTER COLUMN currency_id SET DEFAULT nextval('shared.currency_currency_id_seq'::regclass);


--
-- Name: exchangeRates ex_rate_id; Type: DEFAULT; Schema: shared; Owner: oliwier
--

ALTER TABLE ONLY shared."exchangeRates" ALTER COLUMN ex_rate_id SET DEFAULT nextval('shared."exchangeRates_ex_rate_id_seq"'::regclass);


--
-- Name: transaction transaction_id; Type: DEFAULT; Schema: transactions; Owner: oliwier
--

ALTER TABLE ONLY transactions.transaction ALTER COLUMN transaction_id SET DEFAULT nextval('transactions.transaction_transaction_id_seq'::regclass);


--
-- Name: transaction_statuses transaction_status_id; Type: DEFAULT; Schema: transactions; Owner: oliwier
--

ALTER TABLE ONLY transactions.transaction_statuses ALTER COLUMN transaction_status_id SET DEFAULT nextval('transactions.transaction_statuses_transaction_status_id_seq'::regclass);


--
-- Name: transaction_types transaction_type_id; Type: DEFAULT; Schema: transactions; Owner: oliwier
--

ALTER TABLE ONLY transactions.transaction_types ALTER COLUMN transaction_type_id SET DEFAULT nextval('transactions.transaction_types_transaction_type_id_seq'::regclass);


--
-- Data for Name: account; Type: TABLE DATA; Schema: accounts; Owner: oliwier
--

COPY accounts.account (account_id, client_id, currency_id, account_type_id, number, balance) FROM stdin;
4	4	1	2	PL24102010130000040404040404	25000.00
6	2	3	4	PL25102410130060020702020202	150.00
2	2	1	1	PL22102010130000020202020202	12345.50
5	1	2	4	PL25102010130000050505050505	700.00
1	1	1	1	PL21102010130000010101010101	5845.00
3	3	2	4	PL23102010130000030303030303	3200.00
\.


--
-- Data for Name: account_types; Type: TABLE DATA; Schema: accounts; Owner: oliwier
--

COPY accounts.account_types (account_type_id, name) FROM stdin;
1	Osobiste
2	Oszczędnościowe
3	Firmowe
4	Walutowe
5	Osobiste Premium
\.


--
-- Data for Name: card; Type: TABLE DATA; Schema: accounts; Owner: oliwier
--

COPY accounts.card (card_id, account_id, card_type_id, card_status_id, number, expiry_date) FROM stdin;
2	2	1	1	2222333344445555	2026-10-31
3	3	1	2	3333444455556666	2028-01-31
4	4	2	1	4444555566667777	2025-11-30
5	2	3	1	5555666677778888	2026-06-30
1	1	1	1	1111222233334444	2027-12-31
6	3	3	2	1123435687694537	2028-03-25
\.


--
-- Data for Name: card_statuses; Type: TABLE DATA; Schema: accounts; Owner: oliwier
--

COPY accounts.card_statuses (card_status_id, name) FROM stdin;
1	Aktywna
2	Zablokowana
3	Zastrzeżona
4	Wygasła
5	Zamrożona
\.


--
-- Data for Name: card_types; Type: TABLE DATA; Schema: accounts; Owner: oliwier
--

COPY accounts.card_types (card_type_id, name) FROM stdin;
1	Debetowa
2	Kredytowa
3	Wirtualna
4	Debetowa Walutowa
\.


--
-- Data for Name: loan; Type: TABLE DATA; Schema: loans; Owner: oliwier
--

COPY loans.loan (loan_id, client_id, loan_status_id, employee_id, amount, interest_rate, start_date) FROM stdin;
1	1	1	2	20000.00	7.50	2023-01-15
2	3	1	1	5000.00	9.20	2024-05-20
4	5	3	1	10000.00	8.00	2025-09-01
3	4	1	2	150000.00	5.80	2022-02-10
\.


--
-- Data for Name: loan_statuses; Type: TABLE DATA; Schema: loans; Owner: oliwier
--

COPY loans.loan_statuses (loan_status_id, name) FROM stdin;
1	Aktywny
2	Spłacony
3	W trakcie rozpatrywania
4	Odrzucony
5	Odroczony
\.


--
-- Data for Name: client; Type: TABLE DATA; Schema: parties; Owner: oliwier
--

COPY parties.client (client_id, name, surname, pesel, email) FROM stdin;
1	Adam	Zieliński	85010112345	adam.zielinski@example.com
2	Ewa	Szymańska	92020223456	ewa.szymanska@example.com
3	Tomasz	Jankowski	78030334567	tomasz.jankowski@example.com
4	Magdalena	Woźniak	89040445678	magdalena.wozniak@example.com
5	Krzysztof	Lewandowski	95050556789	krzysztof.lewandowski@example.com
\.


--
-- Data for Name: employee; Type: TABLE DATA; Schema: parties; Owner: oliwier
--

COPY parties.employee (employee_id, position_id, name, surname) FROM stdin;
1	1	Jan	Kowalski
2	2	Anna	Nowak
3	3	Piotr	Wiśniewski
4	4	Katarzyna	Wójcik
5	1	Marek	Kowalczyk
6	5	Michał	Grabala
\.


--
-- Data for Name: positions; Type: TABLE DATA; Schema: parties; Owner: oliwier
--

COPY parties.positions (position_id, name) FROM stdin;
1	Doradca Klienta
2	Analityk Kredytowy
3	Kasjer
4	Specjalista ds. Bezpieczeństwa
5	Analityk Biznesowy
\.


--
-- Data for Name: loginHistory; Type: TABLE DATA; Schema: security; Owner: oliwier
--

COPY security."loginHistory" (login_id, user_id, action_type_id, login_time, ip_adres) FROM stdin;
1	6	1	2025-10-10 08:00:00	192.168.1.10
2	6	2	2025-10-10 08:00:05	192.168.1.10
3	1	1	2025-10-10 08:05:00	10.0.0.5
4	7	1	2025-10-11 12:00:00	89.123.45.67
5	6	3	2025-10-10 09:30:00	192.168.1.10
\.


--
-- Data for Name: login_action_types; Type: TABLE DATA; Schema: security; Owner: oliwier
--

COPY security.login_action_types (action_type_id, name) FROM stdin;
1	Logowanie udane
2	Logowanie nieudane
3	Wylogowanie
4	Logowanie 2FA
\.


--
-- Data for Name: user; Type: TABLE DATA; Schema: security; Owner: oliwier
--

COPY security."user" (user_id, employee_id, client_id, login, password) FROM stdin;
1	1	\N	jkowalski	$2a$12$XvCPIn3kVbguVtfRDWEhsOAyMG.E/xJHKy2BD/dnrizqP5oqWlD.m
2	2	\N	anowak	$2a$12$bVY7EOmWLMrxFnqG6Fb2HemX7YtAzNco0zMK8TppPR72EDSsC6TLC
3	3	\N	pwisniewski	$2a$12$Yc8FMEzvQbHgbbHGUKngyubvBqaf4dO4/7nWIsqHKVYoGOmbvdkfi
4	4	\N	kwojcik	$2a$12$Kfr4PKlPeD8QaMKp9OcHnOAB1r4lNQmMmbJbTpn64E1StQOsF.HAi
5	5	\N	mkowalczyk	$2a$12$J1M5/WgdZWAOF.LLmeFateCM/0rGZZd/ni5y1r3ZYfs8N2SFCATOG
6	\N	1	azielinski	$2a$12$8maNoeh28SsdMiaBNZixHesDjRerxnQbSxNBMWE/L28F4.Z8OEVne
7	\N	2	eszymanska	$2a$12$LltzhvCxvwVg94bz0NzGbO4sODn6GCkDzZbTXRciKLVNp0DzncJ/a
8	\N	3	tjankowski	$2a$12$Q7Q6nf3XWjt8NTMfgfQ2L.RULMc3MR87xIt26oPsfC.ldxJSF6Fx.
9	\N	4	mwozniak	$2a$12$PPc8rj1RwG8tOPID6AhRlO3zRHGMY10hnAE6C6NQoxzF60N/cVLCe
10	\N	5	klewandowski	$2a$12$tN15nY4ciM5HaFIXt4ehEe6189M15O5TFGOvQ.5ZAUP3mlKcWrCXy
\.


--
-- Data for Name: currency; Type: TABLE DATA; Schema: shared; Owner: oliwier
--

COPY shared.currency (currency_id, symbol, name) FROM stdin;
1	PLN	Polski Złoty
2	EUR	Euro
3	USD	Dolar Amerykański
4	CHF	Frank szwajcarski
\.


--
-- Data for Name: exchangeRates; Type: TABLE DATA; Schema: shared; Owner: oliwier
--

COPY shared."exchangeRates" (ex_rate_id, curr_from_id, curr_to_id, ex_rate, date) FROM stdin;
1	2	1	4.250000	2025-10-10
2	3	1	3.980000	2025-10-10
3	1	2	0.230000	2025-10-10
4	1	3	0.250000	2025-10-10
5	4	1	4.590000	2025-10-10
6	1	4	0.217865	2025-10-10
7	3	1	3.675100	2025-10-31
8	1	3	0.272101	2025-10-31
9	2	1	4.254300	2025-10-31
10	1	2	0.235056	2025-10-31
11	4	1	4.584900	2025-10-31
12	1	4	0.218107	2025-10-31
\.


--
-- Data for Name: transaction; Type: TABLE DATA; Schema: transactions; Owner: oliwier
--

COPY transactions.transaction (transaction_id, sender_account_id, receiver_account_id, card_id, exchange_id, transaction_type_id, transaction_status_id, amount, "time", description, counterparty_name, counterparty_acc_num) FROM stdin;
1	1	2	\N	\N	1	1	150.00	2025-10-09 10:00:00	Przelew za obiad	\N	\N
2	2	\N	2	\N	2	1	75.50	2025-10-09 12:30:00	Zakupy spożywcze	\N	\N
3	\N	4	\N	\N	3	1	1000.00	2025-10-10 09:15:00	Wpłata własna	\N	\N
4	5	1	\N	1	5	1	200.00	2025-10-10 11:00:00	Wymiana 200 EUR na PLN	\N	\N
5	1	\N	\N	\N	1	1	250.00	2025-10-11 14:00:00	Czynsz	Wynajem Sp. z o.o.	PL99102010139999989898989898
6	1	2	\N	\N	1	1	250.75	2025-09-22 10:15:00	Zwrot za bilety	\N	\N
7	1	4	\N	\N	1	1	1200.00	2025-10-01 11:00:00	Czynsz	Wynajem Sp. z o.o.	PL99102010139999989898989898
8	1	3	\N	\N	1	1	88.50	2025-08-30 18:45:00	Rozliczenie za kolację	\N	\N
9	5	1	\N	\N	1	1	1000.00	2025-09-15 14:00:00	Przelew własny	\N	\N
10	\N	\N	1	\N	2	1	149.99	2025-10-14 19:30:00	Zakupy odzieżowe	Zalando	\N
11	\N	\N	1	\N	2	1	55.00	2025-10-11 13:00:00	Lunch	Restauracja Smak	\N
12	\N	\N	1	\N	2	1	210.40	2025-09-05 17:20:00	Zakupy spożywcze	Auchan	\N
13	5	\N	\N	\N	4	1	200.00	2025-08-25 09:00:00	Wypłata gotówki	Bankomat Euronet	\N
14	\N	\N	2	\N	2	1	45.80	2025-10-02 08:30:00	Kawa i kanapka	Starbucks	\N
15	\N	\N	2	\N	2	1	78.00	2025-09-28 20:00:00	Bilety do kina	Cinema City	\N
16	\N	\N	5	\N	2	1	95.20	2025-09-18 11:45:00	Tankowanie paliwa	Stacja BP	\N
17	2	4	\N	\N	1	1	300.00	2025-07-20 16:00:00	Prezent urodzinowy	\N	\N
18	\N	\N	3	\N	2	1	129.50	2025-06-10 14:25:00	Książki	Empik	\N
19	\N	3	\N	\N	3	1	500.00	2025-10-05 12:00:00	Wpłata od znajomego	\N	\N
20	\N	\N	4	\N	2	1	65.00	2025-10-08 18:00:00	Apteka	Apteka Zdrowie	\N
21	4	5	\N	\N	1	1	450.00	2025-09-02 21:00:00	Rachunek za telefon	Orange Polska	PL22114000001111222233334444
22	4	1	\N	\N	1	2	199.99	2025-10-16 14:30:00	Przelew weryfikacyjny	\N	\N
23	2	1	\N	\N	1	1	75.00	2024-05-10 10:10:00	Stary przelew	\N	\N
24	1	2	\N	\N	1	1	0.50	2025-10-25 16:35:44.050012	Przelew testowy		PL22102010130000020202020202
25	5	1	\N	1	1	1	100.00	2025-10-25 17:30:39.887297	Przelew testowy 2	\N	\N
26	3	\N	\N	\N	1	2	0.75	2025-10-25 18:04:20.007317	Przelew testowy 3	Test 3	PL21152010130060010701018101
\.


--
-- Data for Name: transaction_statuses; Type: TABLE DATA; Schema: transactions; Owner: oliwier
--

COPY transactions.transaction_statuses (transaction_status_id, name) FROM stdin;
1	Zakończona
2	W toku
3	Odrzucona
\.


--
-- Data for Name: transaction_types; Type: TABLE DATA; Schema: transactions; Owner: oliwier
--

COPY transactions.transaction_types (transaction_type_id, name) FROM stdin;
1	Przelew krajowy
2	Płatność kartą
3	Wpłata
4	Wypłata
5	Wymiana walut
\.


--
-- Name: account_account_id_seq; Type: SEQUENCE SET; Schema: accounts; Owner: oliwier
--

SELECT pg_catalog.setval('accounts.account_account_id_seq', 6, true);


--
-- Name: account_types_account_type_id_seq; Type: SEQUENCE SET; Schema: accounts; Owner: oliwier
--

SELECT pg_catalog.setval('accounts.account_types_account_type_id_seq', 5, true);


--
-- Name: card_card_id_seq; Type: SEQUENCE SET; Schema: accounts; Owner: oliwier
--

SELECT pg_catalog.setval('accounts.card_card_id_seq', 6, true);


--
-- Name: card_statuses_card_status_id_seq; Type: SEQUENCE SET; Schema: accounts; Owner: oliwier
--

SELECT pg_catalog.setval('accounts.card_statuses_card_status_id_seq', 5, true);


--
-- Name: card_types_card_type_id_seq; Type: SEQUENCE SET; Schema: accounts; Owner: oliwier
--

SELECT pg_catalog.setval('accounts.card_types_card_type_id_seq', 4, true);


--
-- Name: loan_loan_id_seq; Type: SEQUENCE SET; Schema: loans; Owner: oliwier
--

SELECT pg_catalog.setval('loans.loan_loan_id_seq', 4, true);


--
-- Name: loan_statuses_loan_status_id_seq; Type: SEQUENCE SET; Schema: loans; Owner: oliwier
--

SELECT pg_catalog.setval('loans.loan_statuses_loan_status_id_seq', 5, true);


--
-- Name: client_client_id_seq; Type: SEQUENCE SET; Schema: parties; Owner: oliwier
--

SELECT pg_catalog.setval('parties.client_client_id_seq', 6, true);


--
-- Name: employee_employee_id_seq; Type: SEQUENCE SET; Schema: parties; Owner: oliwier
--

SELECT pg_catalog.setval('parties.employee_employee_id_seq', 6, true);


--
-- Name: positions_position_id_seq; Type: SEQUENCE SET; Schema: parties; Owner: oliwier
--

SELECT pg_catalog.setval('parties.positions_position_id_seq', 5, true);


--
-- Name: loginHistory_login_id_seq; Type: SEQUENCE SET; Schema: security; Owner: oliwier
--

SELECT pg_catalog.setval('security."loginHistory_login_id_seq"', 5, true);


--
-- Name: login_action_types_action_type_id_seq; Type: SEQUENCE SET; Schema: security; Owner: oliwier
--

SELECT pg_catalog.setval('security.login_action_types_action_type_id_seq', 4, true);


--
-- Name: user_user_id_seq; Type: SEQUENCE SET; Schema: security; Owner: oliwier
--

SELECT pg_catalog.setval('security.user_user_id_seq', 10, true);


--
-- Name: currency_currency_id_seq; Type: SEQUENCE SET; Schema: shared; Owner: oliwier
--

SELECT pg_catalog.setval('shared.currency_currency_id_seq', 4, true);


--
-- Name: exchangeRates_ex_rate_id_seq; Type: SEQUENCE SET; Schema: shared; Owner: oliwier
--

SELECT pg_catalog.setval('shared."exchangeRates_ex_rate_id_seq"', 12, true);


--
-- Name: transaction_statuses_transaction_status_id_seq; Type: SEQUENCE SET; Schema: transactions; Owner: oliwier
--

SELECT pg_catalog.setval('transactions.transaction_statuses_transaction_status_id_seq', 3, true);


--
-- Name: transaction_transaction_id_seq; Type: SEQUENCE SET; Schema: transactions; Owner: oliwier
--

SELECT pg_catalog.setval('transactions.transaction_transaction_id_seq', 26, true);


--
-- Name: transaction_types_transaction_type_id_seq; Type: SEQUENCE SET; Schema: transactions; Owner: oliwier
--

SELECT pg_catalog.setval('transactions.transaction_types_transaction_type_id_seq', 5, true);


--
-- Name: account account_number_key; Type: CONSTRAINT; Schema: accounts; Owner: oliwier
--

ALTER TABLE ONLY accounts.account
    ADD CONSTRAINT account_number_key UNIQUE (number);


--
-- Name: account account_pkey; Type: CONSTRAINT; Schema: accounts; Owner: oliwier
--

ALTER TABLE ONLY accounts.account
    ADD CONSTRAINT account_pkey PRIMARY KEY (account_id);


--
-- Name: account_types account_types_name_key; Type: CONSTRAINT; Schema: accounts; Owner: oliwier
--

ALTER TABLE ONLY accounts.account_types
    ADD CONSTRAINT account_types_name_key UNIQUE (name);


--
-- Name: account_types account_types_pkey; Type: CONSTRAINT; Schema: accounts; Owner: oliwier
--

ALTER TABLE ONLY accounts.account_types
    ADD CONSTRAINT account_types_pkey PRIMARY KEY (account_type_id);


--
-- Name: card card_number_key; Type: CONSTRAINT; Schema: accounts; Owner: oliwier
--

ALTER TABLE ONLY accounts.card
    ADD CONSTRAINT card_number_key UNIQUE (number);


--
-- Name: card card_pkey; Type: CONSTRAINT; Schema: accounts; Owner: oliwier
--

ALTER TABLE ONLY accounts.card
    ADD CONSTRAINT card_pkey PRIMARY KEY (card_id);


--
-- Name: card_statuses card_statuses_name_key; Type: CONSTRAINT; Schema: accounts; Owner: oliwier
--

ALTER TABLE ONLY accounts.card_statuses
    ADD CONSTRAINT card_statuses_name_key UNIQUE (name);


--
-- Name: card_statuses card_statuses_pkey; Type: CONSTRAINT; Schema: accounts; Owner: oliwier
--

ALTER TABLE ONLY accounts.card_statuses
    ADD CONSTRAINT card_statuses_pkey PRIMARY KEY (card_status_id);


--
-- Name: card_types card_types_name_key; Type: CONSTRAINT; Schema: accounts; Owner: oliwier
--

ALTER TABLE ONLY accounts.card_types
    ADD CONSTRAINT card_types_name_key UNIQUE (name);


--
-- Name: card_types card_types_pkey; Type: CONSTRAINT; Schema: accounts; Owner: oliwier
--

ALTER TABLE ONLY accounts.card_types
    ADD CONSTRAINT card_types_pkey PRIMARY KEY (card_type_id);


--
-- Name: loan loan_pkey; Type: CONSTRAINT; Schema: loans; Owner: oliwier
--

ALTER TABLE ONLY loans.loan
    ADD CONSTRAINT loan_pkey PRIMARY KEY (loan_id);


--
-- Name: loan_statuses loan_statuses_name_key; Type: CONSTRAINT; Schema: loans; Owner: oliwier
--

ALTER TABLE ONLY loans.loan_statuses
    ADD CONSTRAINT loan_statuses_name_key UNIQUE (name);


--
-- Name: loan_statuses loan_statuses_pkey; Type: CONSTRAINT; Schema: loans; Owner: oliwier
--

ALTER TABLE ONLY loans.loan_statuses
    ADD CONSTRAINT loan_statuses_pkey PRIMARY KEY (loan_status_id);


--
-- Name: client client_email_key; Type: CONSTRAINT; Schema: parties; Owner: oliwier
--

ALTER TABLE ONLY parties.client
    ADD CONSTRAINT client_email_key UNIQUE (email);


--
-- Name: client client_pesel_key; Type: CONSTRAINT; Schema: parties; Owner: oliwier
--

ALTER TABLE ONLY parties.client
    ADD CONSTRAINT client_pesel_key UNIQUE (pesel);


--
-- Name: client client_pkey; Type: CONSTRAINT; Schema: parties; Owner: oliwier
--

ALTER TABLE ONLY parties.client
    ADD CONSTRAINT client_pkey PRIMARY KEY (client_id);


--
-- Name: employee employee_pkey; Type: CONSTRAINT; Schema: parties; Owner: oliwier
--

ALTER TABLE ONLY parties.employee
    ADD CONSTRAINT employee_pkey PRIMARY KEY (employee_id);


--
-- Name: positions positions_name_key; Type: CONSTRAINT; Schema: parties; Owner: oliwier
--

ALTER TABLE ONLY parties.positions
    ADD CONSTRAINT positions_name_key UNIQUE (name);


--
-- Name: positions positions_pkey; Type: CONSTRAINT; Schema: parties; Owner: oliwier
--

ALTER TABLE ONLY parties.positions
    ADD CONSTRAINT positions_pkey PRIMARY KEY (position_id);


--
-- Name: loginHistory loginHistory_pkey; Type: CONSTRAINT; Schema: security; Owner: oliwier
--

ALTER TABLE ONLY security."loginHistory"
    ADD CONSTRAINT "loginHistory_pkey" PRIMARY KEY (login_id);


--
-- Name: login_action_types login_action_types_name_key; Type: CONSTRAINT; Schema: security; Owner: oliwier
--

ALTER TABLE ONLY security.login_action_types
    ADD CONSTRAINT login_action_types_name_key UNIQUE (name);


--
-- Name: login_action_types login_action_types_pkey; Type: CONSTRAINT; Schema: security; Owner: oliwier
--

ALTER TABLE ONLY security.login_action_types
    ADD CONSTRAINT login_action_types_pkey PRIMARY KEY (action_type_id);


--
-- Name: user user_login_key; Type: CONSTRAINT; Schema: security; Owner: oliwier
--

ALTER TABLE ONLY security."user"
    ADD CONSTRAINT user_login_key UNIQUE (login);


--
-- Name: user user_pkey; Type: CONSTRAINT; Schema: security; Owner: oliwier
--

ALTER TABLE ONLY security."user"
    ADD CONSTRAINT user_pkey PRIMARY KEY (user_id);


--
-- Name: currency currency_pkey; Type: CONSTRAINT; Schema: shared; Owner: oliwier
--

ALTER TABLE ONLY shared.currency
    ADD CONSTRAINT currency_pkey PRIMARY KEY (currency_id);


--
-- Name: currency currency_symbol_key; Type: CONSTRAINT; Schema: shared; Owner: oliwier
--

ALTER TABLE ONLY shared.currency
    ADD CONSTRAINT currency_symbol_key UNIQUE (symbol);


--
-- Name: exchangeRates exchangeRates_pkey; Type: CONSTRAINT; Schema: shared; Owner: oliwier
--

ALTER TABLE ONLY shared."exchangeRates"
    ADD CONSTRAINT "exchangeRates_pkey" PRIMARY KEY (ex_rate_id);


--
-- Name: transaction transaction_pkey; Type: CONSTRAINT; Schema: transactions; Owner: oliwier
--

ALTER TABLE ONLY transactions.transaction
    ADD CONSTRAINT transaction_pkey PRIMARY KEY (transaction_id);


--
-- Name: transaction_statuses transaction_statuses_name_key; Type: CONSTRAINT; Schema: transactions; Owner: oliwier
--

ALTER TABLE ONLY transactions.transaction_statuses
    ADD CONSTRAINT transaction_statuses_name_key UNIQUE (name);


--
-- Name: transaction_statuses transaction_statuses_pkey; Type: CONSTRAINT; Schema: transactions; Owner: oliwier
--

ALTER TABLE ONLY transactions.transaction_statuses
    ADD CONSTRAINT transaction_statuses_pkey PRIMARY KEY (transaction_status_id);


--
-- Name: transaction_types transaction_types_name_key; Type: CONSTRAINT; Schema: transactions; Owner: oliwier
--

ALTER TABLE ONLY transactions.transaction_types
    ADD CONSTRAINT transaction_types_name_key UNIQUE (name);


--
-- Name: transaction_types transaction_types_pkey; Type: CONSTRAINT; Schema: transactions; Owner: oliwier
--

ALTER TABLE ONLY transactions.transaction_types
    ADD CONSTRAINT transaction_types_pkey PRIMARY KEY (transaction_type_id);


--
-- Name: idx_account_client_id; Type: INDEX; Schema: accounts; Owner: oliwier
--

CREATE INDEX idx_account_client_id ON accounts.account USING btree (client_id);


--
-- Name: idx_account_currency_id; Type: INDEX; Schema: accounts; Owner: oliwier
--

CREATE INDEX idx_account_currency_id ON accounts.account USING btree (currency_id);


--
-- Name: idx_card_account_id; Type: INDEX; Schema: accounts; Owner: oliwier
--

CREATE INDEX idx_card_account_id ON accounts.card USING btree (account_id);


--
-- Name: idx_loan_client_id; Type: INDEX; Schema: loans; Owner: oliwier
--

CREATE INDEX idx_loan_client_id ON loans.loan USING btree (client_id);


--
-- Name: idx_loan_employee_id; Type: INDEX; Schema: loans; Owner: oliwier
--

CREATE INDEX idx_loan_employee_id ON loans.loan USING btree (employee_id);


--
-- Name: idx_client_surname_name; Type: INDEX; Schema: parties; Owner: oliwier
--

CREATE INDEX idx_client_surname_name ON parties.client USING btree (surname, name);


--
-- Name: idx_employee_position_id; Type: INDEX; Schema: parties; Owner: oliwier
--

CREATE INDEX idx_employee_position_id ON parties.employee USING btree (position_id);


--
-- Name: idx_loginhistory_user_id; Type: INDEX; Schema: security; Owner: oliwier
--

CREATE INDEX idx_loginhistory_user_id ON security."loginHistory" USING btree (user_id);


--
-- Name: idx_loginhistory_user_time; Type: INDEX; Schema: security; Owner: oliwier
--

CREATE INDEX idx_loginhistory_user_time ON security."loginHistory" USING btree (user_id, login_time DESC);


--
-- Name: idx_user_client_id; Type: INDEX; Schema: security; Owner: oliwier
--

CREATE INDEX idx_user_client_id ON security."user" USING btree (client_id);


--
-- Name: idx_user_employee_id; Type: INDEX; Schema: security; Owner: oliwier
--

CREATE INDEX idx_user_employee_id ON security."user" USING btree (employee_id);


--
-- Name: idx_exchangerates_pair_date; Type: INDEX; Schema: shared; Owner: oliwier
--

CREATE INDEX idx_exchangerates_pair_date ON shared."exchangeRates" USING btree (curr_from_id, curr_to_id, date DESC);


--
-- Name: idx_exchange_id; Type: INDEX; Schema: transactions; Owner: oliwier
--

CREATE INDEX idx_exchange_id ON transactions.transaction USING btree (exchange_id);


--
-- Name: idx_transaction_card_id; Type: INDEX; Schema: transactions; Owner: oliwier
--

CREATE INDEX idx_transaction_card_id ON transactions.transaction USING btree (card_id);


--
-- Name: idx_transaction_receiver_id; Type: INDEX; Schema: transactions; Owner: oliwier
--

CREATE INDEX idx_transaction_receiver_id ON transactions.transaction USING btree (receiver_account_id);


--
-- Name: idx_transaction_receiver_time; Type: INDEX; Schema: transactions; Owner: oliwier
--

CREATE INDEX idx_transaction_receiver_time ON transactions.transaction USING btree (receiver_account_id, "time" DESC);


--
-- Name: idx_transaction_sender_id; Type: INDEX; Schema: transactions; Owner: oliwier
--

CREATE INDEX idx_transaction_sender_id ON transactions.transaction USING btree (sender_account_id);


--
-- Name: idx_transaction_sender_time; Type: INDEX; Schema: transactions; Owner: oliwier
--

CREATE INDEX idx_transaction_sender_time ON transactions.transaction USING btree (sender_account_id, "time" DESC);


--
-- Name: account trg_prevent_delete_active_acc; Type: TRIGGER; Schema: accounts; Owner: oliwier
--

CREATE TRIGGER trg_prevent_delete_active_acc BEFORE DELETE ON accounts.account FOR EACH ROW EXECUTE FUNCTION accounts.fn_check_account_empty();


--
-- Name: account trg_protect_balance_on_update; Type: TRIGGER; Schema: accounts; Owner: oliwier
--

CREATE TRIGGER trg_protect_balance_on_update BEFORE UPDATE ON accounts.account FOR EACH ROW WHEN ((old.balance IS DISTINCT FROM new.balance)) EXECUTE FUNCTION accounts.fn_check_balance_not_negative();


--
-- Name: account account_account_type_id_fkey; Type: FK CONSTRAINT; Schema: accounts; Owner: oliwier
--

ALTER TABLE ONLY accounts.account
    ADD CONSTRAINT account_account_type_id_fkey FOREIGN KEY (account_type_id) REFERENCES accounts.account_types(account_type_id);


--
-- Name: account account_client_id_fkey; Type: FK CONSTRAINT; Schema: accounts; Owner: oliwier
--

ALTER TABLE ONLY accounts.account
    ADD CONSTRAINT account_client_id_fkey FOREIGN KEY (client_id) REFERENCES parties.client(client_id);


--
-- Name: account account_currency_id_fkey; Type: FK CONSTRAINT; Schema: accounts; Owner: oliwier
--

ALTER TABLE ONLY accounts.account
    ADD CONSTRAINT account_currency_id_fkey FOREIGN KEY (currency_id) REFERENCES shared.currency(currency_id);


--
-- Name: card card_account_id_fkey; Type: FK CONSTRAINT; Schema: accounts; Owner: oliwier
--

ALTER TABLE ONLY accounts.card
    ADD CONSTRAINT card_account_id_fkey FOREIGN KEY (account_id) REFERENCES accounts.account(account_id);


--
-- Name: card card_card_status_id_fkey; Type: FK CONSTRAINT; Schema: accounts; Owner: oliwier
--

ALTER TABLE ONLY accounts.card
    ADD CONSTRAINT card_card_status_id_fkey FOREIGN KEY (card_status_id) REFERENCES accounts.card_statuses(card_status_id);


--
-- Name: card card_card_type_id_fkey; Type: FK CONSTRAINT; Schema: accounts; Owner: oliwier
--

ALTER TABLE ONLY accounts.card
    ADD CONSTRAINT card_card_type_id_fkey FOREIGN KEY (card_type_id) REFERENCES accounts.card_types(card_type_id);


--
-- Name: loan loan_client_id_fkey; Type: FK CONSTRAINT; Schema: loans; Owner: oliwier
--

ALTER TABLE ONLY loans.loan
    ADD CONSTRAINT loan_client_id_fkey FOREIGN KEY (client_id) REFERENCES parties.client(client_id);


--
-- Name: loan loan_employee_id_fkey; Type: FK CONSTRAINT; Schema: loans; Owner: oliwier
--

ALTER TABLE ONLY loans.loan
    ADD CONSTRAINT loan_employee_id_fkey FOREIGN KEY (employee_id) REFERENCES parties.employee(employee_id);


--
-- Name: loan loan_loan_status_id_fkey; Type: FK CONSTRAINT; Schema: loans; Owner: oliwier
--

ALTER TABLE ONLY loans.loan
    ADD CONSTRAINT loan_loan_status_id_fkey FOREIGN KEY (loan_status_id) REFERENCES loans.loan_statuses(loan_status_id);


--
-- Name: employee employee_position_id_fkey; Type: FK CONSTRAINT; Schema: parties; Owner: oliwier
--

ALTER TABLE ONLY parties.employee
    ADD CONSTRAINT employee_position_id_fkey FOREIGN KEY (position_id) REFERENCES parties.positions(position_id);


--
-- Name: loginHistory loginHistory_action_type_id_fkey; Type: FK CONSTRAINT; Schema: security; Owner: oliwier
--

ALTER TABLE ONLY security."loginHistory"
    ADD CONSTRAINT "loginHistory_action_type_id_fkey" FOREIGN KEY (action_type_id) REFERENCES security.login_action_types(action_type_id);


--
-- Name: loginHistory loginHistory_user_id_fkey; Type: FK CONSTRAINT; Schema: security; Owner: oliwier
--

ALTER TABLE ONLY security."loginHistory"
    ADD CONSTRAINT "loginHistory_user_id_fkey" FOREIGN KEY (user_id) REFERENCES security."user"(user_id);


--
-- Name: user user_client_id_fkey; Type: FK CONSTRAINT; Schema: security; Owner: oliwier
--

ALTER TABLE ONLY security."user"
    ADD CONSTRAINT user_client_id_fkey FOREIGN KEY (client_id) REFERENCES parties.client(client_id);


--
-- Name: user user_employee_id_fkey; Type: FK CONSTRAINT; Schema: security; Owner: oliwier
--

ALTER TABLE ONLY security."user"
    ADD CONSTRAINT user_employee_id_fkey FOREIGN KEY (employee_id) REFERENCES parties.employee(employee_id);


--
-- Name: exchangeRates exchangeRates_curr_from_id_fkey; Type: FK CONSTRAINT; Schema: shared; Owner: oliwier
--

ALTER TABLE ONLY shared."exchangeRates"
    ADD CONSTRAINT "exchangeRates_curr_from_id_fkey" FOREIGN KEY (curr_from_id) REFERENCES shared.currency(currency_id);


--
-- Name: exchangeRates exchangeRates_curr_to_id_fkey; Type: FK CONSTRAINT; Schema: shared; Owner: oliwier
--

ALTER TABLE ONLY shared."exchangeRates"
    ADD CONSTRAINT "exchangeRates_curr_to_id_fkey" FOREIGN KEY (curr_to_id) REFERENCES shared.currency(currency_id);


--
-- Name: transaction transaction_card_id_fkey; Type: FK CONSTRAINT; Schema: transactions; Owner: oliwier
--

ALTER TABLE ONLY transactions.transaction
    ADD CONSTRAINT transaction_card_id_fkey FOREIGN KEY (card_id) REFERENCES accounts.card(card_id);


--
-- Name: transaction transaction_exchange_id_fkey; Type: FK CONSTRAINT; Schema: transactions; Owner: oliwier
--

ALTER TABLE ONLY transactions.transaction
    ADD CONSTRAINT transaction_exchange_id_fkey FOREIGN KEY (exchange_id) REFERENCES shared."exchangeRates"(ex_rate_id);


--
-- Name: transaction transaction_receiver_account_id_fkey; Type: FK CONSTRAINT; Schema: transactions; Owner: oliwier
--

ALTER TABLE ONLY transactions.transaction
    ADD CONSTRAINT transaction_receiver_account_id_fkey FOREIGN KEY (receiver_account_id) REFERENCES accounts.account(account_id);


--
-- Name: transaction transaction_sender_account_id_fkey; Type: FK CONSTRAINT; Schema: transactions; Owner: oliwier
--

ALTER TABLE ONLY transactions.transaction
    ADD CONSTRAINT transaction_sender_account_id_fkey FOREIGN KEY (sender_account_id) REFERENCES accounts.account(account_id);


--
-- Name: transaction transaction_transaction_status_id_fkey; Type: FK CONSTRAINT; Schema: transactions; Owner: oliwier
--

ALTER TABLE ONLY transactions.transaction
    ADD CONSTRAINT transaction_transaction_status_id_fkey FOREIGN KEY (transaction_status_id) REFERENCES transactions.transaction_statuses(transaction_status_id);


--
-- Name: transaction transaction_transaction_type_id_fkey; Type: FK CONSTRAINT; Schema: transactions; Owner: oliwier
--

ALTER TABLE ONLY transactions.transaction
    ADD CONSTRAINT transaction_transaction_type_id_fkey FOREIGN KEY (transaction_type_id) REFERENCES transactions.transaction_types(transaction_type_id);


--
-- Name: SCHEMA accounts; Type: ACL; Schema: -; Owner: oliwier
--

GRANT USAGE ON SCHEMA accounts TO admin_role;
GRANT USAGE ON SCHEMA accounts TO employee_role;
GRANT USAGE ON SCHEMA accounts TO client_role;


--
-- Name: SCHEMA loans; Type: ACL; Schema: -; Owner: oliwier
--

GRANT USAGE ON SCHEMA loans TO admin_role;
GRANT USAGE ON SCHEMA loans TO employee_role;
GRANT USAGE ON SCHEMA loans TO client_role;


--
-- Name: SCHEMA parties; Type: ACL; Schema: -; Owner: oliwier
--

GRANT USAGE ON SCHEMA parties TO admin_role;
GRANT USAGE ON SCHEMA parties TO employee_role;
GRANT USAGE ON SCHEMA parties TO client_role;


--
-- Name: SCHEMA security; Type: ACL; Schema: -; Owner: oliwier
--

GRANT USAGE ON SCHEMA security TO admin_role;
GRANT USAGE ON SCHEMA security TO employee_role;
GRANT USAGE ON SCHEMA security TO client_role;


--
-- Name: SCHEMA shared; Type: ACL; Schema: -; Owner: oliwier
--

GRANT USAGE ON SCHEMA shared TO admin_role;
GRANT USAGE ON SCHEMA shared TO employee_role;
GRANT USAGE ON SCHEMA shared TO client_role;


--
-- Name: SCHEMA transactions; Type: ACL; Schema: -; Owner: oliwier
--

GRANT USAGE ON SCHEMA transactions TO admin_role;
GRANT USAGE ON SCHEMA transactions TO employee_role;
GRANT USAGE ON SCHEMA transactions TO client_role;


--
-- Name: FUNCTION fn_get_client_total_balance(p_client_id integer, p_target_currency_id integer, p_calculation_date date); Type: ACL; Schema: accounts; Owner: oliwier
--

REVOKE ALL ON FUNCTION accounts.fn_get_client_total_balance(p_client_id integer, p_target_currency_id integer, p_calculation_date date) FROM PUBLIC;
GRANT ALL ON FUNCTION accounts.fn_get_client_total_balance(p_client_id integer, p_target_currency_id integer, p_calculation_date date) TO employee_role;
GRANT ALL ON FUNCTION accounts.fn_get_client_total_balance(p_client_id integer, p_target_currency_id integer, p_calculation_date date) TO admin_role;


--
-- Name: FUNCTION fn_get_my_total_balance(p_target_currency_id integer, p_calculation_date date); Type: ACL; Schema: accounts; Owner: oliwier
--

REVOKE ALL ON FUNCTION accounts.fn_get_my_total_balance(p_target_currency_id integer, p_calculation_date date) FROM PUBLIC;
GRANT ALL ON FUNCTION accounts.fn_get_my_total_balance(p_target_currency_id integer, p_calculation_date date) TO client_role;


--
-- Name: PROCEDURE sp_issue_new_card(IN p_account_id integer, IN p_card_type_name character varying, IN p_number character varying, IN p_expiry_date date); Type: ACL; Schema: accounts; Owner: oliwier
--

REVOKE ALL ON PROCEDURE accounts.sp_issue_new_card(IN p_account_id integer, IN p_card_type_name character varying, IN p_number character varying, IN p_expiry_date date) FROM PUBLIC;
GRANT ALL ON PROCEDURE accounts.sp_issue_new_card(IN p_account_id integer, IN p_card_type_name character varying, IN p_number character varying, IN p_expiry_date date) TO employee_role;
GRANT ALL ON PROCEDURE accounts.sp_issue_new_card(IN p_account_id integer, IN p_card_type_name character varying, IN p_number character varying, IN p_expiry_date date) TO admin_role;


--
-- Name: PROCEDURE sp_open_account(IN p_client_id integer, IN p_currency_symbol character, IN p_account_type_name character varying, IN p_number character varying, IN p_initial_balance numeric); Type: ACL; Schema: accounts; Owner: oliwier
--

REVOKE ALL ON PROCEDURE accounts.sp_open_account(IN p_client_id integer, IN p_currency_symbol character, IN p_account_type_name character varying, IN p_number character varying, IN p_initial_balance numeric) FROM PUBLIC;
GRANT ALL ON PROCEDURE accounts.sp_open_account(IN p_client_id integer, IN p_currency_symbol character, IN p_account_type_name character varying, IN p_number character varying, IN p_initial_balance numeric) TO employee_role;
GRANT ALL ON PROCEDURE accounts.sp_open_account(IN p_client_id integer, IN p_currency_symbol character, IN p_account_type_name character varying, IN p_number character varying, IN p_initial_balance numeric) TO admin_role;


--
-- Name: PROCEDURE sp_add_new_employee(IN p_name character varying, IN p_surname character varying, IN p_position_name character varying); Type: ACL; Schema: parties; Owner: oliwier
--

REVOKE ALL ON PROCEDURE parties.sp_add_new_employee(IN p_name character varying, IN p_surname character varying, IN p_position_name character varying) FROM PUBLIC;
GRANT ALL ON PROCEDURE parties.sp_add_new_employee(IN p_name character varying, IN p_surname character varying, IN p_position_name character varying) TO admin_role;


--
-- Name: PROCEDURE sp_add_currency(IN p_symbol character, IN p_name character varying); Type: ACL; Schema: shared; Owner: oliwier
--

REVOKE ALL ON PROCEDURE shared.sp_add_currency(IN p_symbol character, IN p_name character varying) FROM PUBLIC;
GRANT ALL ON PROCEDURE shared.sp_add_currency(IN p_symbol character, IN p_name character varying) TO employee_role;
GRANT ALL ON PROCEDURE shared.sp_add_currency(IN p_symbol character, IN p_name character varying) TO admin_role;


--
-- Name: PROCEDURE sp_add_symmetrical_exchange_rate(IN p_symbol_from character, IN p_symbol_to character, IN p_direct_rate numeric, IN p_date date); Type: ACL; Schema: shared; Owner: oliwier
--

REVOKE ALL ON PROCEDURE shared.sp_add_symmetrical_exchange_rate(IN p_symbol_from character, IN p_symbol_to character, IN p_direct_rate numeric, IN p_date date) FROM PUBLIC;
GRANT ALL ON PROCEDURE shared.sp_add_symmetrical_exchange_rate(IN p_symbol_from character, IN p_symbol_to character, IN p_direct_rate numeric, IN p_date date) TO employee_role;
GRANT ALL ON PROCEDURE shared.sp_add_symmetrical_exchange_rate(IN p_symbol_from character, IN p_symbol_to character, IN p_direct_rate numeric, IN p_date date) TO admin_role;


--
-- Name: PROCEDURE sp_create_domestic_transfer(IN p_sender_account_id integer, IN p_receiver_account_number character varying, IN p_amount numeric, IN p_description text, IN p_counterparty_name character varying, IN p_transaction_type_id integer); Type: ACL; Schema: transactions; Owner: oliwier
--

REVOKE ALL ON PROCEDURE transactions.sp_create_domestic_transfer(IN p_sender_account_id integer, IN p_receiver_account_number character varying, IN p_amount numeric, IN p_description text, IN p_counterparty_name character varying, IN p_transaction_type_id integer) FROM PUBLIC;
GRANT ALL ON PROCEDURE transactions.sp_create_domestic_transfer(IN p_sender_account_id integer, IN p_receiver_account_number character varying, IN p_amount numeric, IN p_description text, IN p_counterparty_name character varying, IN p_transaction_type_id integer) TO employee_role;
GRANT ALL ON PROCEDURE transactions.sp_create_domestic_transfer(IN p_sender_account_id integer, IN p_receiver_account_number character varying, IN p_amount numeric, IN p_description text, IN p_counterparty_name character varying, IN p_transaction_type_id integer) TO admin_role;


--
-- Name: TABLE account; Type: ACL; Schema: accounts; Owner: oliwier
--

GRANT ALL ON TABLE accounts.account TO admin_role;
GRANT SELECT ON TABLE accounts.account TO employee_role;


--
-- Name: COLUMN account.account_type_id; Type: ACL; Schema: accounts; Owner: oliwier
--

GRANT UPDATE(account_type_id) ON TABLE accounts.account TO employee_role;


--
-- Name: SEQUENCE account_account_id_seq; Type: ACL; Schema: accounts; Owner: oliwier
--

GRANT ALL ON SEQUENCE accounts.account_account_id_seq TO admin_role;


--
-- Name: TABLE account_types; Type: ACL; Schema: accounts; Owner: oliwier
--

GRANT ALL ON TABLE accounts.account_types TO admin_role;
GRANT SELECT ON TABLE accounts.account_types TO employee_role;


--
-- Name: SEQUENCE account_types_account_type_id_seq; Type: ACL; Schema: accounts; Owner: oliwier
--

GRANT ALL ON SEQUENCE accounts.account_types_account_type_id_seq TO admin_role;


--
-- Name: TABLE card; Type: ACL; Schema: accounts; Owner: oliwier
--

GRANT ALL ON TABLE accounts.card TO admin_role;
GRANT SELECT ON TABLE accounts.card TO employee_role;


--
-- Name: COLUMN card.card_status_id; Type: ACL; Schema: accounts; Owner: oliwier
--

GRANT UPDATE(card_status_id) ON TABLE accounts.card TO employee_role;


--
-- Name: SEQUENCE card_card_id_seq; Type: ACL; Schema: accounts; Owner: oliwier
--

GRANT ALL ON SEQUENCE accounts.card_card_id_seq TO admin_role;


--
-- Name: TABLE card_statuses; Type: ACL; Schema: accounts; Owner: oliwier
--

GRANT ALL ON TABLE accounts.card_statuses TO admin_role;
GRANT SELECT ON TABLE accounts.card_statuses TO employee_role;


--
-- Name: SEQUENCE card_statuses_card_status_id_seq; Type: ACL; Schema: accounts; Owner: oliwier
--

GRANT ALL ON SEQUENCE accounts.card_statuses_card_status_id_seq TO admin_role;


--
-- Name: TABLE card_types; Type: ACL; Schema: accounts; Owner: oliwier
--

GRANT ALL ON TABLE accounts.card_types TO admin_role;
GRANT SELECT ON TABLE accounts.card_types TO employee_role;


--
-- Name: SEQUENCE card_types_card_type_id_seq; Type: ACL; Schema: accounts; Owner: oliwier
--

GRANT ALL ON SEQUENCE accounts.card_types_card_type_id_seq TO admin_role;


--
-- Name: TABLE "user"; Type: ACL; Schema: security; Owner: oliwier
--

GRANT ALL ON TABLE security."user" TO admin_role;
GRANT INSERT ON TABLE security."user" TO employee_role;


--
-- Name: COLUMN "user".user_id; Type: ACL; Schema: security; Owner: oliwier
--

GRANT SELECT(user_id) ON TABLE security."user" TO employee_role;


--
-- Name: COLUMN "user".employee_id; Type: ACL; Schema: security; Owner: oliwier
--

GRANT SELECT(employee_id) ON TABLE security."user" TO employee_role;


--
-- Name: COLUMN "user".client_id; Type: ACL; Schema: security; Owner: oliwier
--

GRANT SELECT(client_id) ON TABLE security."user" TO employee_role;
GRANT SELECT(client_id) ON TABLE security."user" TO client_role;


--
-- Name: COLUMN "user".login; Type: ACL; Schema: security; Owner: oliwier
--

GRANT SELECT(login) ON TABLE security."user" TO employee_role;
GRANT SELECT(login) ON TABLE security."user" TO client_role;


--
-- Name: TABLE currency; Type: ACL; Schema: shared; Owner: oliwier
--

GRANT ALL ON TABLE shared.currency TO admin_role;
GRANT SELECT ON TABLE shared.currency TO employee_role;


--
-- Name: TABLE view_client_accounts; Type: ACL; Schema: accounts; Owner: oliwier
--

GRANT SELECT ON TABLE accounts.view_client_accounts TO client_role;


--
-- Name: TABLE view_client_cards; Type: ACL; Schema: accounts; Owner: oliwier
--

GRANT SELECT ON TABLE accounts.view_client_cards TO client_role;


--
-- Name: TABLE loan; Type: ACL; Schema: loans; Owner: oliwier
--

GRANT ALL ON TABLE loans.loan TO admin_role;
GRANT SELECT,INSERT ON TABLE loans.loan TO employee_role;


--
-- Name: COLUMN loan.loan_status_id; Type: ACL; Schema: loans; Owner: oliwier
--

GRANT UPDATE(loan_status_id) ON TABLE loans.loan TO employee_role;


--
-- Name: SEQUENCE loan_loan_id_seq; Type: ACL; Schema: loans; Owner: oliwier
--

GRANT ALL ON SEQUENCE loans.loan_loan_id_seq TO admin_role;
GRANT SELECT,USAGE ON SEQUENCE loans.loan_loan_id_seq TO employee_role;


--
-- Name: TABLE loan_statuses; Type: ACL; Schema: loans; Owner: oliwier
--

GRANT ALL ON TABLE loans.loan_statuses TO admin_role;
GRANT SELECT ON TABLE loans.loan_statuses TO employee_role;


--
-- Name: SEQUENCE loan_statuses_loan_status_id_seq; Type: ACL; Schema: loans; Owner: oliwier
--

GRANT ALL ON SEQUENCE loans.loan_statuses_loan_status_id_seq TO admin_role;
GRANT SELECT,USAGE ON SEQUENCE loans.loan_statuses_loan_status_id_seq TO employee_role;


--
-- Name: TABLE view_client_loans; Type: ACL; Schema: loans; Owner: oliwier
--

GRANT SELECT ON TABLE loans.view_client_loans TO client_role;


--
-- Name: TABLE client; Type: ACL; Schema: parties; Owner: oliwier
--

GRANT ALL ON TABLE parties.client TO admin_role;
GRANT SELECT,INSERT ON TABLE parties.client TO employee_role;


--
-- Name: COLUMN client.name; Type: ACL; Schema: parties; Owner: oliwier
--

GRANT UPDATE(name) ON TABLE parties.client TO employee_role;


--
-- Name: COLUMN client.surname; Type: ACL; Schema: parties; Owner: oliwier
--

GRANT UPDATE(surname) ON TABLE parties.client TO employee_role;


--
-- Name: COLUMN client.pesel; Type: ACL; Schema: parties; Owner: oliwier
--

GRANT UPDATE(pesel) ON TABLE parties.client TO employee_role;


--
-- Name: COLUMN client.email; Type: ACL; Schema: parties; Owner: oliwier
--

GRANT UPDATE(email) ON TABLE parties.client TO employee_role;


--
-- Name: SEQUENCE client_client_id_seq; Type: ACL; Schema: parties; Owner: oliwier
--

GRANT ALL ON SEQUENCE parties.client_client_id_seq TO admin_role;
GRANT SELECT,USAGE ON SEQUENCE parties.client_client_id_seq TO employee_role;


--
-- Name: TABLE employee; Type: ACL; Schema: parties; Owner: oliwier
--

GRANT ALL ON TABLE parties.employee TO admin_role;
GRANT SELECT ON TABLE parties.employee TO employee_role;


--
-- Name: SEQUENCE employee_employee_id_seq; Type: ACL; Schema: parties; Owner: oliwier
--

GRANT ALL ON SEQUENCE parties.employee_employee_id_seq TO admin_role;
GRANT SELECT,USAGE ON SEQUENCE parties.employee_employee_id_seq TO employee_role;


--
-- Name: TABLE positions; Type: ACL; Schema: parties; Owner: oliwier
--

GRANT ALL ON TABLE parties.positions TO admin_role;
GRANT SELECT ON TABLE parties.positions TO employee_role;


--
-- Name: SEQUENCE positions_position_id_seq; Type: ACL; Schema: parties; Owner: oliwier
--

GRANT ALL ON SEQUENCE parties.positions_position_id_seq TO admin_role;
GRANT SELECT,USAGE ON SEQUENCE parties.positions_position_id_seq TO employee_role;


--
-- Name: TABLE view_client_profile; Type: ACL; Schema: parties; Owner: oliwier
--

GRANT SELECT ON TABLE parties.view_client_profile TO client_role;


--
-- Name: TABLE "loginHistory"; Type: ACL; Schema: security; Owner: oliwier
--

GRANT ALL ON TABLE security."loginHistory" TO admin_role;
GRANT SELECT ON TABLE security."loginHistory" TO employee_role;


--
-- Name: SEQUENCE "loginHistory_login_id_seq"; Type: ACL; Schema: security; Owner: oliwier
--

GRANT ALL ON SEQUENCE security."loginHistory_login_id_seq" TO admin_role;
GRANT SELECT,USAGE ON SEQUENCE security."loginHistory_login_id_seq" TO employee_role;


--
-- Name: TABLE login_action_types; Type: ACL; Schema: security; Owner: oliwier
--

GRANT ALL ON TABLE security.login_action_types TO admin_role;
GRANT SELECT ON TABLE security.login_action_types TO employee_role;


--
-- Name: SEQUENCE login_action_types_action_type_id_seq; Type: ACL; Schema: security; Owner: oliwier
--

GRANT ALL ON SEQUENCE security.login_action_types_action_type_id_seq TO admin_role;
GRANT SELECT,USAGE ON SEQUENCE security.login_action_types_action_type_id_seq TO employee_role;


--
-- Name: SEQUENCE user_user_id_seq; Type: ACL; Schema: security; Owner: oliwier
--

GRANT ALL ON SEQUENCE security.user_user_id_seq TO admin_role;
GRANT SELECT,USAGE ON SEQUENCE security.user_user_id_seq TO employee_role;


--
-- Name: SEQUENCE currency_currency_id_seq; Type: ACL; Schema: shared; Owner: oliwier
--

GRANT ALL ON SEQUENCE shared.currency_currency_id_seq TO admin_role;


--
-- Name: TABLE "exchangeRates"; Type: ACL; Schema: shared; Owner: oliwier
--

GRANT ALL ON TABLE shared."exchangeRates" TO admin_role;
GRANT SELECT ON TABLE shared."exchangeRates" TO employee_role;


--
-- Name: SEQUENCE "exchangeRates_ex_rate_id_seq"; Type: ACL; Schema: shared; Owner: oliwier
--

GRANT ALL ON SEQUENCE shared."exchangeRates_ex_rate_id_seq" TO admin_role;


--
-- Name: TABLE transaction; Type: ACL; Schema: transactions; Owner: oliwier
--

GRANT ALL ON TABLE transactions.transaction TO admin_role;
GRANT SELECT ON TABLE transactions.transaction TO employee_role;


--
-- Name: TABLE transaction_statuses; Type: ACL; Schema: transactions; Owner: oliwier
--

GRANT ALL ON TABLE transactions.transaction_statuses TO admin_role;
GRANT SELECT ON TABLE transactions.transaction_statuses TO employee_role;


--
-- Name: SEQUENCE transaction_statuses_transaction_status_id_seq; Type: ACL; Schema: transactions; Owner: oliwier
--

GRANT ALL ON SEQUENCE transactions.transaction_statuses_transaction_status_id_seq TO admin_role;


--
-- Name: SEQUENCE transaction_transaction_id_seq; Type: ACL; Schema: transactions; Owner: oliwier
--

GRANT ALL ON SEQUENCE transactions.transaction_transaction_id_seq TO admin_role;


--
-- Name: TABLE transaction_types; Type: ACL; Schema: transactions; Owner: oliwier
--

GRANT ALL ON TABLE transactions.transaction_types TO admin_role;
GRANT SELECT ON TABLE transactions.transaction_types TO employee_role;


--
-- Name: SEQUENCE transaction_types_transaction_type_id_seq; Type: ACL; Schema: transactions; Owner: oliwier
--

GRANT ALL ON SEQUENCE transactions.transaction_types_transaction_type_id_seq TO admin_role;


--
-- Name: TABLE view_client_card_payments; Type: ACL; Schema: transactions; Owner: oliwier
--

GRANT SELECT ON TABLE transactions.view_client_card_payments TO client_role;


--
-- Name: TABLE view_client_transactions; Type: ACL; Schema: transactions; Owner: oliwier
--

GRANT SELECT ON TABLE transactions.view_client_transactions TO client_role;


--
-- Name: TABLE view_client_transfers; Type: ACL; Schema: transactions; Owner: oliwier
--

GRANT SELECT ON TABLE transactions.view_client_transfers TO client_role;


--
-- PostgreSQL database dump complete
--

\unrestrict 0OzkYLgFTRWcwjaZOfsvg2Fr8QpEbsib8gqPdMSw3XcpIxgDoZ9CtwgYypFKj61

