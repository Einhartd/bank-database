#!/bin/bash

# Ustawia 'bezpieczny' tryb działania skryptu
# -e: zakończ natychmiast, jeśli jakiekolwiek polecenie zwróci błąd
# -o pipefail: zakończ, jeśli polecenie w potoku (np. grep) zawiedzie
set -eo pipefail

# Znajdź katalog, w którym FIZYCZNIE znajduje się ten skrypt (.sh)
# Pozwala to uruchamiać go z dowolnego miejsca, np. z crona
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)

# Pełna ścieżka do aktywatora .venv
VENV_ACTIVATE="$SCRIPT_DIR/.venv/bin/activate"
# Pełna ścieżka do skryptu Pythona
PYTHON_SCRIPT="$SCRIPT_DIR/ms-sql-job.py"
# Pełna ścieżka do pliku logu
LOG_FILE="$SCRIPT_DIR/update_rates_mssql.log"

echo "--- $(date): Rozpoczynam job (przez wrapper .sh) ---" >> "$LOG_FILE"

# Sprawdź, czy .venv istnieje, zanim spróbujesz go aktywować
if [ ! -f "$VENV_ACTIVATE" ]; then
    echo "$(date): BŁĄD KRYTYCZNY: Nie znaleziono .venv/bin/activate" >> "$LOG_FILE"
    exit 1
fi

# Aktywuj środowisko wirtualne
source "$VENV_ACTIVATE"

# Uruchom skrypt Pythona
# Logi (stdout i stderr) są dopisywane do pliku logu
python3 "$PYTHON_SCRIPT" >> "$LOG_FILE" 2>&1

echo "--- $(date): Zakończono job ---" >> "$LOG_FILE"