-- ============================================================================
-- Security Schema Tables
-- ============================================================================
-- Description: Contains tables for user authentication, authorization,
--              and login tracking
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Table: security.user
-- Description: Stores user credentials and links to either employees or clients
-- Notes: Each user must be either an employee OR a client (enforced by constraint)
-- ----------------------------------------------------------------------------
CREATE TABLE "security"."user" (
  "user_id" SERIAL PRIMARY KEY,              -- Unique identifier for the user
  "employee_id" integer,                     -- Reference to employee (if user is an employee)
  "client_id" integer,                       -- Reference to client (if user is a client)
  "login" varchar(20) UNIQUE NOT NULL,       -- Unique login name (username)
  "password" varchar(60) NOT NULL            -- Hashed password (e.g., bcrypt hash)
);

-- ----------------------------------------------------------------------------
-- Table: security.loginHistory
-- Description: Audit trail of user login activities
-- Notes: Tracks both successful logins and failed attempts
-- ----------------------------------------------------------------------------
CREATE TABLE "security"."loginHistory" (
  "login_id" SERIAL PRIMARY KEY,             -- Unique identifier for login event
  "user_id" integer NOT NULL,                -- User who performed the action
  "action_type_id" integer NOT NULL,         -- Type of action (login, logout, failed attempt, etc.)
  "login_time" timestamp NOT NULL,           -- Timestamp of the action
  "ip_adres" varchar(45) NOT NULL            -- IP address (supports both IPv4 and IPv6)
);

-- ----------------------------------------------------------------------------
-- Table: security.login_action_types
-- Description: Reference table for types of login actions
-- Examples: 'LOGIN_SUCCESS', 'LOGIN_FAILED', 'LOGOUT', 'PASSWORD_RESET'
-- ----------------------------------------------------------------------------
CREATE TABLE "security"."login_action_types" (
  "action_type_id" SERIAL PRIMARY KEY,       -- Unique identifier for action type
  "name" varchar(30) UNIQUE NOT NULL         -- Descriptive name of the action type
);
