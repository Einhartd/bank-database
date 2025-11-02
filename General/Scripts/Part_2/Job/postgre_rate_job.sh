# --- Zmienne (dla czytelności) ---
# Upewnij się, że ta ścieżka jest poprawna:
JOB_PATH="/home/oliwier/Dev/uni/bank-db/General/Scripts/Part_2/Job/run_update.sh"

# Ten tag identyfikuje nasz job w cronie:
JOB_ID="#JOB_ID_BANK_RATES_V1"

# Działanie: Usuwa starą wersję joba (jeśli istnieje) i dodaje nową.
(crontab -l 2>/dev/null | grep -v "$JOB_ID"; echo "55 15 * * * $JOB_PATH $JOB_ID") | crontab -
# 'crontab -' --> crontab czyta z wejścia standardowego. Dlatego przed nim jest pipe.
# 'crontab -l 2>/dev/null' --> lista aktualnych zadań cron. '2>/dev/null' ukrywa błąd, jeśli crontab jest pusty.
# 'grep -v "$JOB_ID"' --> usuwa linię z jobem, jeśli istnieje.

# Działanie: Usuwa linię z naszym jobem z crontab.
(crontab -l 2>/dev/null | grep -v "$JOB_ID") | crontab -

# Działanie: Pokaże joba, jeśli jest zainstalowany, lub komunikat.
crontab -l 2>/dev/null | grep "$JOB_ID" || echo "Job nie jest zainstalowany."

chmod +x /home/oliwier/Dev/uni/bank-db/General/Scripts/Part_2/Job/run_update.sh