CREATE VIEW security.view_recent_login AS
SELECT
    u.login,
    lh.login_time,
    lh.ip_adres,
    lat.name AS action_type
FROM
    security."loginHistory" lh
JOIN
    security.user u ON lh.user_id = u.user_id
JOIN
    security.login_action_types lat ON lh.action_type_id = lat.action_type_id;


CREATE VIEW loans.view_assigned_loans AS
SELECT
    e.employee_id,
    e.name AS employee_name,
    e.surname AS employee_surname,
    c.name AS client_name,
    c.surname AS client_surname,
    l.amount AS loan_amount,
    l.interest_rate,
    ls.name AS loan_status
FROM
    loans.loan l
JOIN
    parties.employee e ON l.employee_id = e.employee_id
JOIN
    parties.client c ON l.client_id = c.client_id
JOIN
    loans.loan_statuses ls ON l.loan_status_id = ls.loan_status_id;


GRANT SELECT ON security.view_recent_login TO employee_role;
GRANT SELECT ON loans.view_assigned_loans TO employee_role;
