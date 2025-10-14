-- ============================================================================
-- Foreign Key Constraints
-- ============================================================================
-- Description: Establishes referential integrity between tables
-- Notes: Foreign keys ensure data consistency across related tables
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Security Schema Foreign Keys
-- ----------------------------------------------------------------------------

-- User must reference either an employee or a client
ALTER TABLE "security"."user" 
  ADD FOREIGN KEY ("employee_id") 
  REFERENCES "banking"."employee" ("employee_id");

ALTER TABLE "security"."user" 
  ADD FOREIGN KEY ("client_id") 
  REFERENCES "banking"."client" ("client_id");

-- Login history must reference a valid user and action type
ALTER TABLE "security"."loginHistory" 
  ADD FOREIGN KEY ("user_id") 
  REFERENCES "security"."user" ("user_id");

ALTER TABLE "security"."loginHistory" 
  ADD FOREIGN KEY ("action_type_id") 
  REFERENCES "security"."login_action_types" ("action_type_id");

-- ----------------------------------------------------------------------------
-- Banking Schema Foreign Keys - Employee and Client Relations
-- ----------------------------------------------------------------------------

-- Employee must have a valid position
ALTER TABLE "banking"."employee" 
  ADD FOREIGN KEY ("position_id") 
  REFERENCES "banking"."positions" ("position_id");

-- ----------------------------------------------------------------------------
-- Banking Schema Foreign Keys - Account Relations
-- ----------------------------------------------------------------------------

-- Account must belong to a client and have valid currency and type
ALTER TABLE "banking"."account" 
  ADD FOREIGN KEY ("client_id") 
  REFERENCES "banking"."client" ("client_id");

ALTER TABLE "banking"."account" 
  ADD FOREIGN KEY ("currency_id") 
  REFERENCES "banking"."currency" ("currency_id");

ALTER TABLE "banking"."account" 
  ADD FOREIGN KEY ("account_type_id") 
  REFERENCES "banking"."account_types" ("account_type_id");

-- ----------------------------------------------------------------------------
-- Banking Schema Foreign Keys - Card Relations
-- ----------------------------------------------------------------------------

-- Card must be linked to an account and have valid type and status
ALTER TABLE "banking"."card" 
  ADD FOREIGN KEY ("account_id") 
  REFERENCES "banking"."account" ("account_id");

ALTER TABLE "banking"."card" 
  ADD FOREIGN KEY ("card_type_id") 
  REFERENCES "banking"."card_types" ("card_type_id");

ALTER TABLE "banking"."card" 
  ADD FOREIGN KEY ("card_status_id") 
  REFERENCES "banking"."card_statuses" ("card_status_id");

-- ----------------------------------------------------------------------------
-- Banking Schema Foreign Keys - Loan Relations
-- ----------------------------------------------------------------------------

-- Loan must belong to a client, be processed by an employee, and have a status
ALTER TABLE "banking"."loan" 
  ADD FOREIGN KEY ("client_id") 
  REFERENCES "banking"."client" ("client_id");

ALTER TABLE "banking"."loan" 
  ADD FOREIGN KEY ("employee_id") 
  REFERENCES "banking"."employee" ("employee_id");

ALTER TABLE "banking"."loan" 
  ADD FOREIGN KEY ("loan_status_id") 
  REFERENCES "banking"."loan_statuses" ("loan_status_id");

-- ----------------------------------------------------------------------------
-- Banking Schema Foreign Keys - Transaction Relations
-- ----------------------------------------------------------------------------

-- Transaction can reference sender/receiver accounts (optional for some transaction types)
ALTER TABLE "banking"."transaction" 
  ADD FOREIGN KEY ("sender_account_id") 
  REFERENCES "banking"."account" ("account_id");

ALTER TABLE "banking"."transaction" 
  ADD FOREIGN KEY ("receiver_account_id") 
  REFERENCES "banking"."account" ("account_id");

-- Transaction can involve a card
ALTER TABLE "banking"."transaction" 
  ADD FOREIGN KEY ("card_id") 
  REFERENCES "banking"."card" ("card_id");

-- Transaction can involve currency exchange
ALTER TABLE "banking"."transaction" 
  ADD FOREIGN KEY ("exchange_id") 
  REFERENCES "banking"."exchangeRates" ("ex_rate_id");

-- Transaction must have a valid type and status
ALTER TABLE "banking"."transaction" 
  ADD FOREIGN KEY ("transaction_type_id") 
  REFERENCES "banking"."transaction_types" ("transaction_type_id");

ALTER TABLE "banking"."transaction" 
  ADD FOREIGN KEY ("transaction_status_id") 
  REFERENCES "banking"."transaction_statuses" ("transaction_status_id");

-- ----------------------------------------------------------------------------
-- Banking Schema Foreign Keys - Exchange Rate Relations
-- ----------------------------------------------------------------------------

-- Exchange rate must reference valid currencies for both source and target
ALTER TABLE "banking"."exchangeRates" 
  ADD FOREIGN KEY ("curr_from_id") 
  REFERENCES "banking"."currency" ("currency_id");

ALTER TABLE "banking"."exchangeRates" 
  ADD FOREIGN KEY ("curr_to_id") 
  REFERENCES "banking"."currency" ("currency_id");
