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