USE msdb;
GO

EXEC sp_add_job
    @job_name = N'msjob',
    @enabled = 1;
GO

EXEC sp_add_jobstep
    @job_name = N'msjob',
    @step_name = N'Ustaw status Wygasła',
    @subsystem = N'TSQL',
    @database_name = N'bank_db_etl',
    @command = N'
DECLARE @ExpiredStatusID INT;

SELECT @ExpiredStatusID = [card_status_id]
FROM [accounts].[card_statuses]
WHERE [name] = N''Wygasła'';

IF @ExpiredStatusID IS NOT NULL
BEGIN
    UPDATE [accounts].[card]
    SET
        [card_status_id] = @ExpiredStatusID
    WHERE
        [expiry_date] < CAST(GETDATE() AS DATE)
        AND
        [card_status_id] != @ExpiredStatusID;
END
ELSE
BEGIN
    -- Ten błąd już nie powinien wystąpić
    RAISERROR(''Krytyczny błąd: Nie odnaleziono statusu "Wygasła".'', 16, 1);
END;
';
GO

EXEC sp_add_schedule
    @schedule_name = N'msjob-schedule',
    @freq_type = 4, @freq_interval = 1,
    @active_start_time = 141500;
GO

EXEC sp_attach_schedule
   @job_name = N'msjob',
   @schedule_name = N'msjob-schedule';
GO

EXEC sp_add_jobserver
    @job_name = N'msjob';
GO