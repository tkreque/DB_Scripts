DECLARE @tstamp BIGINT
DECLARE @newTime DATETIME
DECLARE @startTime DATETIME
SET @tstamp = ( SELECT TOP 1 timestamp FROM sys.dm_os_ring_buffers WHERE ring_buffer_type = 'TYPE_GOES_HERE' ORDER BY timestamp DESC )
SET @startTime = '1970-01-01 00:00:00.000'
SET @newTime = DATEADD(ss,@tstamp,@startTime)
SELECT @newTime