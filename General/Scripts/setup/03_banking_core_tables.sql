-- ============================================================================
-- Banking Core Tables
-- ============================================================================
-- Description: Contains main business entities for banking operations
--              (employees, clients, accounts, cards, loans, transactions)
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Table: banking.employee
-- Description: Stores information about bank employees
-- ----------------------------------------------------------------------------
CREATE TABLE "banking"."employee" (
  "employee_id" SERIAL PRIMARY KEY,          -- Unique identifier for employee
  "position_id" integer NOT NULL,            -- Employee's position/role in the bank
  "name" varchar(20) NOT NULL,               -- Employee's first name
  "surname" varchar(60) NOT NULL             -- Employee's last name
);

-- ----------------------------------------------------------------------------
-- Table: banking.client
-- Description: Stores information about bank clients (customers)
-- Notes: PESEL is Polish national identification number (11 digits)
-- ----------------------------------------------------------------------------
CREATE TABLE "banking"."client" (
  "client_id" SERIAL PRIMARY KEY,            -- Unique identifier for client
  "name" varchar(20) NOT NULL,               -- Client's first name
  "surname" varchar(60) NOT NULL,            -- Client's last name
  "pesel" char(11) UNIQUE NOT NULL,          -- National ID number (must be unique)
  "email" varchar(80) UNIQUE NOT NULL        -- Email address (must be unique)
);

-- ----------------------------------------------------------------------------
-- Table: banking.account
-- Description: Bank accounts owned by clients
-- Notes: Supports multiple currencies and account types
-- ----------------------------------------------------------------------------
CREATE TABLE "banking"."account" (
  "account_id" SERIAL PRIMARY KEY,           -- Unique identifier for account
  "client_id" integer NOT NULL,              -- Account owner
  "currency_id" integer NOT NULL,            -- Account currency (USD, EUR, PLN, etc.)
  "account_type_id" integer NOT NULL,        -- Type of account (checking, savings, etc.)
  "number" varchar(34) UNIQUE NOT NULL,      -- Account number (supports IBAN format - max 34 chars)
  "balance" decimal(12,2) NOT NULL           -- Current account balance (precision: 2 decimal places)
);

-- ----------------------------------------------------------------------------
-- Table: banking.card
-- Description: Payment cards linked to accounts
-- Notes: Tracks card details, type, and current status
-- ----------------------------------------------------------------------------
CREATE TABLE "banking"."card" (
  "card_id" SERIAL PRIMARY KEY,              -- Unique identifier for card
  "account_id" integer NOT NULL,             -- Account linked to this card
  "card_type_id" integer NOT NULL,           -- Type of card (debit, credit, etc.)
  "card_status_id" integer NOT NULL,         -- Current status (active, blocked, expired, etc.)
  "number" varchar(19) UNIQUE NOT NULL,      -- Card number (13-19 digits per ISO/IEC 7812)
  "expiry_date" date NOT NULL                -- Card expiration date
);

-- ----------------------------------------------------------------------------
-- Table: banking.loan
-- Description: Loan agreements between the bank and clients
-- Notes: Tracks loan amount, interest rate, and approval status
-- ----------------------------------------------------------------------------
CREATE TABLE "banking"."loan" (
  "loan_id" SERIAL PRIMARY KEY,              -- Unique identifier for loan
  "client_id" integer NOT NULL,              -- Client who took the loan
  "loan_status_id" integer NOT NULL,         -- Current loan status (pending, approved, rejected, closed)
  "employee_id" integer NOT NULL,            -- Employee who processed the loan application
  "amount" decimal(12,2) NOT NULL,           -- Loan amount
  "interest_rate" decimal(5,2) NOT NULL,     -- Annual interest rate (e.g., 5.25 for 5.25%)
  "start_date" date NOT NULL                 -- Date when loan was disbursed
);

-- ----------------------------------------------------------------------------
-- Table: banking.transaction
-- Description: All financial transactions in the system
-- Notes: Supports multiple transaction types (transfers, withdrawals, deposits, etc.)
--        Can involve accounts, cards, and currency exchanges
-- ----------------------------------------------------------------------------
CREATE TABLE "banking"."transaction" (
  "transaction_id" SERIAL PRIMARY KEY,       -- Unique identifier for transaction
  "sender_account_id" integer,               -- Source account (NULL for deposits/card transactions)
  "receiver_account_id" integer,             -- Destination account (NULL for withdrawals/card transactions)
  "card_id" integer,                         -- Card used for transaction (if applicable)
  "exchange_id" integer,                     -- Exchange rate used (if currency conversion involved)
  "transaction_type_id" integer NOT NULL,    -- Type of transaction (transfer, withdrawal, etc.)
  "transaction_status_id" integer NOT NULL,  -- Status (pending, completed, failed, cancelled)
  "amount" decimal(12,2) NOT NULL,           -- Transaction amount
  "time" timestamp NOT NULL,                 -- Transaction timestamp
  "description" text,                        -- Optional transaction description/memo
  "counterparty_name" varchar(100),          -- Name of external party (for external transactions)
  "counterparty_acc_num" varchar(34)         -- Account number of external party
);

-- ----------------------------------------------------------------------------
-- Table: banking.currency
-- Description: Supported currencies in the system
-- Examples: USD (US Dollar), EUR (Euro), PLN (Polish Zloty)
-- ----------------------------------------------------------------------------
CREATE TABLE "banking"."currency" (
  "currency_id" SERIAL PRIMARY KEY,          -- Unique identifier for currency
  "symbol" char(3) UNIQUE NOT NULL,          -- ISO 4217 currency code (e.g., USD, EUR)
  "name" varchar(34) NOT NULL                -- Full currency name
);

-- ----------------------------------------------------------------------------
-- Table: banking.exchangeRates
-- Description: Currency exchange rates
-- Notes: Stores historical exchange rates for currency conversions
-- ----------------------------------------------------------------------------
CREATE TABLE "banking"."exchangeRates" (
  "ex_rate_id" SERIAL PRIMARY KEY,           -- Unique identifier for exchange rate entry
  "curr_from_id" integer NOT NULL,           -- Source currency
  "curr_to_id" integer NOT NULL,             -- Target currency
  "ex_rate" decimal(10,6) NOT NULL,          -- Exchange rate (6 decimal precision for accuracy)
  "date" date NOT NULL                       -- Date when this rate was valid
);
