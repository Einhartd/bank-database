-- security.user (Użytkownicy)

INSERT INTO security.user (employee_id, client_id, login, password) VALUES
-- Pracownicy (employee_id jest ustawiony, client_id to NULL)
(1, NULL, 'jkowalski', '$2a$12$XvCPIn3kVbguVtfRDWEhsOAyMG.E/xJHKy2BD/dnrizqP5oqWlD.m'),
( 2, NULL, 'anowak', '$2a$12$bVY7EOmWLMrxFnqG6Fb2HemX7YtAzNco0zMK8TppPR72EDSsC6TLC'),
( 3, NULL, 'pwisniewski', '$2a$12$Yc8FMEzvQbHgbbHGUKngyubvBqaf4dO4/7nWIsqHKVYoGOmbvdkfi'),
( 4, NULL, 'kwojcik', '$2a$12$Kfr4PKlPeD8QaMKp9OcHnOAB1r4lNQmMmbJbTpn64E1StQOsF.HAi'),
( 5, NULL, 'mkowalczyk', '$2a$12$J1M5/WgdZWAOF.LLmeFateCM/0rGZZd/ni5y1r3ZYfs8N2SFCATOG'),
-- Klienci (client_id jest ustawiony, employee_id to NULL)
( NULL, 1, 'azielinski', '$2a$12$8maNoeh28SsdMiaBNZixHesDjRerxnQbSxNBMWE/L28F4.Z8OEVne'),
( NULL, 2, 'eszymanska', '$2a$12$LltzhvCxvwVg94bz0NzGbO4sODn6GCkDzZbTXRciKLVNp0DzncJ/a'),
( NULL, 3, 'tjankowski', '$2a$12$Q7Q6nf3XWjt8NTMfgfQ2L.RULMc3MR87xIt26oPsfC.ldxJSF6Fx.'),
( NULL, 4, 'mwozniak', '$2a$12$PPc8rj1RwG8tOPID6AhRlO3zRHGMY10hnAE6C6NQoxzF60N/cVLCe'),
( NULL, 5, 'klewandowski', '$2a$12$tN15nY4ciM5HaFIXt4ehEe6189M15O5TFGOvQ.5ZAUP3mlKcWrCXy');

-- security.loginHistory (Historia logowań)
INSERT INTO security."loginHistory" (user_id, action_type_id, login_time, ip_adres) VALUES
( 6, 1, '2025-10-10 08:00:00', '192.168.1.10'),
( 6, 2, '2025-10-10 08:00:05', '192.168.1.10'), -- Nieudana próba
( 1, 1, '2025-10-10 08:05:00', '10.0.0.5'),
( 7, 1, '2025-10-11 12:00:00', '89.123.45.67'),
( 6, 3, '2025-10-10 09:30:00', '192.168.1.10'); -- Wylogowanie