import psycopg2
import psycopg2.extras
import random
from faker import Faker
from decimal import Decimal

DB_CONFIG = {
    "dbname": "banking_system",
    "user": "oliwier",
    "password": "einhart",
    "host": "localhost",
    "port": "5432"
}


# Konfiguracja generatora
NUM_TRANSACTIONS = 100000
BATCH_SIZE = 1000

# Inicjalizacja Fakera
fake = Faker('pl_PL')


def fetch_foreign_keys(cursor):
    """Pobiera z bazy danych listy istniejących kluczy obcych."""

    # Pobierz ID kont
    cursor.execute("SELECT account_id FROM accounts.account")
    account_ids = [row[0] for row in cursor.fetchall()]

    # Pobierz ID kart
    cursor.execute("SELECT card_id FROM accounts.card")
    card_ids = [row[0] for row in cursor.fetchall()]

    # Pobierz ID statusów i typów transakcji (słowniki)
    cursor.execute("SELECT transaction_type_id FROM transactions.transaction_types")
    transaction_type_ids = [row[0] for row in cursor.fetchall()]

    # Get transaction statuses
    cursor.execute("SELECT transaction_status_id FROM transactions.transaction_statuses")
    transaction_status_ids = [row[0] for row in cursor.fetchall()]


    if not all([account_ids, transaction_type_ids, transaction_status_ids]):
        raise ValueError(
            "Empty table")

    return {
        "accounts": account_ids,
        "cards": card_ids,
        "types": transaction_type_ids,
        "statuses": transaction_status_ids
    }


def generate_transaction(fk_data):
    """Generuje pojedynczy, logicznie spójny rekord transakcji."""

    # Podstawowe, zawsze obecne dane
    amount = Decimal(random.uniform(5.0, 5000.0)).quantize(Decimal('0.01'))
    time = fake.date_time_between(start_date='-3y', end_date='now')
    #transaction_type_id = random.choice(fk_data['types'])
    transaction_status_id = random.choices(fk_data['statuses'], weights=[85, 10, 5], k=1)[0]

    # Zmienne, które będą się zmieniać w zależności od typu transakcji
    sender_account_id = None
    receiver_account_id = None
    card_id = None
    description = ""
    counterparty_name = None
    counterparty_acc_num = None

    # Logika generowania w zależności od typu transakcji (dla realizmu)
    transaction_logic = random.choice(
        ['internal_transfer', 'card_payment', 'external_transfer_in', 'external_transfer_out', 'atm_withdrawal'])

    if transaction_logic == 'internal_transfer':
        sender_account_id, receiver_account_id = random.sample(fk_data['accounts'], 2)
        transaction_type_id = 1
        description = f"Przelew wewnętrzny"

    elif transaction_logic == 'card_payment' and fk_data['cards']:
        transaction_type_id = 2
        card_id = random.choice(fk_data['cards'])
        description = f"Płatność kartą w {fake.company()}"
        counterparty_name = description.replace("Płatność kartą w ", "")


    elif transaction_logic == 'external_transfer_in':
        receiver_account_id = random.choice(fk_data['accounts'])
        description = f"Przelew od {fake.name()}"
        transaction_type_id = 3
        counterparty_name = description.replace("Przelew od ", "")
        counterparty_acc_num = fake.iban()

    elif transaction_logic == 'external_transfer_out':
        sender_account_id = random.choice(fk_data['accounts'])
        transaction_type_id = 1
        description = f"Przelew do {fake.name()}"
        counterparty_name = description.replace("Przelew do ", "")
        counterparty_acc_num = fake.iban()

    else:  # Domyślnie lub dla 'atm_withdrawal'
        sender_account_id = random.choice(fk_data['accounts'])
        transaction_type_id = 4
        if fk_data['cards'] and random.random() > 0.5:  # Czasem wypłata jest powiązana z kartą
            card_id = random.choice(fk_data['cards'])
        description = f"Wypłata z bankomatu {fake.city()}"

    return (
        sender_account_id,
        receiver_account_id,
        card_id,
        None,
        transaction_type_id,
        transaction_status_id,
        amount,
        time,
        description,
        counterparty_name,
        counterparty_acc_num
    )


def main():

    transactions_data = []

    # Nawiązanie połączenia z bazą danych
    conn = psycopg2.connect(**DB_CONFIG)
    cursor = conn.cursor()

    # Pobranie kluczy obcych
    fk_data = fetch_foreign_keys(cursor)

    try:
        # Nawiązanie połączenia z bazą danych
        conn = psycopg2.connect(**DB_CONFIG)
        cursor = conn.cursor()

        # Pobranie kluczy obcych
        fk_data = fetch_foreign_keys(cursor)

        # Główna pętla generująca dane
        for i in range(NUM_TRANSACTIONS):
            transaction = generate_transaction(fk_data)
            transactions_data.append(transaction)

            # Wstawianie danych do bazy partiami
            if len(transactions_data) == BATCH_SIZE:
                insert_query = """
                               INSERT INTO transactions.transaction (sender_account_id, receiver_account_id, card_id, \
                                                                     exchange_id, \
                                                                     transaction_type_id, transaction_status_id, amount, \
                                                                     time, \
                                                                     description, counterparty_name, \
                                                                     counterparty_acc_num) \
                               VALUES %s \
                               """
                psycopg2.extras.execute_values(cursor, insert_query, transactions_data)
                conn.commit()
                transactions_data = []  # Wyczyszczenie listy na kolejną partię
                print(f"Wstawiono {i + 1}/{NUM_TRANSACTIONS} rekordów...")

        # Wstawienie ostatniej, niepełnej partii danych, jeśli jakaś została
        if transactions_data:
            insert_query = """
                           INSERT INTO transactions.transaction (sender_account_id, receiver_account_id, card_id, \
                                                                 exchange_id, \
                                                                 transaction_type_id, transaction_status_id, amount, \
                                                                 time, \
                                                                 description, counterparty_name, counterparty_acc_num) \
                           VALUES %s \
                           """
            psycopg2.extras.execute_values(cursor, insert_query, transactions_data)
            conn.commit()

    except (Exception, psycopg2.Error) as error:
        print(f"Error: {error}")

    finally:
        if 'conn' in locals() and conn is not None:
            cursor.close()
            conn.close()


if __name__ == "__main__":
    main()