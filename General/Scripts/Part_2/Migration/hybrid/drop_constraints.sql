
alter table accounts.account drop constraint fk_account_client;
go

alter table accounts.account drop constraint fk_account_currency;
go

alter table accounts.account drop constraint fk_account_type;
go

-- Drop constraints from accounts.card
alter table accounts.card drop constraint fk_card_account;
go

alter table accounts.card drop constraint fk_card_type;
go

alter table accounts.card drop constraint fk_card_status;
go

-- Drop constraints from shared.exchangeRates
alter table shared.exchangeRates drop constraint fk_exchange_from_currency;
go

alter table shared.exchangeRates drop constraint fk_exchange_to_currency;
go

-- Drop constraints from parties.employee
alter table parties.employee drop constraint fk_employee_position;
go

-- Drop constraints from loans.loan
alter table loans.loan drop constraint fk_loan_client;
go

alter table loans.loan drop constraint fk_loan_status;
go

alter table loans.loan drop constraint fk_loan_employee;
go

-- Drop constraints from transactions.[transaction]
alter table transactions.[transaction] drop constraint fk_transaction_sender;
go

alter table transactions.[transaction] drop constraint fk_transaction_receiver;
go

alter table transactions.[transaction] drop constraint fk_transaction_card;
go

alter table transactions.[transaction] drop constraint fk_transaction_exchange;
go

alter table transactions.[transaction] drop constraint fk_transaction_type;
go

alter table transactions.[transaction] drop constraint fk_transaction_status;
go

-- Drop constraints from security.[user]
alter table security.[user] drop constraint fk_user_employee;
go

alter table security.[user] drop constraint fk_user_client;
go

alter table security.[user] drop constraint chk_user_role;
go

-- Drop constraints from security.loginHistory
alter table security.loginHistory drop constraint fk_loginhistory_user;
go

alter table security.loginHistory drop constraint fk_loginhistory_action_type;
go


