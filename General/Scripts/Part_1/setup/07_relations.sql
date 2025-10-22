-- ============================================================================
-- 07_create_relations.sql
-- Description: Defines all FOREIGN KEY constraints between tables.
-- ============================================================================

-- Security relations
ALTER TABLE "security"."user" ADD FOREIGN KEY ("employee_id") REFERENCES "parties"."employee" ("employee_id");
ALTER TABLE "security"."user" ADD FOREIGN KEY ("client_id") REFERENCES "parties"."client" ("client_id");
ALTER TABLE "security"."loginHistory" ADD FOREIGN KEY ("user_id") REFERENCES "security"."user" ("user_id");
ALTER TABLE "security"."loginHistory" ADD FOREIGN KEY ("action_type_id") REFERENCES "security"."login_action_types" ("action_type_id");

-- Parties relations
ALTER TABLE "parties"."employee" ADD FOREIGN KEY ("position_id") REFERENCES "parties"."positions" ("position_id");

-- Accounts relations
ALTER TABLE "accounts"."account" ADD FOREIGN KEY ("client_id") REFERENCES "parties"."client" ("client_id");
ALTER TABLE "accounts"."account" ADD FOREIGN KEY ("currency_id") REFERENCES "shared"."currency" ("currency_id");
ALTER TABLE "accounts"."account" ADD FOREIGN KEY ("account_type_id") REFERENCES "accounts"."account_types" ("account_type_id");
ALTER TABLE "accounts"."card" ADD FOREIGN KEY ("account_id") REFERENCES "accounts"."account" ("account_id");
ALTER TABLE "accounts"."card" ADD FOREIGN KEY ("card_type_id") REFERENCES "accounts"."card_types" ("card_type_id");
ALTER TABLE "accounts"."card" ADD FOREIGN KEY ("card_status_id") REFERENCES "accounts"."card_statuses" ("card_status_id");

-- Loans relations
ALTER TABLE "loans"."loan" ADD FOREIGN KEY ("client_id") REFERENCES "parties"."client" ("client_id");
ALTER TABLE "loans"."loan" ADD FOREIGN KEY ("employee_id") REFERENCES "parties"."employee" ("employee_id");
ALTER TABLE "loans"."loan" ADD FOREIGN KEY ("loan_status_id") REFERENCES "loans"."loan_statuses" ("loan_status_id");

-- Transactions relations
ALTER TABLE "transactions"."transaction" ADD FOREIGN KEY ("sender_account_id") REFERENCES "accounts"."account" ("account_id");
ALTER TABLE "transactions"."transaction" ADD FOREIGN KEY ("receiver_account_id") REFERENCES "accounts"."account" ("account_id");
ALTER TABLE "transactions"."transaction" ADD FOREIGN KEY ("card_id") REFERENCES "accounts"."card" ("card_id");
ALTER TABLE "transactions"."transaction" ADD FOREIGN KEY ("exchange_id") REFERENCES "shared"."exchangeRates" ("ex_rate_id");
ALTER TABLE "transactions"."transaction" ADD FOREIGN KEY ("transaction_type_id") REFERENCES "transactions"."transaction_types" ("transaction_type_id");
ALTER TABLE "transactions"."transaction" ADD FOREIGN KEY ("transaction_status_id") REFERENCES "transactions"."transaction_statuses" ("transaction_status_id");

-- Shared relations
ALTER TABLE "shared"."exchangeRates" ADD FOREIGN KEY ("curr_from_id") REFERENCES "shared"."currency" ("currency_id");
ALTER TABLE "shared"."exchangeRates" ADD FOREIGN KEY ("curr_to_id") REFERENCES "shared"."currency" ("currency_id");