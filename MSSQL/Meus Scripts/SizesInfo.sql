/*
	Options:
		1 - SizeMB per database (Log and Data)
		2 - SizeMB per instance (Log and Data)
		3 - SizeGB per database (Log and Data)
		4 - SizeGB per instance (Log and Data)
*/
declare @opt int = 2


if (@opt = 1)
begin
	select tbl.name, tbl.filetype,tbl.sizemb from (
		select 
			t1.name,
			filetype = CASE t2.groupid WHEN 0 THEN 'LOG'
			ELSE 'DATA'
			END,
			sum(t2.size*8)/1024 as sizemb,
			(sum(t2.size*8)/1024)/1024 as sizegb 
		from
			sys.databases t1 inner join
			sys.sysaltfiles t2
				on t1.database_id = t2.dbid
		where 
			state_desc = 'ONLINE'
			and t1.database_id > 4
			and t1.name not in ('DBA')
		group by t1.name, t2.groupid
	) tbl
	order by tbl.name,tbl.filetype
end
if (@opt = 2)
begin
	select tbl.filetype, sum(tbl.sizemb) sizemb from (
	select 
			t1.name,
			filetype = CASE t2.groupid WHEN 0 THEN 'LOG'
			ELSE 'DATA'
			END,
			sum(t2.size*8)/1024 as sizemb,
			(sum(t2.size*8)/1024)/1024 as sizegb 
		from
			sys.databases t1 inner join
			sys.sysaltfiles t2
				on t1.database_id = t2.dbid
		where 
			state_desc = 'ONLINE'
			and t1.database_id > 4
			and t1.name not in ('DBA')
		group by t1.name, t2.groupid
	) tbl
	group by tbl.filetype
	order by tbl.filetype
end
if (@opt = 3)
begin
	select tbl.name, tbl.filetype,tbl.sizegb from (
		select 
			t1.name,
			filetype = CASE t2.groupid WHEN 0 THEN 'LOG'
			ELSE 'DATA'
			END,
			sum(t2.size*8)/1024 as sizemb,
			(sum(t2.size*8)/1024)/1024 as sizegb 
		from
			sys.databases t1 inner join
			sys.sysaltfiles t2
				on t1.database_id = t2.dbid
		where 
			state_desc = 'ONLINE'
			and t1.database_id > 4
			and t1.name not in ('DBA')
		group by t1.name, t2.groupid
	) tbl
	order by tbl.name,tbl.filetype
end
if (@opt = 4)
begin
	select tbl.filetype, sum(tbl.sizegb) sizegb from (
	select 
			t1.name,
			filetype = CASE t2.groupid WHEN 0 THEN 'LOG'
			ELSE 'DATA'
			END,
			sum(t2.size*8)/1024 as sizemb,
			(sum(t2.size*8)/1024)/1024 as sizegb 
		from
			sys.databases t1 inner join
			sys.sysaltfiles t2
				on t1.database_id = t2.dbid
		where 
			state_desc = 'ONLINE'
			and t1.database_id > 4
			and t1.name not in ('DBA')
		group by t1.name, t2.groupid
	) tbl
	group by tbl.filetype
	order by tbl.filetype
end