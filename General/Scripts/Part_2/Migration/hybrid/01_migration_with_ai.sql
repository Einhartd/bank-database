create schema accounts
go

create schema loans
go

create schema parties
go

create schema security
go

create schema shared
go

create schema transactions
go


create table accounts.account_types
(
    account_type_id integer      not null identity(1,1)
        primary key clustered,
    name            nvarchar(30) not null
        unique
)
go

create table accounts.card_statuses
(
    card_status_id integer      not null identity(1,1)
        primary key clustered,
    name           nvarchar(30) not null
        unique
)
go

create table accounts.card_types
(
    card_type_id integer      not null identity(1,1)
        primary key clustered,
    name         nvarchar(30) not null
        unique
)
go

-- -------------------------------------------------------------------------------------
-- 2.2 Core Business Tables
-- -------------------------------------------------------------------------------------

create table parties.client
(
    client_id integer      not null identity(1,1)
        primary key clustered,
    name      nvarchar(20) not null,
    surname   nvarchar(60) not null,
    pesel     char(11)     not null
        unique,
    email     nvarchar(80) not null
        unique
)
go

-- Index for client search by name
create index idx_client_surname_name
    on parties.client (surname, name)
go

create table shared.currency
(
    currency_id integer      not null identity(1,1)
        primary key clustered,
    symbol      char(3)      not null
        unique,
    name        nvarchar(34) not null
)
go

create table accounts.account
(
    account_id      integer        not null identity(1,1)
        primary key clustered,
    client_id       integer        not null
        constraint fk_account_client foreign key
        references parties.client(client_id)
        on delete no action on update no action,
    currency_id     integer        not null
        constraint fk_account_currency foreign key
        references shared.currency(currency_id)
        on delete no action on update no action,
    account_type_id integer        not null
        constraint fk_account_type foreign key
        references accounts.account_types(account_type_id)
        on delete no action on update no action,
    number          varchar(34)    not null
        unique,
    balance         numeric(12, 2) not null
)
go

create index idx_account_client_id
    on accounts.account (client_id)
go

create index idx_account_currency_id
    on accounts.account (currency_id)
go

-- -------------------------------------------------------------------------------------
-- TRIGGERS for accounts.account
-- -------------------------------------------------------------------------------------

-- Trigger 1: Prevent negative balance
create trigger accounts.trg_protect_balance_on_update
    on accounts.account
    after update
    as
begin
    set nocount on;

    if exists (select 1 from inserted where balance < 0.00)
    begin
        declare @account_id int, @balance numeric(12,2), @msg nvarchar(255);
        select @account_id = account_id, @balance = balance
        from inserted
        where balance < 0.00;

        set @msg = N'Błąd: Saldo konta (ID: ' + cast(@account_id as nvarchar(10)) +
                   N') nie może być ujemne. Próba ustawienia na ' + cast(@balance as nvarchar(20)) + N'.';
        throw 50001, @msg, 1;
    end
end
go

-- Trigger 2: Prevent deletion of accounts with non-zero balance
create trigger accounts.trg_prevent_delete_active_acc
    on accounts.account
    instead of delete
    as
begin
    set nocount on;

    if exists (select 1 from deleted where balance != 0.00)
    begin
        declare @account_id int, @balance numeric(12,2), @msg nvarchar(255);
        select @account_id = account_id, @balance = balance
        from deleted
        where balance != 0.00;

        set @msg = N'Błąd: Saldo konta (ID: ' + cast(@account_id as nvarchar(10)) +
                   N') nie wynosi 0 (' + cast(@balance as nvarchar(20)) + N'). Nie można usunąć konta.';
        throw 50002, @msg, 1;
    end
    else
    begin
        delete from accounts.account
        where account_id in (select account_id from deleted);
    end
end
go

create table accounts.card
(
    card_id        integer     not null identity(1,1)
        primary key clustered,
    account_id     integer     not null
        constraint fk_card_account foreign key
        references accounts.account(account_id)
        on delete cascade on update cascade,  -- Delete cards when account is deleted
    card_type_id   integer     not null
        constraint fk_card_type foreign key
        references accounts.card_types(card_type_id)
        on delete no action on update no action,
    card_status_id integer     not null
        constraint fk_card_status foreign key
        references accounts.card_statuses(card_status_id)
        on delete no action on update no action,
    number         varchar(19) not null
        unique,
    expiry_date    date        not null
)
go

create index idx_card_account_id
    on accounts.card (account_id)
go

create table shared.exchangeRates
(
    ex_rate_id   integer        not null identity(1,1)
        primary key clustered,
    curr_from_id integer        not null
        constraint fk_exchange_from_currency foreign key
        references shared.currency(currency_id)
        on delete no action on update no action,
    curr_to_id   integer        not null
        constraint fk_exchange_to_currency foreign key
        references shared.currency(currency_id)
        on delete no action on update no action,
    ex_rate      numeric(10, 6) not null,
    date         date           not null
)
go

