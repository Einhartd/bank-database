-- ============================================================================
-- 04_create_tables_shared.sql
-- Description: Creates shared tables like currencies and exchange rates.
-- Schema: shared
-- ============================================================================

CREATE TABLE "shared"."currency" (
  "currency_id" SERIAL PRIMARY KEY,
  "symbol" char(3) UNIQUE NOT NULL,
  "name" varchar(34) NOT NULL
);

CREATE TABLE "shared"."exchangeRates" (
  "ex_rate_id" SERIAL PRIMARY KEY,
  "curr_from_id" integer NOT NULL,
  "curr_to_id" integer NOT NULL,
  "ex_rate" decimal(10, 6) NOT NULL,
  "date" date NOT NULL
);