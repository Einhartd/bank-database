USE bank_db_manual;

-- security tables
CREATE TABLE [security].[user] (
    [user_id]       INT IDENTITY(1,1) PRIMARY KEY,
    [employee_id]   INT,
    [client_id]     INT,
    [login]         VARCHAR(20) UNIQUE NOT NULL,
    [password]      VARCHAR(60) NOT NULL
);

ALTER TABLE [security].[user]
ADD CONSTRAINT chk_user_role CHECK (
    (
        ([employee_id] IS NOT NULL) AND ([client_id] IS NULL)
    )
    OR
    (
        ([employee_id] IS NULL) AND ([client_id] IS NOT NULL)
    )
);

CREATE TABLE [security].[loginHistory] (
    [login_id]          INT IDENTITY(1,1) PRIMARY KEY,
    [user_id]           INT NOT NULL,
    [action_type_id]    INT NOT NULL,
    [login_time]        DATETIME2 NOT NULL,
    [ip_adres]          VARCHAR(45) NOT NULL
);

CREATE TABLE [security].[login_action_types] (
    [action_type_id]    INT IDENTITY(1,1) PRIMARY KEY,
    [action_type]       VARCHAR(20) UNIQUE NOT NULL
);
-- end security tables

-- loans tables
CREATE TABLE [loans].[loan] (
    [loan_id] INT IDENTITY(1,1) PRIMARY KEY,
    [client_id] INT NOT NULL,
    [loan_status_id] INT NOT NULL,
    [employee_id] INT NOT NULL,
    [amount] NUMERIC(12,2) NOT NULL,
    [interest_rate] NUMERIC(5,2) NOT NULL,
    [start_date] DATE NOT NULL
);

CREATE TABLE [loans].[loan_statuses] (
    [loan_status_id] INT IDENTITY(1,1) PRIMARY KEY,
    [name] VARCHAR(30) UNIQUE NOT NULL
);
-- end loans tables

-- parties tables
CREATE TABLE [parties].[client] (
    [client_id] INT IDENTITY(1,1) PRIMARY KEY,
    [name] VARCHAR(20) NOT NULL,
    [surname] VARCHAR(60) NOT NULL,
    [pesel] CHAR(11) UNIQUE NOT NULL,
    [email] VARCHAR(80) UNIQUE NOT NULL
);

CREATE TABLE [parties].[employee] (
    [employee_id] INT IDENTITY(1,1) PRIMARY KEY,
    [position_id] INT NOT NULL,
    [name] VARCHAR(20) NOT NULL,
    [surname] VARCHAR(60) NOT NULL
);

CREATE TABLE [parties].[positions] (
    [position_id] INT IDENTITY(1,1) PRIMARY KEY,
    [name] VARCHAR(30) UNIQUE NOT NULL
);

