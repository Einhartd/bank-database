SELECT cron.schedule(
    'job_expire_cards_pg',
    '56 12 * * *',
    $$
    UPDATE accounts.card
    SET card_status_id = (SELECT card_status_id FROM accounts.card_statuses WHERE name = 'Wygasła')
    WHERE expiry_date < CURRENT_DATE
      AND card_status_id != (SELECT card_status_id FROM accounts.card_statuses WHERE name = 'Wygasła');
    $$
);