create index idx_exchangerates_pair_date
    on shared.exchangeRates (curr_from_id asc, curr_to_id asc, date desc)
go

create table loans.loan_statuses
(
    loan_status_id integer      not null identity(1,1)
        primary key clustered,
    name           nvarchar(30) not null
        unique
)
go

create table security.login_action_types
(
    action_type_id integer      not null identity(1,1)
        primary key clustered,
    name           nvarchar(30) not null
        unique
)
go

create table parties.positions
(
    position_id integer      not null identity(1,1)
        primary key clustered,
    name        nvarchar(30) not null
        unique
)
go

create table parties.employee
(
    employee_id integer      not null identity(1,1)
        primary key clustered,
    position_id integer      not null
        constraint fk_employee_position foreign key
        references parties.positions(position_id)
        on delete no action on update no action,
    name        nvarchar(20) not null,
    surname     nvarchar(60) not null
)
go

create index idx_employee_position_id
    on parties.employee (position_id)
go

create table loans.loan
(
    loan_id        integer        not null identity(1,1)
        primary key clustered,
    client_id      integer        not null
        constraint fk_loan_client foreign key
        references parties.client(client_id)
        on delete no action on update no action,
    loan_status_id integer        not null
        constraint fk_loan_status foreign key
        references loans.loan_statuses(loan_status_id)
        on delete no action on update no action,
    employee_id    integer        not null
        constraint fk_loan_employee foreign key
        references parties.employee(employee_id)
        on delete no action on update no action,
    amount         numeric(12, 2) not null,
    interest_rate  numeric(5, 2)  not null,
    start_date     date           not null
)
go

create index idx_loan_client_id
    on loans.loan (client_id)
go

create index idx_loan_employee_id
    on loans.loan (employee_id)
go

create table transactions.transaction_statuses
(
    transaction_status_id integer      not null identity(1,1)
        primary key clustered,
    name                  nvarchar(30) not null
        unique
)
go

create table transactions.transaction_types
(
    transaction_type_id integer      not null identity(1,1)
        primary key clustered,
    name                nvarchar(30) not null
        unique
)
go

create table transactions.[transaction]
(
    transaction_id        integer        not null identity(1,1)
        primary key clustered,
    sender_account_id     integer
        constraint fk_transaction_sender foreign key
        references accounts.account(account_id)
        on delete no action on update no action,
    receiver_account_id   integer
        constraint fk_transaction_receiver foreign key
        references accounts.account(account_id)
        on delete no action on update no action,
    card_id               integer
        constraint fk_transaction_card foreign key
        references accounts.card(card_id)
        on delete set null on update no action,
    exchange_id           integer
        constraint fk_transaction_exchange foreign key
        references shared.exchangeRates(ex_rate_id)
        on delete set null on update no action,
    transaction_type_id   integer        not null
        constraint fk_transaction_type foreign key
        references transactions.transaction_types(transaction_type_id)
        on delete no action on update no action,
    transaction_status_id integer        not null
        constraint fk_transaction_status foreign key
        references transactions.transaction_statuses(transaction_status_id)
        on delete no action on update no action,
    amount                numeric(12, 2) not null,
    time                  datetime2      not null,
    description           nvarchar(max),
    counterparty_name     nvarchar(100),
    counterparty_acc_num  varchar(34)
)
go

create index idx_transaction_sender_time
    on transactions.[transaction] (sender_account_id asc, time desc)
go

create index idx_transaction_receiver_time
    on transactions.[transaction] (receiver_account_id asc, time desc)
go

create index idx_transaction_card_id
    on transactions.[transaction] (card_id)
go

create index idx_exchange_id
    on transactions.[transaction] (exchange_id)
go

create table security.[user]
(
    user_id     integer      not null identity(1,1)
        primary key clustered,
    employee_id integer
        constraint fk_user_employee foreign key
        references parties.employee(employee_id)
        on delete no action on update no action,
    client_id   integer
        constraint fk_user_client foreign key
        references parties.client(client_id)
        on delete no action on update no action,
    login       nvarchar(20) not null
        unique,
    password    varchar(60)  not null,
    constraint chk_user_role
        check (((employee_id IS NOT NULL) AND (client_id IS NULL)) OR
               ((employee_id IS NULL) AND (client_id IS NOT NULL)))
)
go

create table security.loginHistory
(
    login_id       integer     not null identity(1,1)
        primary key clustered,
    user_id        integer     not null
        constraint fk_loginhistory_user foreign key
        references security.[user](user_id)
        on delete cascade on update cascade,  -- Delete login history when user is deleted
    action_type_id integer     not null
        constraint fk_loginhistory_action_type foreign key
        references security.login_action_types(action_type_id)
        on delete no action on update no action,
    login_time     datetime2   not null,
    ip_adres       varchar(45) not null
)
go

