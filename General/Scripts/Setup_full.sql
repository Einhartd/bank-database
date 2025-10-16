/*
 * =================================================================================
 * Schemat Bazy Danych Systemu Bankowego
 * Wersja z podziałem na schematy domenowe
 * =================================================================================
 */

-- Krok 1: Tworzenie schematów
CREATE SCHEMA IF NOT EXISTS security;
CREATE SCHEMA IF NOT EXISTS parties;
CREATE SCHEMA IF NOT EXISTS accounts;
CREATE SCHEMA IF NOT EXISTS transactions;
CREATE SCHEMA IF NOT EXISTS loans;
CREATE SCHEMA IF NOT EXISTS shared;

---
-- Krok 2: Tworzenie tabel w odpowiednich schematach
---

-- Schemat: security (Uwierzytelnianie i autoryzacja)
CREATE TABLE security."user" (
  "user_id" SERIAL PRIMARY KEY,
  "employee_id" integer,
  "client_id" integer,
  "login" varchar(20) UNIQUE NOT NULL,
  "password" varchar(60) NOT NULL
);

CREATE TABLE security."loginHistory" (
  "login_id" SERIAL PRIMARY KEY,
  "user_id" integer NOT NULL,
  "action_type_id" integer NOT NULL,
  "login_time" timestamp NOT NULL,
  "ip_adres" varchar(45) NOT NULL
);

CREATE TABLE security."login_action_types" (
  "action_type_id" SERIAL PRIMARY KEY,
  "name" varchar(30) UNIQUE NOT NULL
);


-- Schemat: parties (Dane o podmiotach: klienci i pracownicy)
CREATE TABLE parties."employee" (
  "employee_id" SERIAL PRIMARY KEY,
  "position_id" integer NOT NULL,
  "name" varchar(20) NOT NULL,
  "surname" varchar(60) NOT NULL
);

CREATE TABLE parties."client" (
  "client_id" SERIAL PRIMARY KEY,
  "name" varchar(20) NOT NULL,
  "surname" varchar(60) NOT NULL,
  "pesel" char(11) UNIQUE NOT NULL,
  "email" varchar(80) UNIQUE NOT NULL
);

CREATE TABLE parties."positions" (
  "position_id" SERIAL PRIMARY KEY,
  "name" varchar(30) UNIQUE NOT NULL
);


-- Schemat: accounts (Konta bankowe i karty płatnicze)
CREATE TABLE accounts."account" (
  "account_id" SERIAL PRIMARY KEY,
  "client_id" integer NOT NULL,
  "currency_id" integer NOT NULL,
  "account_type_id" integer NOT NULL,
  "number" varchar(34) UNIQUE NOT NULL,
  "balance" decimal(12,2) NOT NULL
);

CREATE TABLE accounts."card" (
  "card_id" SERIAL PRIMARY KEY,
  "account_id" integer NOT NULL,
  "card_type_id" integer NOT NULL,
  "card_status_id" integer NOT NULL,
  "number" varchar(19) UNIQUE NOT NULL,
  "expiry_date" date NOT NULL
);

CREATE TABLE accounts."account_types" (
  "account_type_id" SERIAL PRIMARY KEY,
  "name" varchar(30) UNIQUE NOT NULL
);

CREATE TABLE accounts."card_types" (
  "card_type_id" SERIAL PRIMARY KEY,
  "name" varchar(30) UNIQUE NOT NULL
);

CREATE TABLE accounts."card_statuses" (
  "card_status_id" SERIAL PRIMARY KEY,
  "name" varchar(30) UNIQUE NOT NULL
);


-- Schemat: loans (Kredyty)
CREATE TABLE loans."loan" (
  "loan_id" SERIAL PRIMARY KEY,
  "client_id" integer NOT NULL,
  "loan_status_id" integer NOT NULL,
  "employee_id" integer NOT NULL,
  "amount" decimal(12,2) NOT NULL,
  "interest_rate" decimal(5,2) NOT NULL,
  "start_date" date NOT NULL
);

CREATE TABLE loans."loan_statuses" (
  "loan_status_id" SERIAL PRIMARY KEY,
  "name" varchar(30) UNIQUE NOT NULL
);


-- Schemat: transactions (Operacje finansowe)
CREATE TABLE transactions."transaction" (
  "transaction_id" SERIAL PRIMARY KEY,
  "sender_account_id" integer,
  "receiver_account_id" integer,
  "card_id" integer,
  "exchange_id" integer,
  "transaction_type_id" integer NOT NULL,
  "transaction_status_id" integer NOT NULL,
  "amount" decimal(12,2) NOT NULL,
  "time" timestamp NOT NULL,
  "description" text,
  "counterparty_name" varchar(100),
  "counterparty_acc_num" varchar(34)
);

