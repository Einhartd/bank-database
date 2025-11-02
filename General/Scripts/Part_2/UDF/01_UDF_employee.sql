-- udf do sumowania salda klienta z wszystkich kont
-- nie powinno byc problemow z migracja jezeli convert_currency zostanie
-- odpowiednio poprawione
CREATE FUNCTION accounts.fn_get_client_total_balance(
    p_client_id INT,
    p_target_currency_id INT,
    p_calculation_date DATE
)
RETURNS DECIMAL(12,2)
LANGUAGE sql
STABLE
AS $$
    SELECT COALESCE(
                SUM(
                    shared.fn_convert_currency(
                    a.balance,
                    a.currency_id,
                    p_target_currency_id,
                    p_calculation_date
                    )
                ),
                0.00)
    FROM
        accounts.account a
    WHERE
        a.client_id = p_client_id;
$$;

REVOKE EXECUTE
ON FUNCTION accounts.fn_get_client_total_balance
FROM public;

GRANT EXECUTE
ON FUNCTION accounts.fn_get_client_total_balance
TO employee_role;

GRANT EXECUTE
ON FUNCTION accounts.fn_get_client_total_balance
TO admin_role;

GRANT EXECUTE
ON FUNCTION accounts.fn_get_client_total_balance
TO oliwier;

