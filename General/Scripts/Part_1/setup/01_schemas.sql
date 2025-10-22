-- ============================================================================
-- 01_create_schemas.sql
-- Description: Creates all domain-specific schemas for the banking database.
-- ============================================================================

CREATE SCHEMA IF NOT EXISTS "security";
CREATE SCHEMA IF NOT EXISTS "parties";
CREATE SCHEMA IF NOT EXISTS "accounts";
CREATE SCHEMA IF NOT EXISTS "transactions";
CREATE SCHEMA IF NOT EXISTS "loans";
CREATE SCHEMA IF NOT EXISTS "shared";