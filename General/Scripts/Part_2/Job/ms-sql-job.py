import requests
import pyodbc
import sys

DRIVER = '{ODBC Driver 18 for SQL Server}'
SERVER = 'localhost'
PORT = '1433'
DATABASE = 'bank_db_etl'
USERNAME = 'oliwier'
PASSWORD = 'R7LPiKIz6D'

CONNECTION_STRING = f"DRIVER={DRIVER};SERVER={SERVER},{PORT};DATABASE={DATABASE};UID={USERNAME};PWD={PASSWORD};TrustServerCertificate=yes"

NBP_API_URL = 'http://api.nbp.pl/api/exchangerates/tables/A/?format=json'
BASE_CURRENCY = 'PLN'


def fetch_bank_currencies(cursor):
    """Pobiera obsługiwane waluty z bazy (oprócz PLN)"""
    try:
        cursor.execute("SELECT symbol FROM shared.currency WHERE symbol != ?", (BASE_CURRENCY,))
        supported_currencies = {row[0] for row in cursor.fetchall()}
        print(f"Baza danych obsługuje: {supported_currencies}")
        return supported_currencies
    except pyodbc.Error as e:  # Zmiana typu błędu
        print(f"BŁĄD BAZY: Nie można pobrać listy walut: {e}")
        return None


def fetch_rates_api():
    """Pobiera kursy walut z API NBP (bez zmian)"""
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
    """Filtruje kursy NBP tylko do tych obsługiwanych przez bank (bez zmian)"""
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
        conn = pyodbc.connect(CONNECTION_STRING)
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
                    "EXEC shared.sp_add_symmetrical_exchange_rate ?, ?, ?, ?",
                    (symbol_from, BASE_CURRENCY, exchange_rate, effective_date)
                )

                conn.commit()

            except pyodbc.Error as e:
                # pyodbc.Error złapie błędy SQL oraz komunikaty z RAISERROR/THROW
                # w T-SQL (odpowiednik RaiseException z plpgsql)
                print(f"INFO/BŁĄD BAZY (dla {symbol_from}): {e}")
                conn.rollback()

            except Exception as e:
                # Łapie inne błędy (np. błędy logiki Pythona)
                print(f"BŁĄD APLIKACJI (dla {symbol_from}): {e}")
                conn.rollback()

        print("--- Zakończono ---")

    except pyodbc.Error as e:
        # Błąd połączenia lub inny błąd krytyczny bazy
        print(f"WYSTĄPIŁ BŁĄD KRYTYCZNY BAZY DANYCH: {e}")
        if conn:
            conn.rollback()
    except Exception as e:
        print(f"WYSTĄPIŁ BLED KRYTYCZNY APLIKACJI: {e}")
        if conn:
            conn.rollback()
    finally:
        if conn:
            conn.close()
            print("Połączenie z bazą danych zamknięte.")