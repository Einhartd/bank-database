-- ============================================================================
-- 08_create_constraints.sql
-- Description: Defines additional CHECK constraints for data integrity.
-- ============================================================================

ALTER TABLE "security"."user" ADD CONSTRAINT "chk_user_role"
CHECK (
    ("employee_id" IS NOT NULL AND "client_id" IS NULL) OR
    ("employee_id" IS NULL AND "client_id" IS NOT NULL)
);