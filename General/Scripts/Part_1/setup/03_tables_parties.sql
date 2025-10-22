-- ============================================================================
-- 03_create_tables_parties.sql
-- Description: Creates tables for clients and employees.
-- Schema: parties
-- ============================================================================

CREATE TABLE "parties"."employee" (
  "employee_id" SERIAL PRIMARY KEY,
  "position_id" integer NOT NULL,
  "name" varchar(20) NOT NULL,
  "surname" varchar(60) NOT NULL
);

CREATE TABLE "parties"."client" (
  "client_id" SERIAL PRIMARY KEY,
  "name" varchar(20) NOT NULL,
  "surname" varchar(60) NOT NULL,
  "pesel" char(11) UNIQUE NOT NULL,
  "email" varchar(80) UNIQUE NOT NULL
);