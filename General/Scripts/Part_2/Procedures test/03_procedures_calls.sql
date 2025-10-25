CALL accounts.sp_addaccounttype('Osobiste Premium');

CALL parties.sp_addemployeeposition('Analityk Biznesowy');

CALL security.sp_addloginactiontype('Logowanie 2FA');

CALL accounts.sp_addcardtype('Debetowa Walutowa');

CALL accounts.sp_addcardstatus('Zamrożona');

CALL loans.sp_addloanstatus('Odroczony');

CALL parties.sp_addnewemployee('Michał', 'Grabala', 'Analityk Biznesowy');

CALL accounts.sp_openaccount(2, 'USD', 'Walutowe', 'PL25102410130060020702020202', 150.00);

CALL accounts.sp_issuenewcard(3, 'Wirtualna', '1123435687694537', '2028-03-25');

CALL transactions.sp_createdomestictransfer(1, 2, 0.50,
                               'Przelew testowy', '', 1);

-- przelew bedzie dotyczyl kwoty 100.00 z konta 5 na konto 1 (EUR-PLN)

CALL transactions.sp_createdomestictransfer(5, 'PL21102010130000010101010101', 100.00,
                               'Przelew testowy 2', '', 1);

-- przelew bedzie dotyczyl kwoty 0.75 z konta 3 na na konto zewnetrzne

CALL transactions.sp_createdomestictransfer(3, 'PL21152010130060010701018101', 0.75,
                               'Przelew testowy 3', 'Test 3', 1);