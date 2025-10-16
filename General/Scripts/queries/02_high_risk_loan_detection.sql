-- zapytanie identyfikujace klientow z wysokim ryzykiem kredytowym
-- w ramach zapytania obliczamy iloraz wszysktich kredytow do srodkow
-- na koncie (risk ratio). Wybieramy tylko aktywne kredyty i segregujemy
-- od najwiekszego do najmniejszego ryzyka

SELECT
    c.name,
    c.surname,
    c.email,
    SUM(a.balance) AS total_balance,
    SUM(l.amount) AS total_loan_amount,

    ROUND((SUM(l.amount) / SUM(a.balance)), 2) AS risk_ratio
FROM
    parties.client c
JOIN
    accounts.account a ON c.client_id = a.client_id
JOIN
    loans.loan l ON c.client_id = l.client_id
WHERE
    l.loan_status_id = (
        SELECT loan_status_id FROM loans.loan_statuses WHERE name = 'Aktywny'
    )
GROUP BY
    c.client_id, c.name, c.surname, c.email
HAVING
    SUM(a.balance) > 0
ORDER BY
    risk_ratio DESC;