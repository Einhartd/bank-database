-- ============================================================================
-- 02_create_tables_security.sql
-- Description: Creates tables for authentication, authorization, and auditing.
-- Schema: security
-- ============================================================================

CREATE TABLE "security"."user" (
  "user_id" SERIAL PRIMARY KEY,
  "employee_id" integer,
  "client_id" integer,
  "login" varchar(20) UNIQUE NOT NULL,
  "password" varchar(60) NOT NULL
);

CREATE TABLE "security"."loginHistory" (
  "login_id" SERIAL PRIMARY KEY,
  "user_id" integer NOT NULL,
  "action_type_id" integer NOT NULL,
  "login_time" timestamp NOT NULL,
  "ip_adres" varchar(45) NOT NULL
);