CALL parties.sp_add_new_employee('Michał', 'Grabala', 'Analityk Biznesowy');

CALL accounts.sp_open_account(2, 'USD', 'Walutowe', 'PL25102410130060020702020202', 150.00);

CALL accounts.sp_issue_new_card(3, 'Wirtualna', '1123435687694537', '2028-03-25');

CALL transactions.sp_create_domestic_transfer(1, 2, 0.50,
                               'Przelew testowy', '', 1);

-- przelew bedzie dotyczyl kwoty 100.00 z konta 5 na konto 1 (EUR-PLN)

CALL transactions.sp_create_domestic_transfer(5, 'PL21102010130000010101010101', 100.00,
                               'Przelew testowy 2', '', 1);

-- przelew bedzie dotyczyl kwoty 0.75 z konta 3 na na konto zewnetrzne

CALL transactions.sp_create_domestic_transfer(3, 'PL21152010130060010701018101', 0.75,
                               'Przelew testowy 3', 'Test 3', 1);