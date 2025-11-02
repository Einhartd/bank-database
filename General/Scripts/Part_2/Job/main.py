import requests
import psycopg2

DB_CONFIG = {
    "dbname": "banking_system",
    "user": "oliwier",
    "password": "einhart",
    "host": "localhost",
    "port": "5432"
}

NBP_API_URL = 'http://api.nbp.pl/api/exchangerates/tables/A/?format=json'
BASE_CURRENCY = 'PLN'


def fetch_bank_currencies(cursor):
    """Pobiera obsługiwane waluty z bazy (oprócz PLN)"""
    try:
        cursor.execute("SELECT symbol FROM shared.currency WHERE symbol != %s", (BASE_CURRENCY,))
        supported_currencies = {row[0] for row in cursor.fetchall()}
        print(f"Baza danych obsługuje: {supported_currencies}")
        return supported_currencies
    except psycopg2.Error as e:
        print(f"BŁĄD BAZY: Nie można pobrać listy walut: {e}")
        return None


def fetch_rates_api():
    """Pobiera kursy walut z API NBP"""
    try:
        response = requests.get(NBP_API_URL)
        response.raise_for_status()
        data = response.json()

        if not data:
            raise ValueError("API NBP zwróciło pustą odpowiedź.")

        rates_list = data[0].get('rates', [])
        effective_date = data[0].get('effectiveDate')
        print(f"Pobrano {len(rates_list)} kursów z NBP na dzień {effective_date}.")
        return rates_list, effective_date

    except requests.exceptions.RequestException as e:
        print(f"BŁĄD API: Nie można połączyć się z NBP: {e}")
        return None, None


def process_rates(rates_list, effective_date, supported_currencies):
    """Filtruje kursy NBP tylko do tych obsługiwanych przez bank"""
    prepared_rates = []
    if supported_currencies is None:
        return []

    for rate in rates_list:
        if rate['code'] in supported_currencies:
            prepared_rates.append((rate['code'], rate['mid'], effective_date))

    print(f"Przygotowano {len(prepared_rates)} obsługiwanych kursów.")
    return prepared_rates


if __name__ == '__main__':
    conn = None
    try:
        conn = psycopg2.connect(**DB_CONFIG)
        conn.autocommit = False
        cursor = conn.cursor()

        supported_currencies = fetch_bank_currencies(cursor)
        rates_list, effective_date = fetch_rates_api()
        filtered_rates = process_rates(rates_list, effective_date, supported_currencies)

        if not filtered_rates:
            print("Brak kursów do przetworzenia.")
        else:
            print("--- Rozpoczynam wstawianie/aktualizację kursów ---")


        for rate in filtered_rates:
            try:
                symbol_from = rate[0]
                exchange_rate = rate[1]
                effective_date = rate[2]

                cursor.execute(
                    "CALL shared.sp_add_symmetrical_exchange_rate(%s, %s, %s, %s)",
                    (symbol_from, BASE_CURRENCY, exchange_rate, effective_date)
                )

                conn.commit()

            except psycopg2.errors.RaiseException as e:
                print(f"INFO (dla {symbol_from}): {e}")
                conn.rollback()

            except Exception as e:
                print(f"BŁĄD (dla {symbol_from}): {e}")
                conn.rollback()

        print("--- Zakończono ---")

    except Exception as e:
        print(f"WYSTĄPIŁ BŁĄD KRYTYCZNY: {e}")
        if conn:
            conn.rollback()
    finally:
        if conn:
            conn.close()
            print("Połączenie z bazą danych zamknięte.")