create index idx_loginhistory_user_time
    on security.loginHistory (user_id asc, login_time desc)
go

create index idx_user_employee_id
    on security.[user] (employee_id)
go

create index idx_user_client_id
    on security.[user] (client_id)
go

-- Purpose: Shows client's own accounts only (for client_role)
CREATE OR ALTER VIEW accounts.view_client_accounts AS
SELECT
    a.account_id,
    a.number,
    a.balance,
    c.symbol AS currency,
    at.name AS account_type,
    a.client_id,
    a.currency_id
FROM
    accounts.account a
JOIN
    shared.currency c ON a.currency_id = c.currency_id
JOIN
    accounts.account_types at ON a.account_type_id = at.account_type_id
WHERE
    a.client_id = (SELECT client_id FROM security.[user] WHERE login = USER_NAME());

-- Purpose: Shows client's own cards only (for client_role)
-- Widok na karty płatnicze klienta
CREATE OR ALTER VIEW accounts.view_client_cards AS
SELECT
    a_card.card_id,
    a_card.number,
    a_card.expiry_date,
    ct.name AS card_type,
    cs.name AS card_status
FROM
    accounts.card a_card
JOIN
    accounts.view_client_accounts client_acc ON a_card.account_id = client_acc.account_id
JOIN
    accounts.card_types ct ON a_card.card_type_id = ct.card_type_id
JOIN
    accounts.card_statuses cs ON a_card.card_status_id = cs.card_status_id;


CREATE OR ALTER VIEW parties.view_client_profile AS
SELECT
    client_id,
    name,
    surname,
    pesel,
    email
FROM
    parties.client
WHERE
    client_id = (SELECT client_id FROM security.[user] WHERE login = USER_NAME());

GRANT SELECT ON parties.view_client_profile TO client_role;


CREATE OR ALTER VIEW loans.view_client_loans AS
SELECT
    ll.loan_id,
    ll.amount,
    ll.interest_rate,
    ll.start_date,
    ls.name AS loan_status
FROM
    loans.loan ll
JOIN
    loans.loan_statuses ls ON ll.loan_status_id = ls.loan_status_id
WHERE
    client_id = (SELECT client_id FROM security.[user] WHERE login = USER_NAME());


CREATE OR ALTER VIEW transactions.view_client_transactions AS
SELECT
    t.transaction_id,
    t.amount,
    t.time,
    sender_acc.number AS sender_account_number,
    receiver_acc.number AS receiver_account_number,
    c.number AS card_number,
    ex.ex_rate AS exchange_rate,
    t.description,
    t.counterparty_name,
    t.counterparty_acc_num,
    tt.name AS transaction_type,
    ts.name AS transaction_status
FROM
    transactions.[transaction] t
LEFT JOIN
    accounts.account sender_acc ON t.sender_account_id = sender_acc.account_id
LEFT JOIN
    accounts.account receiver_acc ON t.receiver_account_id = receiver_acc.account_id
JOIN
    transactions.transaction_types tt ON t.transaction_type_id = tt.transaction_type_id
JOIN
    transactions.transaction_statuses ts ON t.transaction_status_id = ts.transaction_status_id
LEFT JOIN
    shared.[exchangeRates] ex ON t.exchange_id = ex.ex_rate_id
LEFT JOIN
    accounts.card c on t.card_id = c.card_id
WHERE
    t.sender_account_id IN (SELECT account_id FROM accounts.view_client_accounts)
    OR t.receiver_account_id IN (SELECT account_id FROM accounts.view_client_accounts)
    OR t.card_id IN (SELECT card_id FROM accounts.view_client_cards);


-- Purpose: Shows client's own card payments (for client_role)
CREATE OR ALTER VIEW transactions.view_client_card_payments AS
SELECT
    t.transaction_id,
    t.amount,
    t.time,
    c.number AS card_number,
    t.description,
    t.counterparty_name,
    tt.name AS transaction_type,
    ts.name AS transaction_status
FROM
    transactions.[transaction] t
JOIN
    transactions.transaction_types tt ON t.transaction_type_id = tt.transaction_type_id
JOIN
    transactions.transaction_statuses ts ON t.transaction_status_id = ts.transaction_status_id
LEFT JOIN
    accounts.card c on t.card_id = c.card_id
WHERE
    t.card_id IN (SELECT card_id FROM accounts.view_client_cards);

