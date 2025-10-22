-- ============================================================================
-- 06_create_tables_domain.sql
-- Description: Creates the core business logic tables.
-- Schemas: accounts, loans, transactions
-- ============================================================================

CREATE TABLE "accounts"."account" (
  "account_id" SERIAL PRIMARY KEY,
  "client_id" integer NOT NULL,
  "currency_id" integer NOT NULL,
  "account_type_id" integer NOT NULL,
  "number" varchar(34) UNIQUE NOT NULL,
  "balance" decimal(12, 2) NOT NULL
);

CREATE TABLE "accounts"."card" (
  "card_id" SERIAL PRIMARY KEY,
  "account_id" integer NOT NULL,
  "card_type_id" integer NOT NULL,
  "card_status_id" integer NOT NULL,
  "number" varchar(19) UNIQUE NOT NULL,
  "expiry_date" date NOT NULL
);

CREATE TABLE "loans"."loan" (
  "loan_id" SERIAL PRIMARY KEY,
  "client_id" integer NOT NULL,
  "loan_status_id" integer NOT NULL,
  "employee_id" integer NOT NULL,
  "amount" decimal(12, 2) NOT NULL,
  "interest_rate" decimal(5, 2) NOT NULL,
  "start_date" date NOT NULL
);

CREATE TABLE "transactions"."transaction" (
  "transaction_id" SERIAL PRIMARY KEY,
  "sender_account_id" integer,
  "receiver_account_id" integer,
  "card_id" integer,
  "exchange_id" integer,
  "transaction_type_id" integer NOT NULL,
  "transaction_status_id" integer NOT NULL,
  "amount" decimal(12, 2) NOT NULL,
  "time" timestamp NOT NULL,
  "description" text,
  "counterparty_name" varchar(100),
  "counterparty_acc_num" varchar(34)
);