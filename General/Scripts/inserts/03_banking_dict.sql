-- banking.positions (Stanowiska)
INSERT INTO parties.positions (name) VALUES
( 'Doradca Klienta'),
( 'Analityk Kredytowy'),
( 'Kasjer'),
( 'Specjalista ds. Bezpieczeństwa');

-- banking.account_types (Typy kont)
INSERT INTO accounts.account_types (name) VALUES
( 'Osobiste'),
( 'Oszczędnościowe'),
( 'Firmowe'),
( 'Walutowe');

-- banking.card_types (Typy kart)
INSERT INTO accounts.card_types (name) VALUES
( 'Debetowa'),
( 'Kredytowa'),
( 'Wirtualna');

-- banking.card_statuses (Statusy kart)
INSERT INTO accounts.card_statuses (name) VALUES
( 'Aktywna'),
( 'Zablokowana'),
( 'Zastrzeżona'),
( 'Wygasła');

-- banking.loan_statuses (Statusy kredytów)
INSERT INTO loans.loan_statuses (name) VALUES
( 'Aktywny'),
( 'Spłacony'),
('W trakcie rozpatrywania'),
( 'Odrzucony');

-- banking.transaction_types (Typy transakcji)
INSERT INTO transactions.transaction_types (name) VALUES
( 'Przelew krajowy'),
( 'Płatność kartą'),
( 'Wpłata'),
( 'Wypłata'),
( 'Wymiana walut');

-- banking.transaction_statuses (Statusy transakcji)
INSERT INTO transactions.transaction_statuses (name) VALUES
( 'Zakończona'),
( 'W toku'),
( 'Odrzucona');

-- banking.currency (Waluty)
INSERT INTO shared.currency (symbol, name) VALUES
( 'PLN', 'Polski Złoty'),
( 'EUR', 'Euro'),
( 'USD', 'Dolar Amerykański');