/*
 * =================================================================================
 * Funkcja Wyzwalacza: accounts.fn_check_balance_not_negative
 * Opis: Sprawdza, czy saldo (balance) w tabeli 'accounts.account'
 * nie spadło poniżej zera podczas operacji UPDATE.
 * Uwaga! problem przy migracji
 * =================================================================================
 */
CREATE FUNCTION accounts.fn_check_balance_not_negative()
RETURNS TRIGGER AS $$
BEGIN

    IF NEW.balance < 0.00 THEN

        RAISE EXCEPTION 'Błąd: Saldo konta (ID: %) nie może być ujemne. Próba ustawienia na %.',
                         NEW.account_id, NEW.balance;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

/*
 * =================================================================================
 * Wyzwalacz: trg_protect_balance_on_update
 * Tabela: accounts.account
 * Zdarzenie: BEFORE UPDATE (Przed każdą aktualizacją)
 * =================================================================================
 */

DROP TRIGGER IF EXISTS trg_protect_balance_on_update ON accounts.account;

CREATE TRIGGER trg_protect_balance_on_update
BEFORE UPDATE ON accounts.account
FOR EACH ROW
WHEN (OLD.balance IS DISTINCT FROM NEW.balance)
EXECUTE FUNCTION accounts.fn_check_balance_not_negative();



/*
 * =================================================================================
 * Funkcja Wyzwalacza: accounts.fn_check_account_empty
 * Opis: Sprawdza, czy saldo (balance) w tabeli 'accounts.account'
 * jest puste przed usunieciem z bazy.
 * Uwaga! problem przy migracji
 * =================================================================================
 */
CREATE FUNCTION accounts.fn_check_account_empty()
RETURNS TRIGGER AS $$
BEGIN

    IF OLD.balance != 0.00 THEN

        RAISE EXCEPTION 'Błąd: Saldo konta (ID: %) nie wynosi 0 (%). Nie mozna usunac konta.',
                         OLD.account_id, OLD.balance;
    END IF;

    RETURN OLD;
END;
$$ LANGUAGE plpgsql;


CREATE TRIGGER trg_prevent_delete_active_acc
BEFORE DELETE ON accounts.account
FOR EACH ROW
EXECUTE FUNCTION accounts.fn_check_account_empty();