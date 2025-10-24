/*
 --
 Procedura: parties.sp_AddNewEmployee
 Opis: Dodaje nowego pracownika do bazy danych.
 Uwaga! problem przy migracji
 --
*/

CREATE PROCEDURE parties.sp_AddNewEmployee(
    p_name VARCHAR(20),
    p_surname VARCHAR(60),
    p_position_name VARCHAR(30)
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_position_id INT;
BEGIN
    SELECT position_id INTO v_position_id
    FROM parties.positions
    WHERE name = p_position_name;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Nie można dodac pracownika. Stanowisko o nazwie "%" nie istnieje.', p_position_name;
    END IF;

    INSERT INTO parties.employee (name, surname, position_id)
    VALUES (p_name, p_surname, v_position_id);

    RAISE NOTICE 'Pomyslnie dodano pracownika: % % (Stanowisko: %)', p_name, p_surname, p_position_name;
END;
$$