-- widok dla samych przelewow
CREATE OR ALTER VIEW transactions.view_client_transfers AS
SELECT
    t.transaction_id,
    t.amount,
    t.time,
    sender_acc.number    AS sender_account_number,
    receiver_acc.number  AS receiver_account_number,
    t.description,
    t.counterparty_name,
    t.counterparty_acc_num,
    tt.name AS transaction_type,
    ts.name AS transaction_status
FROM
    transactions.[transaction] t
LEFT JOIN
    accounts.account sender_acc ON t.sender_account_id = sender_acc.account_id
LEFT JOIN
    accounts.account receiver_acc ON t.receiver_account_id = receiver_acc.account_id
JOIN
    transactions.transaction_types tt ON t.transaction_type_id = tt.transaction_type_id
JOIN
    transactions.transaction_statuses ts ON t.transaction_status_id = ts.transaction_status_id
WHERE
    t.card_id IS NULL AND
    (t.sender_account_id IN (SELECT account_id FROM accounts.view_client_accounts)
     OR t.receiver_account_id IN (SELECT account_id FROM accounts.view_client_accounts));

-- ✓ Function 1: Currency Conversion
CREATE OR ALTER FUNCTION shared.fn_convert_currency(
    @p_amount DECIMAL(12, 2),
    @p_curr_from_id INT,
    @p_curr_to_id INT,
    @p_rate_date DATE
)
RETURNS DECIMAL(12, 2)
WITH EXECUTE AS OWNER -- Odpowiednik SECURITY DEFINER
AS
BEGIN
    DECLARE @v_rate DECIMAL(10, 6);

    -- 1. Jeśli waluty są te same, zwróć kwotę
    IF @p_curr_from_id = @p_curr_to_id
    BEGIN
        RETURN @p_amount;
    END

    -- 2. Znajdź najnowszy kurs BEZPOŚREDNI (na dzień p_rate_date lub wcześniej)
    SELECT TOP 1 @v_rate = er.ex_rate
    FROM shared.[exchangeRates] er
    WHERE er.curr_from_id = @p_curr_from_id
      AND er.curr_to_id = @p_curr_to_id
      AND er.date <= @p_rate_date
    ORDER BY er.date DESC;

    -- 3. Sprawdzenie, czy kurs bezpośredni został znaleziony
    --    (Odpowiednik 'IF FOUND' z plpgsql)
    IF @v_rate IS NOT NULL
    BEGIN
        RETURN ROUND(@p_amount * @v_rate, 2);
    END

    -- 4. Jeśli nie ma kursu bezpośredniego, znajdź najnowszy kurs ODWROTNY
    SELECT TOP 1 @v_rate = (1.0 / er.ex_rate)
    FROM shared.[exchangeRates] er
    WHERE er.curr_from_id = @p_curr_to_id
      AND er.curr_to_id = @p_curr_from_id
      AND er.date <= @p_rate_date
    ORDER BY er.date DESC;

    -- 5. Sprawdzenie, czy kurs odwrotny został znaleziony
    IF @v_rate IS NOT NULL
    BEGIN
        RETURN ROUND(@p_amount * @v_rate, 2);
    END
    -- UDF w MS SQL nie moze miec throw
    RETURN NULL;
END;

-- ✓ Function 2: Get Client Total Balance (Employee use)
create function accounts.fn_get_client_total_balance(
    @p_client_id integer,
    @p_target_currency_id integer,
    @p_calculation_date date
)
returns numeric(12,2)
as
begin
    declare @total numeric(12,2);

    select @total = coalesce(
        sum(
            shared.fn_convert_currency(
                a.balance,
                a.currency_id,
                @p_target_currency_id,
                @p_calculation_date
            )
        ),
        0.00
    )
    from accounts.account a
    where a.client_id = @p_client_id;

    return @total;
end
go

CREATE OR ALTER FUNCTION accounts.fn_get_my_total_balance(
    @p_target_currency_id INT,
    @p_calculation_date DATE
)
RETURNS DECIMAL(12,2)
AS
BEGIN
    DECLARE @v_total_balance DECIMAL(12, 2);

    SELECT @v_total_balance = COALESCE(
                SUM(
                    shared.fn_convert_currency(
                        v.balance,
                        v.currency_id,
                        @p_target_currency_id,
                        @p_calculation_date
                    )
                ),
                0.00)
    FROM
        accounts.view_client_accounts v;

    RETURN @v_total_balance;
END;

-- ✓ Procedure 1: Add Currency
create procedure shared.sp_add_currency(
    @p_symbol char(3),
    @p_name nvarchar(34)
)
as
begin
    set nocount on;

    -- Validation: Check if symbol already exists
    if exists (select 1 from shared.currency where symbol = @p_symbol)
    begin
        declare @error_symbol nvarchar(255);
        set @error_symbol = N'Waluta o symbolu "' + @p_symbol + N'" już istnieje.';
        throw 50001, @error_symbol, 1;
    end

    -- Validation: Check if name already exists
    if exists (select 1 from shared.currency where name = @p_name)
    begin
        declare @error_name nvarchar(255);
        set @error_name = N'Waluta o nazwie "' + @p_name + N'" już istnieje.';
        throw 50002, @error_name, 1;
    end

    insert into shared.currency (symbol, name)
    values (@p_symbol, @p_name);

    -- Success message
    print N'Umieszczono nową walutę: ' + @p_name + N' (' + @p_symbol + N')';
