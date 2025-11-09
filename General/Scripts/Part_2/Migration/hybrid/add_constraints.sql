
alter table accounts.account
    add constraint fk_account_client foreign key (client_id)
        references parties.client(client_id)
        on delete no action on update no action;
go

alter table accounts.account
    add constraint fk_account_currency foreign key (currency_id)
        references shared.currency(currency_id)
        on delete no action on update no action;
go

alter table accounts.account
    add constraint fk_account_type foreign key (account_type_id)
        references accounts.account_types(account_type_id)
        on delete no action on update no action;
go

alter table accounts.card
    add constraint fk_card_account foreign key (account_id)
        references accounts.account(account_id)
        on delete cascade on update cascade;
go

alter table accounts.card
    add constraint fk_card_type foreign key (card_type_id)
        references accounts.card_types(card_type_id)
        on delete no action on update no action;
go

alter table accounts.card
    add constraint fk_card_status foreign key (card_status_id)
        references accounts.card_statuses(card_status_id)
        on delete no action on update no action;
go

-- Add constraints to shared.exchangeRates
alter table shared.exchangeRates
    add constraint fk_exchange_from_currency foreign key (curr_from_id)
        references shared.currency(currency_id)
        on delete no action on update no action;
go

alter table shared.exchangeRates
    add constraint fk_exchange_to_currency foreign key (curr_to_id)
        references shared.currency(currency_id)
        on delete no action on update no action;
go

alter table parties.employee
    add constraint fk_employee_position foreign key (position_id)
        references parties.positions(position_id)
        on delete no action on update no action;
go

alter table loans.loan
    add constraint fk_loan_client foreign key (client_id)
        references parties.client(client_id)
        on delete no action on update no action;
go

alter table loans.loan
    add constraint fk_loan_status foreign key (loan_status_id)
        references loans.loan_statuses(loan_status_id)
        on delete no action on update no action;
go

alter table loans.loan
    add constraint fk_loan_employee foreign key (employee_id)
        references parties.employee(employee_id)
        on delete no action on update no action;
go

alter table transactions.[transaction]
    add constraint fk_transaction_sender foreign key (sender_account_id)
        references accounts.account(account_id)
        on delete no action on update no action;
go

alter table transactions.[transaction]
    add constraint fk_transaction_receiver foreign key (receiver_account_id)
        references accounts.account(account_id)
        on delete no action on update no action;
go

alter table transactions.[transaction]
    add constraint fk_transaction_card foreign key (card_id)
        references accounts.card(card_id)
        on delete set null on update no action;
go

alter table transactions.[transaction]
    add constraint fk_transaction_exchange foreign key (exchange_id)
        references shared.exchangeRates(ex_rate_id)
        on delete set null on update no action;
go

alter table transactions.[transaction]
    add constraint fk_transaction_type foreign key (transaction_type_id)
        references transactions.transaction_types(transaction_type_id)
        on delete no action on update no action;
go

alter table transactions.[transaction]
    add constraint fk_transaction_status foreign key (transaction_status_id)
        references transactions.transaction_statuses(transaction_status_id)
        on delete no action on update no action;
go

-- Add constraints to security.[user]
alter table security.[user]
    add constraint fk_user_employee foreign key (employee_id)
        references parties.employee(employee_id)
        on delete no action on update no action;
go

alter table security.[user]
    add constraint fk_user_client foreign key (client_id)
        references parties.client(client_id)
        on delete no action on update no action;
go

alter table security.[user]
    add constraint chk_user_role
        check (((employee_id IS NOT NULL) AND (client_id IS NULL)) OR
               ((employee_id IS NULL) AND (client_id IS NOT NULL)));
go

alter table security.loginHistory
    add constraint fk_loginhistory_user foreign key (user_id)
        references security.[user](user_id)
        on delete cascade on update cascade;
go

alter table security.loginHistory
    add constraint fk_loginhistory_action_type foreign key (action_type_id)
        references security.login_action_types(action_type_id)
        on delete no action on update no action;
go


