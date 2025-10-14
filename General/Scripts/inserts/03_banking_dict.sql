-- banking.positions (Stanowiska)
INSERT INTO banking.positions (position_id, name) VALUES
(1, 'Doradca Klienta'),
(2, 'Analityk Kredytowy'),
(3, 'Kasjer'),
(4, 'Specjalista ds. Bezpieczeństwa');

-- banking.account_types (Typy kont)
INSERT INTO banking.account_types (account_type_id, name) VALUES
(1, 'Osobiste'),
(2, 'Oszczędnościowe'),
(3, 'Firmowe'),
(4, 'Walutowe');

-- banking.card_types (Typy kart)
INSERT INTO banking.card_types (card_type_id, name) VALUES
(1, 'Debetowa'),
(2, 'Kredytowa'),
(3, 'Wirtualna');

-- banking.card_statuses (Statusy kart)
INSERT INTO banking.card_statuses (card_status_id, name) VALUES
(1, 'Aktywna'),
(2, 'Zablokowana'),
(3, 'Zastrzeżona'),
(4, 'Wygasła');

-- banking.loan_statuses (Statusy kredytów)
INSERT INTO banking.loan_statuses (loan_status_id, name) VALUES
(1, 'Aktywny'),
(2, 'Spłacony'),
(3, 'W trakcie rozpatrywania'),
(4, 'Odrzucony');

-- banking.transaction_types (Typy transakcji)
INSERT INTO banking.transaction_types (transaction_type_id, name) VALUES
(1, 'Przelew krajowy'),
(2, 'Płatność kartą'),
(3, 'Wpłata'),
(4, 'Wypłata'),
(5, 'Wymiana walut');

-- banking.transaction_statuses (Statusy transakcji)
INSERT INTO banking.transaction_statuses (transaction_status_id, name) VALUES
(1, 'Zakończona'),
(2, 'W toku'),
(3, 'Odrzucona');

-- banking.currency (Waluty)
INSERT INTO banking.currency (currency_id, symbol, name) VALUES
(1, 'PLN', 'Polski Złoty'),
(2, 'EUR', 'Euro'),
(3, 'USD', 'Dolar Amerykański');