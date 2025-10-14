-- ============================================================================
-- Additional Constraints
-- ============================================================================
-- Description: Custom business logic constraints beyond foreign keys
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Constraint: User Role Validation
-- Description: Ensures that each user is either an employee OR a client,
--              but not both and not neither
-- Business Rule: A user account must be associated with exactly one role type
-- ----------------------------------------------------------------------------
ALTER TABLE "security"."user" 
  ADD CONSTRAINT chk_user_role
  CHECK (
    -- User is an employee (has employee_id but no client_id)
    ("employee_id" IS NOT NULL AND "client_id" IS NULL) OR
    -- User is a client (has client_id but no employee_id)
    ("employee_id" IS NULL AND "client_id" IS NOT NULL)
  );