end
go

/*
 --
 Procedura: parties.sp_AddNewEmployee
 Opis: Dodaje nowego pracownika do bazy danych.
 --
*/
CREATE OR ALTER PROCEDURE parties.sp_add_new_employee
    @p_name VARCHAR(20),
    @p_surname VARCHAR(60),
    @p_position_name VARCHAR(30)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @v_position_id INT;
    DECLARE @ErrorMessage NVARCHAR(255);

    SELECT @v_position_id = position_id
    FROM parties.positions
    WHERE name = @p_position_name;

    IF @@ROWCOUNT = 0
    BEGIN
        SET @ErrorMessage = 'Nie można dodac pracownika. Stanowisko o nazwie "' + @p_position_name + '" nie istnieje.';
        THROW 50001, @ErrorMessage, 1;
        RETURN;
    END

    -- Dodaj pracownika
    INSERT INTO parties.employee (name, surname, position_id)
    VALUES (@p_name, @p_surname, @v_position_id);

    -- Odpowiednik RAISE NOTICE
    PRINT 'Pomyslnie dodano pracownika: ' + @p_name + ' ' + @p_surname + ' (Stanowisko: ' + @p_position_name + ')';
END;


GO

CREATE OR ALTER PROCEDURE shared.sp_add_symmetrical_exchange_rate
    @p_symbol_from CHAR(3),
    @p_symbol_to CHAR(3),
    @p_direct_rate DECIMAL(10, 6),
    @p_date DATE
AS
BEGIN

    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @v_inverse_rate DECIMAL(10, 6);
    DECLARE @v_count_direct INT;
    DECLARE @v_count_inverse INT;
    DECLARE @v_curr_from_id INT;
    DECLARE @v_curr_to_id INT;
    DECLARE @ErrorMessage NVARCHAR(500); -- Dla THROW

    -- Sprawdź walutę ŹRÓDŁOWĄ
    SELECT @v_curr_from_id = currency_id
    FROM shared.currency c
    WHERE c.symbol = @p_symbol_from;

    IF @v_curr_from_id IS NULL -- Odpowiednik 'IF NOT FOUND'
    BEGIN
        SET @ErrorMessage = 'Waluta zrodlowa o symbolu "' + @p_symbol_from + '" nie istnieje w tabeli shared.currency.';
        THROW 50001, @ErrorMessage, 1;
        RETURN;
    END

    -- Sprawdź walutę DOCELOWĄ
    SELECT @v_curr_to_id = currency_id
    FROM shared.currency c
    WHERE c.symbol = @p_symbol_to;

    IF @v_curr_to_id IS NULL -- Odpowiednik 'IF NOT FOUND'
    BEGIN
        SET @ErrorMessage = 'Waluta docelowa o symbolu "' + @p_symbol_to + '" nie istnieje w tabeli shared.currency.';
        THROW 50001, @ErrorMessage, 1;
        RETURN;
    END

    -- Sprawdź, czy waluty nie są te same
    IF @v_curr_from_id = @v_curr_to_id
    BEGIN
        SET @ErrorMessage = 'Nie mozna dodac kursu wymiany dla tej samej waluty (' + @p_symbol_from + ').';
        THROW 50001, @ErrorMessage, 1;
        RETURN;
    END

    -- Sprawdź kurs bezpośredni
    SELECT @v_count_direct = COUNT(*)
    FROM shared.[exchangeRates] er
    WHERE er.curr_from_id = @v_curr_from_id
      AND er.curr_to_id = @v_curr_to_id
      AND er.date = @p_date;

    -- Sprawdź kurs odwrotny
    SELECT @v_count_inverse = COUNT(*)
    FROM shared.[exchangeRates] er
    WHERE er.curr_from_id = @v_curr_to_id
      AND er.curr_to_id = @v_curr_from_id
      AND er.date = @p_date;

    IF @v_count_direct = 0 AND @v_count_inverse = 0
    BEGIN
        -- Scenariusz 1: Dodajemy oba kursy
        SET @v_inverse_rate = 1.0 / @p_direct_rate;
        -- transakcja w celu zapewnienia spojnosci (wszystko albo nic)
        BEGIN TRANSACTION;

            INSERT INTO shared.[exchangeRates] (curr_from_id, curr_to_id, ex_rate, date)
            VALUES (@v_curr_from_id, @v_curr_to_id, @p_direct_rate, @p_date);

            INSERT INTO shared.[exchangeRates] (curr_from_id, curr_to_id, ex_rate, date)
            VALUES (@v_curr_to_id, @v_curr_from_id, @v_inverse_rate, @p_date);

        COMMIT TRANSACTION;
        RETURN;
    END
    ELSE IF @v_count_direct = 1 AND @v_count_inverse = 1
    BEGIN
        -- Scenariusz 2: Kursy już istnieją (odpowiednik RAISE NOTICE)
        PRINT 'Kursy dla pary ' + @p_symbol_from + '/' + @p_symbol_to +
              ' na dzien ' + CONVERT(VARCHAR(10), @p_date, 120) + ' już sa. Pomijam.';
        RETURN;
    END
    ELSE
    BEGIN
        -- Scenariusz 3: Niespójność
        SET @ErrorMessage = 'NIESPOJNOSC DANYCH! Tabela exchangeRates jest uszkodzona dla pary ' +
                            @p_symbol_from + '/' + @p_symbol_to + ' na dzien ' +
                            CONVERT(VARCHAR(10), @p_date, 120) + '.';
        THROW 50001, @ErrorMessage, 1;
        RETURN;
    END
