CREATE ROLE employee_role;

-- UPRAWNIENIA PRACOWNIKA
    -- Tworzenie konta klienta
    -- Zarządzanie danymi klienta (imie, nazwisko, pesel, email)
    -- Procesowanie wnioskow kredytowych
        -- Wygenerowanie wniosku kredytowego
        -- Zmiana statusu wniosku kredytowego
    -- Przegladanie innych pracownikow

-- === Schemat 'parties' (Klienci) ===
GRANT USAGE ON SCHEMA parties TO employee_role;
GRANT SELECT ON parties.client TO employee_role;
GRANT INSERT ON parties.client TO employee_role;
GRANT UPDATE (surname, email, name, pesel) ON parties.client TO employee_role;
GRANT SELECT ON parties.employee, parties.positions TO employee_role;

-- === Schemat 'security' (Użytkownicy) ===
GRANT USAGE ON SCHEMA security TO employee_role;
GRANT INSERT ON security.user TO employee_role;
GRANT SELECT (user_id, employee_id, client_id, login) ON security.user TO employee_role;
GRANT SELECT ON security."loginHistory", security.login_action_types TO employee_role;


-- === Schemat 'accounts' (Konta i Karty) ===
GRANT USAGE ON SCHEMA accounts TO employee_role;
GRANT SELECT ON accounts.account, accounts.card TO employee_role;
GRANT UPDATE (account_type_id) ON accounts.account TO employee_role;
GRANT UPDATE (card_status_id) ON accounts.card TO employee_role;
GRANT SELECT ON accounts.account_types, accounts.card_types, accounts.card_statuses TO employee_role;

-- === Schemat 'loans' (Kredyty) ===
GRANT USAGE ON SCHEMA loans TO employee_role;
GRANT SELECT, INSERT ON loans.loan TO employee_role;
GRANT UPDATE (loan_status_id) ON loans.loan TO employee_role;
GRANT SELECT ON loans.loan_statuses TO employee_role;

-- === Schematy 'transactions' i 'shared' (Tylko odczyt) ===
GRANT USAGE ON SCHEMA transactions, shared TO employee_role;
GRANT SELECT ON ALL TABLES IN SCHEMA transactions, shared TO employee_role;

-- === Uprawnienia do sekwencji ===
-- Pracownik musi mieć prawo do używania sekwencji w tabelach, do których może dodawać wiersze
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA parties, security, loans TO employee_role;
