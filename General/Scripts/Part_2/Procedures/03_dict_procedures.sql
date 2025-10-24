/*
    --
    Procedura sp_AddAccountType
    Opis: procedura dodajaca typ konta
    Uwaga: problem przy migracji
    --
*/

CREATE PROCEDURE accounts.sp_AddAccountType(
    p_name VARCHAR(30)
)
LANGUAGE plpgsql
AS $$
BEGIN

IF EXISTS (SELECT 1 FROM accounts.account_types
                    WHERE name = p_name)
    THEN RAISE EXCEPTION 'Typ konta juz istnieje %', p_name;
END IF;

INSERT INTO accounts.account_types(name)
    VALUES (p_name);

RAISE NOTICE 'Dodano typ konta %', p_name;

END;
$$;


/*
    --
    Procedura sp_AddEmployeePosition
    Opis: procedura dodajaca typ pracownika
    Uwaga: problem przy migracji
    --
*/

CREATE PROCEDURE parties.sp_AddEmployeePosition(
    p_name VARCHAR(30)
)
LANGUAGE plpgsql
AS $$
BEGIN

IF EXISTS (SELECT 1 FROM parties.positions
                    WHERE name = p_name)
    THEN RAISE EXCEPTION 'Typ stanowiska juz istnieje %', p_name;
END IF;

INSERT INTO parties.positions(name)
VALUES (p_name);

RAISE NOTICE 'Dodano nowe stanowisko %', p_name;

END;
$$;


/*
    --
    Procedura sp_AddLoginActionType
    Opis: procedura dodajaca typ procedury logowania do logow
    Uwaga: problem przy migracji
    --
*/

CREATE PROCEDURE security.sp_AddLoginActionType(
    p_name VARCHAR(30)
)
LANGUAGE plpgsql
AS $$
BEGIN

IF EXISTS (SELECT 1 FROM security.login_action_types
                    WHERE name = p_name)
    THEN RAISE EXCEPTION 'Typ akcji logowania juz istnieje %', p_name;
END IF;

INSERT INTO security.login_action_types(name)
VALUES (p_name);

RAISE NOTICE 'Dodano typ akcji logowania %', p_name;

END;
$$;

/*
    --
    Procedura sp_AddCardType
    Opis: procedura dodajaca typ karty
    Uwaga: problem przy migracji
    --
*/

CREATE PROCEDURE accounts.sp_AddCardType(
    p_name VARCHAR(30)
)
LANGUAGE plpgsql
AS $$
BEGIN

IF EXISTS (SELECT 1 FROM accounts.card_types
                    WHERE name = p_name)
    THEN RAISE EXCEPTION 'Typ karty juz istnieje %', p_name;
END IF;

INSERT INTO accounts.card_types(name)
VALUES (p_name);

RAISE NOTICE 'Dodano typ karty %', p_name;

END;
$$;


/*
    --
    Procedura sp_AddCardStatus
    Opis: procedura dodajaca status karty
    Uwaga: problem przy migracji
    --
*/

CREATE PROCEDURE accounts.sp_AddCardStatus(
    p_name VARCHAR(30)
)
LANGUAGE plpgsql
AS $$
BEGIN

IF EXISTS (SELECT 1 FROM accounts.card_statuses
                    WHERE name = p_name)
    THEN RAISE EXCEPTION 'Typ statusu karty juz istnieje %', p_name;
END IF;

INSERT INTO accounts.card_statuses(name)
VALUES (p_name);

RAISE NOTICE 'Dodano typ statusu karty %', p_name;

END;
$$;


/*
    --
    Procedura sp_AddLoanStatus
    Opis: procedura dodajaca status kredytu
    Uwaga: problem przy migracji
    --
*/

CREATE PROCEDURE loans.sp_AddLoanStatus(
    p_name VARCHAR(30)
)
LANGUAGE plpgsql
AS $$
BEGIN

IF EXISTS (SELECT 1 FROM loans.loan_statuses
                    WHERE name = p_name)
    THEN RAISE EXCEPTION 'Typ statusu kredytu juz istnieje %', p_name;
END IF;

INSERT INTO loans.loan_statuses(name)
VALUES (p_name);

RAISE NOTICE 'Dodano typ statusu karty %', p_name;

END;
$$;


/*
    --
    Procedura sp_AddTransactionType
    Opis: procedura dodajaca typ transakcji
    Uwaga: problem przy migracji
    --
*/

CREATE PROCEDURE transactions.sp_AddTransactionType(
    p_name VARCHAR(30)
)
LANGUAGE plpgsql
AS $$
BEGIN

IF EXISTS (SELECT 1 FROM transactions.transaction_types
                    WHERE name = p_name)
    THEN RAISE EXCEPTION 'Typ transakcji juz istnieje %', p_name;
END IF;

INSERT INTO transactions.transaction_types(name)
VALUES (p_name);

RAISE NOTICE 'Dodano typ transakcji %', p_name;

END;
$$;


/*
    --
    Procedura sp_AddTransactionStatus
    Opis: procedura dodajaca status transakcji
    Uwaga: problem przy migracji
    --
*/

CREATE PROCEDURE transactions.sp_AddTransactionStatus(
    p_name VARCHAR(30)
)
LANGUAGE plpgsql
AS $$
BEGIN

IF EXISTS (SELECT 1 FROM transactions.transaction_statuses
                    WHERE name = p_name)
    THEN RAISE EXCEPTION 'Typ statusu transakcji juz istnieje %', p_name;
END IF;

INSERT INTO transactions.transaction_statuses(name)
VALUES (p_name);

RAISE NOTICE 'Dodano typ statusu transakcji %', p_name;

END;
$$;