END;
GO

/*
--
Procedura: transactions.sp_CreateDomesticTransfer
Opis: Tworzy przelew krajowy.
--
*/
CREATE OR ALTER PROCEDURE transactions.sp_create_domestic_transfer
    @p_sender_account_id INTEGER,
    @p_receiver_account_number VARCHAR(34),
    @p_amount DECIMAL(12, 2),
    @p_description TEXT,
    @p_counterparty_name VARCHAR(100),
    @p_transaction_type_id INTEGER
AS
BEGIN
    /*
     * SET XACT_ABORT ON; -> Gwarantuje, że jeśli THROW lub inny błąd wystąpi,
     *
     * SET NOCOUNT ON;   -> Standardowa optymalizacja T-SQL.
     */
    SET XACT_ABORT ON;
    SET NOCOUNT ON;

    -- Dane nadawcy
    DECLARE @v_sender_balance DECIMAL(12, 2);
    DECLARE @v_sender_currency_id INTEGER;

    -- Dane odbiorcy
    DECLARE @v_receiver_account_id INTEGER;
    DECLARE @v_receiver_currency_id INTEGER;
    DECLARE @v_receiver_amount DECIMAL(12, 2);

    -- ID słownikowe
    DECLARE @v_status_completed_id INTEGER;
    DECLARE @v_status_pending_id INTEGER;

    -- Dane do logowania
    DECLARE @v_exchange_id INTEGER = NULL;
    DECLARE @ErrorMessage NVARCHAR(500);

    BEGIN TRANSACTION;

    -- Pobranie ID statusów (LIMIT 1 -> TOP 1)
    SELECT TOP 1 @v_status_completed_id = transaction_status_id
    FROM transactions.transaction_statuses WHERE name = N'Zakończona';

    SELECT TOP 1 @v_status_pending_id = transaction_status_id
    FROM transactions.transaction_statuses WHERE name = N'W toku';

    IF @v_status_completed_id IS NULL OR @v_status_pending_id IS NULL
    BEGIN
        THROW 50001, 'Krytyczny błąd: Nie zdefiniowano statusów transakcji (Zakończona/w toku).', 1;
    END

    -- 1. Walidacja kwoty
    IF @p_amount <= 0
    BEGIN
        SET @ErrorMessage = 'Kwota przelewu musi być dodatnia (' + CAST(@p_amount AS VARCHAR(20)) + ').';
        THROW 50001, @ErrorMessage, 1;
    END

    /* * PROBLEM MIGRACJI: FOR UPDATE -> WITH (UPDLOCK) *
     * Musimy też obsłużyć IF NOT FOUND */
    SELECT
        @v_sender_balance = balance,
        @v_sender_currency_id = currency_id
    FROM accounts.account WITH (UPDLOCK) -- Odpowiednik FOR UPDATE
    WHERE account_id = @p_sender_account_id;

    /* * PROBLEM MIGRACJI: IF NOT FOUND -> @@ROWCOUNT = 0 * */
    IF @@ROWCOUNT = 0
    BEGIN
        SET @ErrorMessage = 'Konto nadawcy (ID: ' + CAST(@p_sender_account_id AS VARCHAR(10)) + ') nie istnieje.';
        THROW 50001, @ErrorMessage, 1;
    END

    -- Sprawdzenie salda nadawcy
    IF @v_sender_balance < @p_amount
    BEGIN
        SET @ErrorMessage = 'Niewystarczające środki na koncie nadawcy (ID: ' + CAST(@p_sender_account_id AS VARCHAR(10)) +
                            '). Wymagane: ' + CAST(@p_amount AS VARCHAR(20)) +
                            ', Dostępne: ' + CAST(@v_sender_balance AS VARCHAR(20));
        THROW 50001, @ErrorMessage, 1;
    END

    -- Identyfikacja odbiorcy: Wewnętrzny czy Zewnętrzny?
    SELECT
        @v_receiver_account_id = account_id,
        @v_receiver_currency_id = currency_id
    FROM accounts.account
    WHERE number = @p_receiver_account_number;

    IF @v_receiver_account_id IS NOT NULL
    BEGIN

        IF @v_receiver_account_id = @p_sender_account_id
        BEGIN
            SET @ErrorMessage = 'Nie można wykonać przelewu na to samo konto (ID: ' + CAST(@p_sender_account_id AS VARCHAR(10)) + ').';
            THROW 50001, @ErrorMessage, 1;
        END

        -- 5A. Logika przewalutowania
        IF @v_sender_currency_id = @v_receiver_currency_id
        BEGIN
            SET @v_receiver_amount = @p_amount;
            SET @v_exchange_id = NULL;
        END
        ELSE
        BEGIN
            SET @v_receiver_amount = shared.fn_convert_currency(@p_amount, @v_sender_currency_id, @v_receiver_currency_id, CAST(GETDATE() AS DATE));

            /* Pobieramy ID kursu do logów (LIMIT 1 -> TOP 1) */
            SELECT TOP 1 @v_exchange_id = ex_rate_id
            FROM shared.[exchangeRates] -- " " -> [ ]
            WHERE curr_from_id = @v_sender_currency_id
              AND curr_to_id = @v_receiver_currency_id
              AND date <= CAST(GETDATE() AS DATE)
            ORDER BY
              date DESC,
              ex_rate_id DESC;
        END

        -- 6A. Wykonanie transakcji (Debet i Kredyt)
        UPDATE accounts.account
        SET balance = balance - @p_amount
        WHERE account_id = @p_sender_account_id;

        UPDATE accounts.account
        SET balance = balance + @v_receiver_amount
        WHERE account_id = @v_receiver_account_id;

        -- 7A. Logowanie transakcji (NOW() -> GETDATE())
        INSERT INTO transactions.[transaction] (
            sender_account_id, receiver_account_id, card_id, exchange_id,
            transaction_type_id, transaction_status_id, amount,
            time, description
        )
        VALUES (
            @p_sender_account_id, @v_receiver_account_id, NULL, @v_exchange_id,
            @p_transaction_type_id, @v_status_completed_id, @p_amount,
            GETDATE(), @p_description
        );
    END
    ELSE
    BEGIN

        IF @p_counterparty_name IS NULL OR @p_counterparty_name = ''
        BEGIN
            THROW 50001, 'Nazwa kontrahenta (odbiorcy) jest wymagana przy przelewach zewnętrznych.', 1;
        END

        UPDATE accounts.account
        SET balance = balance - @p_amount
        WHERE account_id = @p_sender_account_id;

        INSERT INTO transactions.[transaction] (
            sender_account_id, receiver_account_id, card_id, exchange_id,
            transaction_type_id, transaction_status_id, amount,
            time, description, counterparty_name, counterparty_acc_num
        )
        VALUES (
            @p_sender_account_id, NULL, NULL, NULL,
            @p_transaction_type_id, @v_status_pending_id, @p_amount,
            GETDATE(), @p_description, @p_counterparty_name, @p_receiver_account_number
        );
    END

    /* Jeśli wszystko się udało, zatwierdź transakcję */
    COMMIT TRANSACTION;
