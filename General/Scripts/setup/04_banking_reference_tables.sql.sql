-- ============================================================================
-- Banking Reference/Lookup Tables
-- ============================================================================
-- Description: Contains reference data for various enumerations and types
--              These tables store allowed values for various categorical fields
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Table: banking.positions
-- Description: Employee positions/roles within the bank
-- Examples: 'Manager', 'Teller', 'Loan Officer', 'Branch Manager'
-- ----------------------------------------------------------------------------
CREATE TABLE "banking"."positions" (
  "position_id" SERIAL PRIMARY KEY,          -- Unique identifier for position
  "name" varchar(30) UNIQUE NOT NULL         -- Position name
);

-- ----------------------------------------------------------------------------
-- Table: banking.account_types
-- Description: Types of bank accounts
-- Examples: 'Checking', 'Savings', 'Business', 'Student'
-- ----------------------------------------------------------------------------
CREATE TABLE "banking"."account_types" (
  "account_type_id" SERIAL PRIMARY KEY,      -- Unique identifier for account type
  "name" varchar(30) UNIQUE NOT NULL         -- Account type name
);

-- ----------------------------------------------------------------------------
-- Table: banking.card_types
-- Description: Types of payment cards
-- Examples: 'Debit', 'Credit', 'Prepaid', 'Virtual'
-- ----------------------------------------------------------------------------
CREATE TABLE "banking"."card_types" (
  "card_type_id" SERIAL PRIMARY KEY,         -- Unique identifier for card type
  "name" varchar(30) UNIQUE NOT NULL         -- Card type name
);

-- ----------------------------------------------------------------------------
-- Table: banking.card_statuses
-- Description: Possible statuses for payment cards
-- Examples: 'Active', 'Blocked', 'Expired', 'Lost', 'Stolen', 'Cancelled'
-- ----------------------------------------------------------------------------
CREATE TABLE "banking"."card_statuses" (
  "card_status_id" SERIAL PRIMARY KEY,       -- Unique identifier for card status
  "name" varchar(30) UNIQUE NOT NULL         -- Card status name
);

-- ----------------------------------------------------------------------------
-- Table: banking.loan_statuses
-- Description: Possible statuses for loan applications and agreements
-- Examples: 'Pending', 'Approved', 'Rejected', 'Active', 'Closed', 'Default'
-- ----------------------------------------------------------------------------
CREATE TABLE "banking"."loan_statuses" (
  "loan_status_id" SERIAL PRIMARY KEY,       -- Unique identifier for loan status
  "name" varchar(30) UNIQUE NOT NULL         -- Loan status name
);

-- ----------------------------------------------------------------------------
-- Table: banking.transaction_types
-- Description: Types of financial transactions
-- Examples: 'Transfer', 'Withdrawal', 'Deposit', 'Card Payment', 'ATM Withdrawal'
-- ----------------------------------------------------------------------------
CREATE TABLE "banking"."transaction_types" (
  "transaction_type_id" SERIAL PRIMARY KEY,  -- Unique identifier for transaction type
  "name" varchar(30) UNIQUE NOT NULL         -- Transaction type name
);

-- ----------------------------------------------------------------------------
-- Table: banking.transaction_statuses
-- Description: Possible statuses for transactions
-- Examples: 'Pending', 'Completed', 'Failed', 'Cancelled', 'Reversed'
-- ----------------------------------------------------------------------------
CREATE TABLE "banking"."transaction_statuses" (
  "transaction_status_id" SERIAL PRIMARY KEY, -- Unique identifier for transaction status
  "name" varchar(30) UNIQUE NOT NULL          -- Transaction status name
);
