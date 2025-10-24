CALL accounts.sp_addaccounttype('Osobiste Premium');

CALL parties.sp_addemployeeposition('Analityk Biznesowy');

CALL security.sp_addloginactiontype('Logowanie 2FA');

CALL accounts.sp_addcardtype('Debetowa Walutowa');

CALL accounts.sp_addcardstatus('Zamrożona');

CALL loans.sp_addloanstatus('Odroczony');

CALL parties.sp_addnewemployee('Michał', 'Grabala', 'Analityk Biznesowy');

CALL accounts.sp_openaccount(2, 'USD', 'Walutowe', 'PL25102410130060020702020202', 150.00);

CALL accounts.sp_issuenewcard(3, 'Wirtualna', '1123435687694537', '2028-03-25');