END;
GO

/*
--
Procedura: accounts.sp_IssueNewCard
Opis: Dodaje (wydaje) nową kartę płatniczą i przypisuje ją
do istniejącego konta klienta.
--
 */
CREATE OR ALTER PROCEDURE accounts.sp_issue_new_card
    @p_account_id INT,
    @p_card_type_name VARCHAR(30),
    @p_number VARCHAR(19),
    @p_expiry_date DATE
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @v_card_type_id INT;
    DECLARE @v_card_status_id INT;
    DECLARE @v_default_status_name VARCHAR(30) = 'Zablokowana';
    DECLARE @ErrorMessage NVARCHAR(500);

    SELECT @v_card_type_id = card_type_id
    FROM accounts.card_types
    WHERE name = @p_card_type_name;

    IF @v_card_type_id IS NULL
    BEGIN
        SET @ErrorMessage = 'Typ karty o nazwie "' + @p_card_type_name + '" nie istnieje.';
        THROW 50001, @ErrorMessage, 1;
        RETURN;
    END

    SELECT @v_card_status_id = card_status_id
    FROM accounts.card_statuses
    WHERE name = @v_default_status_name;

    IF @v_card_status_id IS NULL
    BEGIN
        SET @ErrorMessage = 'BŁĄD KONFIGURACJI: Domyślny status karty "' + @v_default_status_name + '" nie istnieje w bazie.';
        THROW 50001, @ErrorMessage, 1;
        RETURN;
    END

    /* Walidacja konta (logika IF NOT EXISTS jest identyczna) */
    IF NOT EXISTS (SELECT 1 FROM accounts.account WHERE account_id = @p_account_id)
    BEGIN
        SET @ErrorMessage = 'Konto o ID ' + CAST(@p_account_id AS VARCHAR(10)) + ' nie istnieje.';
        THROW 50001, @ErrorMessage, 1;
        RETURN;
    END

    /* Walidacja numeru karty (logika IF EXISTS jest identyczna) */
    IF EXISTS (SELECT 1 FROM accounts.card WHERE number = @p_number)
    BEGIN
        SET @ErrorMessage = 'Karta o numerze "' + @p_number + '" jest już zarejestrowana w systemie.';
        THROW 50001, @ErrorMessage, 1;
        RETURN;
    END

    /* "Problem" nr 3: Funkcja daty (CURRENT_DATE) */
    IF @p_expiry_date < CAST(GETDATE() AS DATE)
    BEGIN
        /* Używamy CONVERT, aby bezpiecznie sformatować datę w błędzie */
        SET @ErrorMessage = 'Nie można wydac karty. Podana data ważności (' + CONVERT(VARCHAR(10), @p_expiry_date, 120) + ') juz minela.';
        THROW 50001, @ErrorMessage, 1;
        RETURN;
    END

    /* Wstawienie danych (logika identyczna, inne zmienne) */
    INSERT INTO accounts.card (
        account_id,
        card_type_id,
        card_status_id,
        number,
        expiry_date
    )
    VALUES (
        @p_account_id,
        @v_card_type_id,
        @v_card_status_id,
        @p_number,
        @p_expiry_date
    );

    PRINT 'Pomyślnie wydano nową kartę (Typ: ' + @p_card_type_name +
          ') dla konta ID ' + CAST(@p_account_id AS VARCHAR(10)) +
          '. Karta oczekuje na aktywację.';
