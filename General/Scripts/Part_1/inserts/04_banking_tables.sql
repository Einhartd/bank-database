-- banking.employee (Pracownicy)
INSERT INTO parties.employee (position_id, name, surname) VALUES
( 1, 'Jan', 'Kowalski'),
( 2, 'Anna', 'Nowak'),
( 3, 'Piotr', 'Wiśniewski'),
( 4, 'Katarzyna', 'Wójcik'),
( 1, 'Marek', 'Kowalczyk');

-- banking.client (Klienci)
INSERT INTO parties.client (name, surname, pesel, email) VALUES
( 'Adam', 'Zieliński', '85010112345', 'adam.zielinski@example.com'),
( 'Ewa', 'Szymańska', '92020223456', 'ewa.szymanska@example.com'),
( 'Tomasz', 'Jankowski', '78030334567', 'tomasz.jankowski@example.com'),
( 'Magdalena', 'Woźniak', '89040445678', 'magdalena.wozniak@example.com'),
( 'Krzysztof', 'Lewandowski', '95050556789', 'krzysztof.lewandowski@example.com');

-- banking.account (Konta bankowe)
INSERT INTO accounts.account (client_id, currency_id, account_type_id, number, balance) VALUES
( 1, 1, 1, 'PL21102010130000010101010101', 5420.50),
( 2, 1, 1, 'PL22102010130000020202020202', 12345.00),
( 3, 2, 4, 'PL23102010130000030303030303', 3200.75),
( 4, 1, 2, 'PL24102010130000040404040404', 25000.00),
( 1, 2, 4, 'PL25102010130000050505050505', 800.00);

-- banking.card (Karty płatnicze)
INSERT INTO accounts.card (account_id, card_type_id, card_status_id, number, expiry_date) VALUES
( 1, 1, 1, '1111222233334444', '2027-12-31'),
( 2, 1, 1, '2222333344445555', '2026-10-31'),
( 3, 1, 2, '3333444455556666', '2028-01-31'),
( 4, 2, 1, '4444555566667777', '2025-11-30'),
( 2, 3, 1, '5555666677778888', '2026-06-30');

-- banking.loan (Kredyty)
INSERT INTO loans.loan (client_id, loan_status_id, employee_id, amount, interest_rate, start_date) VALUES
( 1, 1, 2, 20000.00, 7.50, '2023-01-15'),
( 3, 1, 1, 5000.00, 9.20, '2024-05-20'),
( 4, 2, 2, 150000.00, 5.80, '2022-02-10'),
( 5, 3, 1, 10000.00, 8.00, '2025-09-01');

-- banking.exchangeRates (Kursy wymiany)
INSERT INTO shared."exchangeRates" (curr_from_id, curr_to_id, ex_rate, date) VALUES
( 2, 1, 4.25, '2025-10-10'),
( 3, 1, 3.98, '2025-10-10'),
( 1, 2, 0.23, '2025-10-10'),
( 1, 3, 0.25, '2025-10-10');

-- banking.transaction (Transakcje)
INSERT INTO transactions.transaction (sender_account_id, receiver_account_id, card_id, exchange_id, transaction_type_id, transaction_status_id, amount, time, description, counterparty_name, counterparty_acc_num) VALUES
( 1, 2, NULL, NULL, 1, 1, 150.00, '2025-10-09 10:00:00', 'Przelew za obiad', NULL, NULL),
( 2, NULL, 2, NULL, 2, 1, 75.50, '2025-10-09 12:30:00', 'Zakupy spożywcze', NULL, NULL),
( NULL, 4, NULL, NULL, 3, 1, 1000.00, '2025-10-10 09:15:00', 'Wpłata własna', NULL, NULL),
( 5, 1, NULL, 1, 5, 1, 200.00, '2025-10-10 11:00:00', 'Wymiana 200 EUR na PLN', NULL, NULL),
( 1, NULL, NULL, NULL, 1, 1, 250.00, '2025-10-11 14:00:00', 'Czynsz', 'Wynajem Sp. z o.o.', 'PL99102010139999989898989898');

INSERT INTO transactions.transaction (sender_account_id, receiver_account_id, card_id, exchange_id, transaction_type_id, transaction_status_id, amount, time, description, counterparty_name, counterparty_acc_num) VALUES
( 1, 2, null, null, 1, 1, 250.75, '2025-09-22 10:15:00.000000', 'Zwrot za bilety', null, null),
( 1, 4, null, null, 1, 1, 1200.00, '2025-10-01 11:00:00.000000', 'Czynsz', 'Wynajem Sp. z o.o.', 'PL99102010139999989898989898'),
( 1, 3, null, null, 1, 1, 88.50, '2025-08-30 18:45:00.000000', 'Rozliczenie za kolację', null, null),
( 5, 1, null, null, 1, 1, 1000.00, '2025-09-15 14:00:00.000000', 'Przelew własny', null, null),
( null, null, 1, null, 2, 1, 149.99, '2025-10-14 19:30:00.000000', 'Zakupy odzieżowe', 'Zalando', null),
( null, null, 1, null, 2, 1, 55.00, '2025-10-11 13:00:00.000000', 'Lunch', 'Restauracja Smak', null),
( null, null, 1, null, 2, 1, 210.40, '2025-09-05 17:20:00.000000', 'Zakupy spożywcze', 'Auchan', null),
( 5, null, null, null, 4, 1, 200.00, '2025-08-25 09:00:00.000000', 'Wypłata gotówki', 'Bankomat Euronet', null),
( null, null, 2, null, 2, 1, 45.80, '2025-10-02 08:30:00.000000', 'Kawa i kanapka', 'Starbucks', null),
( null, null, 2, null, 2, 1, 78.00, '2025-09-28 20:00:00.000000', 'Bilety do kina', 'Cinema City', null),
( null, null, 5, null, 2, 1, 95.20, '2025-09-18 11:45:00.000000', 'Tankowanie paliwa', 'Stacja BP', null),
(2, 4, null, null, 1, 1, 300.00, '2025-07-20 16:00:00.000000', 'Prezent urodzinowy', null, null),
( null, null, 3, null, 2, 1, 129.50, '2025-06-10 14:25:00.000000', 'Książki', 'Empik', null),
( null, 3, null, null, 3, 1, 500.00, '2025-10-05 12:00:00.000000', 'Wpłata od znajomego', null, null),
( null, null, 4, null, 2, 1, 65.00, '2025-10-08 18:00:00.000000', 'Apteka', 'Apteka Zdrowie', null),
( 4, 5, null, null, 1, 1, 450.00, '2025-09-02 21:00:00.000000', 'Rachunek za telefon', 'Orange Polska', 'PL22114000001111222233334444'),
( 4, 1, null, null, 1, 2, 199.99, '2025-10-16 14:30:00.000000', 'Przelew weryfikacyjny', null, null),
( 2, 1, null, null, 1, 1, 75.00, '2024-05-10 10:10:00.000000', 'Stary przelew', null, null);