CREATE TABLE transactions."transaction_types" (
  "transaction_type_id" SERIAL PRIMARY KEY,
  "name" varchar(30) UNIQUE NOT NULL
);

CREATE TABLE transactions."transaction_statuses" (
  "transaction_status_id" SERIAL PRIMARY KEY,
  "name" varchar(30) UNIQUE NOT NULL
);


-- Schemat: shared (Współdzielone słowniki, np. waluty)
CREATE TABLE shared."currency" (
  "currency_id" SERIAL PRIMARY KEY,
  "symbol" char(3) UNIQUE NOT NULL,
  "name" varchar(34) NOT NULL
);

CREATE TABLE shared."exchangeRates" (
  "ex_rate_id" SERIAL PRIMARY KEY,
  "curr_from_id" integer NOT NULL,
  "curr_to_id" integer NOT NULL,
  "ex_rate" decimal(10,6) NOT NULL,
  "date" date NOT NULL
);

---
-- Krok 3: Definiowanie relacji (kluczy obcych) z uwzględnieniem schematów
---

-- Relacje w schemacie 'security'
ALTER TABLE security."user" ADD FOREIGN KEY ("employee_id") REFERENCES parties."employee" ("employee_id");
ALTER TABLE security."user" ADD FOREIGN KEY ("client_id") REFERENCES parties."client" ("client_id");
ALTER TABLE security."loginHistory" ADD FOREIGN KEY ("user_id") REFERENCES security."user" ("user_id");
ALTER TABLE security."loginHistory" ADD FOREIGN KEY ("action_type_id") REFERENCES security."login_action_types" ("action_type_id");

-- Relacje w schemacie 'parties'
ALTER TABLE parties."employee" ADD FOREIGN KEY ("position_id") REFERENCES parties."positions" ("position_id");

-- Relacje w schemacie 'accounts'
ALTER TABLE accounts."account" ADD FOREIGN KEY ("client_id") REFERENCES parties."client" ("client_id");
ALTER TABLE accounts."account" ADD FOREIGN KEY ("currency_id") REFERENCES shared."currency" ("currency_id");
ALTER TABLE accounts."account" ADD FOREIGN KEY ("account_type_id") REFERENCES accounts."account_types" ("account_type_id");
ALTER TABLE accounts."card" ADD FOREIGN KEY ("account_id") REFERENCES accounts."account" ("account_id");
ALTER TABLE accounts."card" ADD FOREIGN KEY ("card_type_id") REFERENCES accounts."card_types" ("card_type_id");
ALTER TABLE accounts."card" ADD FOREIGN KEY ("card_status_id") REFERENCES accounts."card_statuses" ("card_status_id");

-- Relacje w schemacie 'loans'
ALTER TABLE loans."loan" ADD FOREIGN KEY ("client_id") REFERENCES parties."client" ("client_id");
ALTER TABLE loans."loan" ADD FOREIGN KEY ("employee_id") REFERENCES parties."employee" ("employee_id");
ALTER TABLE loans."loan" ADD FOREIGN KEY ("loan_status_id") REFERENCES loans."loan_statuses" ("loan_status_id");

-- Relacje w schemacie 'transactions'
ALTER TABLE transactions."transaction" ADD FOREIGN KEY ("sender_account_id") REFERENCES accounts."account" ("account_id");
ALTER TABLE transactions."transaction" ADD FOREIGN KEY ("receiver_account_id") REFERENCES accounts."account" ("account_id");
ALTER TABLE transactions."transaction" ADD FOREIGN KEY ("card_id") REFERENCES accounts."card" ("card_id");
ALTER TABLE transactions."transaction" ADD FOREIGN KEY ("exchange_id") REFERENCES shared."exchangeRates" ("ex_rate_id");
ALTER TABLE transactions."transaction" ADD FOREIGN KEY ("transaction_type_id") REFERENCES transactions."transaction_types" ("transaction_type_id");
ALTER TABLE transactions."transaction" ADD FOREIGN KEY ("transaction_status_id") REFERENCES transactions."transaction_statuses" ("transaction_status_id");

-- Relacje w schemacie 'shared'
ALTER TABLE shared."exchangeRates" ADD FOREIGN KEY ("curr_from_id") REFERENCES shared."currency" ("currency_id");
ALTER TABLE shared."exchangeRates" ADD FOREIGN KEY ("curr_to_id") REFERENCES shared."currency" ("currency_id");

---
-- Krok 4: Definiowanie ograniczeń (constraints)
---

-- Ograniczenie w tabeli 'user' zapewniające, że użytkownik jest albo pracownikiem, albo klientem
ALTER TABLE security."user" ADD CONSTRAINT chk_user_role
CHECK (
    ("employee_id" IS NOT NULL AND "client_id" IS NULL) OR
    ("employee_id" IS NULL AND "client_id" IS NOT NULL)
);