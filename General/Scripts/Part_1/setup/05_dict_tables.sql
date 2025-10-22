-- ============================================================================
-- 05_create_tables_dictionary.sql
-- Description: Creates all reference/dictionary tables for statuses and types.
-- ============================================================================

-- Security
CREATE TABLE "security"."login_action_types" (
  "action_type_id" SERIAL PRIMARY KEY, "name" varchar(30) UNIQUE NOT NULL
);

-- Parties
CREATE TABLE "parties"."positions" (
  "position_id" SERIAL PRIMARY KEY, "name" varchar(30) UNIQUE NOT NULL
);

-- Accounts
CREATE TABLE "accounts"."account_types" (
  "account_type_id" SERIAL PRIMARY KEY, "name" varchar(30) UNIQUE NOT NULL
);
CREATE TABLE "accounts"."card_types" (
  "card_type_id" SERIAL PRIMARY KEY, "name" varchar(30) UNIQUE NOT NULL
);
CREATE TABLE "accounts"."card_statuses" (
  "card_status_id" SERIAL PRIMARY KEY, "name" varchar(30) UNIQUE NOT NULL
);

-- Loans
CREATE TABLE "loans"."loan_statuses" (
  "loan_status_id" SERIAL PRIMARY KEY, "name" varchar(30) UNIQUE NOT NULL
);

-- Transactions
CREATE TABLE "transactions"."transaction_types" (
  "transaction_type_id" SERIAL PRIMARY KEY, "name" varchar(30) UNIQUE NOT NULL
);
CREATE TABLE "transactions"."transaction_statuses" (
  "transaction_status_id" SERIAL PRIMARY KEY, "name" varchar(30) UNIQUE NOT NULL
);