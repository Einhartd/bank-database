/*
 * =================================================================================
 * Funkcja Klienta: accounts.fn_get_my_total_balance
 * Opis: Oblicza łączne saldo zalogowanego klienta w wybranej walucie,
 * korzystając z bezpiecznego widoku 'view_client_accounts'.
 * =================================================================================
 */
CREATE OR REPLACE FUNCTION accounts.fn_get_my_total_balance(
    p_target_currency_id INT,
    p_calculation_date DATE
)
RETURNS DECIMAL(12,2)
LANGUAGE sql
STABLE
SECURITY INVOKER
AS $$
    SELECT COALESCE(
                SUM(
                    shared.fn_convert_currency(
                        v.balance,
                        v.currency_id,
                        p_target_currency_id,
                        p_calculation_date
                    )
                ),
                0.00)
    FROM
        accounts.view_client_accounts v;
$$;

REVOKE EXECUTE
ON FUNCTION accounts.fn_get_my_total_balance(INT, DATE)
FROM PUBLIC;

GRANT EXECUTE
ON FUNCTION accounts.fn_get_my_total_balance(INT, DATE)
TO client_role;