END;
GO

CREATE OR ALTER PROCEDURE accounts.sp_open_account
    @p_client_id INT,
    @p_currency_symbol CHAR(3),
    @p_account_type_name VARCHAR(30),
    @p_number VARCHAR(34),
    @p_initial_balance DECIMAL(12, 2) = 0.00
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @v_currency_id INT;
    DECLARE @v_account_type_id INT;
    DECLARE @ErrorMessage NVARCHAR(500);

    -- Wyszukaj walutę
    SELECT @v_currency_id = currency_id
    FROM shared.currency
    WHERE symbol = @p_currency_symbol;

    IF @v_currency_id IS NULL
    BEGIN
        SET @ErrorMessage = 'Waluta o symbolu "' + @p_currency_symbol + '" nie istnieje.';
        THROW 50001, @ErrorMessage, 1;
        RETURN;
    END

    -- Wyszukaj typ konta
    SELECT @v_account_type_id = account_type_id
    FROM accounts.account_types
    WHERE name = @p_account_type_name;

    /* Odpowiednik "IF NOT FOUND" w T-SQL */
    IF @v_account_type_id IS NULL
    BEGIN
        SET @ErrorMessage = 'Typ konta o nazwie "' + @p_account_type_name + '" nie istnieje.';
        THROW 50001, @ErrorMessage, 1;
        RETURN;
    END

    /* --- Pozostałe walidacje (logika IF EXISTS jest identyczna) --- */

    IF NOT EXISTS (SELECT 1 FROM parties.client WHERE client_id = @p_client_id)
    BEGIN
        SET @ErrorMessage = 'Klient o ID ' + CAST(@p_client_id AS VARCHAR(10)) + ' nie istnieje.';
        THROW 50001, @ErrorMessage, 1;
        RETURN;
    END

    IF EXISTS (SELECT 1 FROM accounts.account WHERE number = @p_number)
    BEGIN
        SET @ErrorMessage = 'Numer konta "' + @p_number + '" jest już zajęty.';
        THROW 50001, @ErrorMessage, 1;
        RETURN;
    END


    INSERT INTO accounts.account (client_id, currency_id, account_type_id, number, balance)
    VALUES (@p_client_id, @v_currency_id, @v_account_type_id, @p_number, @p_initial_balance);

    PRINT 'Pomyślnie utworzono konto ' + @p_number + ' (' + @p_account_type_name +
          ') dla klienta ID ' + CAST(@p_client_id AS VARCHAR(10)) + '.';

END;
GO


