use ReportServer
go
declare @ReportMatchingTag varchar(100) = 'scorecard';
declare @WeeksBack int=7,
		@i int = 0, 
		@TimeRangeEnd datetime = '2016-01-31'; 

IF OBJECT_ID('tempdb..#Ranges') IS NOT NULL
BEGIN
	DROP TABLE #Ranges
END

CREATE TABLE #Ranges (
	StartDate datetime,
	EndDate datetime
);

while @i < @WeeksBack
begin
	insert into #Ranges (
		StartDate, EndDate 
	)
	SELECT dateadd(week, 0-(@i+1), @TimeRangeEnd), 
		dateadd(week, 0-@i, @TimeRangeEnd)

	set @i = @i + 1
end



select ItemPath, 
	RangeBegin = convert(date,StartDate), 
	RangeEnd = convert(date,EndDate), 
	[#Exec] = CONVERT(varchar(20),[#Exec]) + CASE WHEN ISNULL([#ManyRecs],0) > 0 THEN '   [' + CONVERT(varchar(20),[#ManyRecs]) + ']' ELSE '' END,
	[AvgTotalDur(ms)] = CONVERT(varchar(30), AvgTotalDurMS_small/[#Exec]) + 
			CASE WHEN ISNULL([#ManyRecs],0) > 0 THEN '   [' + CONVERT(varchar(30),[AvgTotalDurMS_large]) + ']' ELSE '' END, 
	[AvgTDR] = CONVERT(varchar(30), AvgTDR_small) + 
			CASE WHEN ISNULL([#ManyRecs],0) > 0 THEN '   [' + CONVERT(varchar(30),[AvgTDR_large]) + ']' ELSE '' END, 
	[MinTDR] = CONVERT(varchar(30), MinTDR_small) + 
			CASE WHEN ISNULL([#ManyRecs],0) > 0 THEN '   [' + CONVERT(varchar(30),[MinTDR_large]) + ']' ELSE '' END, 
	[MaxTDR] = CONVERT(varchar(30), MaxTDR_small) + 
			CASE WHEN ISNULL([#ManyRecs],0) > 0 THEN '   [' + CONVERT(varchar(30),[MaxTDR_large]) + ']' ELSE '' END, 
			
	[0-10sec] = CASE WHEN [0-10sec] = 0 THEN '' ELSE CONVERT(varchar(30), [0-10sec]) END + 
			CASE WHEN [m0-10sec] > 0 THEN '   [' + CONVERT(varchar(30),[m0-10sec]) + ']' ELSE '' END,
	[10-30sec] = CASE WHEN [10-30sec] = 0 THEN '' ELSE CONVERT(varchar(30), [10-30sec]) END + 
			CASE WHEN [m10-30sec] > 0 THEN '   [' + CONVERT(varchar(30),[m10-30sec]) + ']' ELSE '' END,
	[30-60sec] = CASE WHEN [30-60sec] = 0 THEN '' ELSE CONVERT(varchar(30), [30-60sec]) END + 
			CASE WHEN [m30-60sec] > 0 THEN '   [' + CONVERT(varchar(30),[m30-60sec]) + ']' ELSE '' END,
	[60-90sec] = CASE WHEN [60-90sec] = 0 THEN '' ELSE CONVERT(varchar(30), [60-90sec]) END + 
			CASE WHEN [m60-90sec] > 0 THEN '   [' + CONVERT(varchar(30),[m60-90sec]) + ']' ELSE '' END,
	[90-120sec] = CASE WHEN [90-120sec] = 0 THEN '' ELSE CONVERT(varchar(30), [90-120sec]) END + 
			CASE WHEN [m90-120sec] > 0 THEN '   [' + CONVERT(varchar(30),[m90-120sec]) + ']' ELSE '' END,
	[2-3min] = CASE WHEN [2-3min] = 0 THEN '' ELSE CONVERT(varchar(30), [2-3min]) END + 
			CASE WHEN [m2-3min] > 0 THEN '   [' + CONVERT(varchar(30),[m2-3min]) + ']' ELSE '' END,
	[3-4min] = CASE WHEN [3-4min] = 0 THEN '' ELSE CONVERT(varchar(30), [3-4min]) END + 
			CASE WHEN [m3-4min] > 0 THEN '   [' + CONVERT(varchar(30),[m3-4min]) + ']' ELSE '' END,
	[4-5min] = CASE WHEN [4-5min] = 0 THEN '' ELSE CONVERT(varchar(30), [4-5min]) END + 
			CASE WHEN [m4-5min] > 0 THEN '   [' + CONVERT(varchar(30),[m4-5min]) + ']' ELSE '' END,
	[5-10min] = CASE WHEN [5-10min] = 0 THEN '' ELSE CONVERT(varchar(30), [5-10min]) END + 
			CASE WHEN [m5-10min] > 0 THEN '   [' + CONVERT(varchar(30),[m5-10min]) + ']' ELSE '' END,
	[10-15min] = CASE WHEN [10-15min] = 0 THEN '' ELSE CONVERT(varchar(30), [10-15min]) END + 
			CASE WHEN [m10-15min] > 0 THEN '   [' + CONVERT(varchar(30),[m10-15min]) + ']' ELSE '' END,
	[15min+] = CASE WHEN [15min+] = 0 THEN '' ELSE CONVERT(varchar(30), [15min+]) END + 
			CASE WHEN [m15min+] > 0 THEN '   [' + CONVERT(varchar(30),[m15min+]) + ']' ELSE '' END,
	[AvgProcessing] = CONVERT(varchar(30), Avg_TimeProcessing_small) + 
			CASE WHEN ISNULL([#ManyRecs],0) > 0 THEN '   [' + CONVERT(varchar(30),[Avg_TimeProcessing_large]) + ']' ELSE '' END, 			
	[AvgRendering] = CONVERT(varchar(30), Avg_TimeRendering_small) + 
			CASE WHEN ISNULL([#ManyRecs],0) > 0 THEN '   [' + CONVERT(varchar(30),[Avg_TimeRendering_large]) + ']' ELSE '' END
from (
select 
	StartDate, EndDate, ss.ItemPath, 
	SUM(CASE WHEN ManyRecords = 0 THEN 1 ELSE 0 END) as [#Exec],
	SUM(ManyRecords) as [#ManyRecs],
	SUM(CASE WHEN ManyRecords=0 THEN TotalDur_ms ELSE 0 END) as AvgTotalDurMS_small,
	SUM(CASE WHEN ManyRecords=1 THEN TotalDur_ms ELSE 0 END) as AvgTotalDurMS_large,
	avg(CASE WHEN ManyRecords=0 THEN TimeDataRetrieval ELSE null END) as AvgTDR_small,
	avg(CASE WHEN ManyRecords=1 THEN TimeDataRetrieval ELSE null END) as AvgTDR_large,
	min(CASE WHEN ManyRecords=0 THEN TimeDataRetrieval ELSE null END) as MinTDR_small,
	min(CASE WHEN ManyRecords=1 THEN TimeDataRetrieval ELSE null END) as MinTDR_large,
	max(CASE WHEN ManyRecords=0 THEN TimeDataRetrieval ELSE null END) as MaxTDR_small, 
	max(CASE WHEN ManyRecords=1 THEN TimeDataRetrieval ELSE null END) as MaxTDR_large, 
	[0-10sec] = SUM(Case when TimeDataRetrieval BETWEEN 0 and 10000 AND ManyRecords=0 THEN 1 ELSE 0 END),
	[10-30sec] = SUM(Case when TimeDataRetrieval BETWEEN 10001 and 30000 AND ManyRecords=0 THEN 1 ELSE 0 END),
	[30-60sec] = SUM(Case when TimeDataRetrieval BETWEEN 30001 and 60000 AND ManyRecords=0 THEN 1 ELSE 0 END),
	[60-90sec] = SUM(Case when TimeDataRetrieval BETWEEN 60001 and 90000 AND ManyRecords=0 THEN 1 ELSE 0 END),
	[90-120sec] = SUM(Case when TimeDataRetrieval BETWEEN 90001 and 120000 AND ManyRecords=0 THEN 1 ELSE 0 END),
	[2-3min] = SUM(Case when TimeDataRetrieval BETWEEN 120001 and 180000 AND ManyRecords=0 THEN 1 ELSE 0 END),
	[3-4min] = SUM(Case when TimeDataRetrieval BETWEEN 180001 and 240000 AND ManyRecords=0 THEN 1 ELSE 0 END),
	[4-5min] = SUM(Case when TimeDataRetrieval BETWEEN 240001 and 300000 AND ManyRecords=0 THEN 1 ELSE 0 END),
	[5-10min] = SUM(Case when TimeDataRetrieval BETWEEN 300001 and 600000 AND ManyRecords=0 THEN 1 ELSE 0 END),
	[10-15min] = SUM(Case when TimeDataRetrieval BETWEEN 600001 and 900000 AND ManyRecords=0 THEN 1 ELSE 0 END),
	[15min+] = SUM(Case when TimeDataRetrieval >= 900000 THEN 1 ELSE 0 END),
	
	avg(CASE WHEN ManyRecords=0 THEN TimeProcessing ELSE 0 END) as Avg_TimeProcessing_small,
	avg(CASE WHEN ManyRecords=1 THEN TimeProcessing ELSE 0 END) as Avg_TimeProcessing_large,
	avg(CASE WHEN ManyRecords=0 THEN TimeRendering ELSE 0 END) as Avg_TimeRendering_small,
	avg(CASE WHEN ManyRecords=1 THEN TimeRendering ELSE 0 END) as Avg_TimeRendering_large,
	
	[m0-10sec] = SUM(Case when TimeDataRetrieval BETWEEN 0 and 10000 AND ManyRecords=1 THEN 1 ELSE 0 END),
	[m10-30sec] = SUM(Case when TimeDataRetrieval BETWEEN 10001 and 30000 AND ManyRecords=1 THEN 1 ELSE 0 END),
	[m30-60sec] = SUM(Case when TimeDataRetrieval BETWEEN 30001 and 60000 AND ManyRecords=1 THEN 1 ELSE 0 END),
	[m60-90sec] = SUM(Case when TimeDataRetrieval BETWEEN 60001 and 90000 AND ManyRecords=1 THEN 1 ELSE 0 END),
	[m90-120sec] = SUM(Case when TimeDataRetrieval BETWEEN 90001 and 120000 AND ManyRecords=1 THEN 1 ELSE 0 END),
	[m2-3min] = SUM(Case when TimeDataRetrieval BETWEEN 120001 and 180000 AND ManyRecords=1 THEN 1 ELSE 0 END),
	[m3-4min] = SUM(Case when TimeDataRetrieval BETWEEN 180001 and 240000 AND ManyRecords=1 THEN 1 ELSE 0 END),
	[m4-5min] = SUM(Case when TimeDataRetrieval BETWEEN 240001 and 300000 AND ManyRecords=1 THEN 1 ELSE 0 END),
	[m5-10min] = SUM(Case when TimeDataRetrieval BETWEEN 300001 and 600000 AND ManyRecords=1 THEN 1 ELSE 0 END),
	[m10-15min] = SUM(Case when TimeDataRetrieval BETWEEN 600001 and 900000 AND ManyRecords=1 THEN 1 ELSE 0 END),
	[m15min+] = SUM(Case when TimeDataRetrieval >= 900000 AND ManyRecords=1 THEN 1 ELSE 0 END)
from (
	select r.StartDate, r.EndDate,
		REPLACE(l.ItemPath,'/Live.Reports/','') as ItemPath, convert(bigint,datediff(ms, TimeStart, TimeEnd)) as TotalDur_ms, 
		convert(bigint,l.TimeDataRetrieval) as TimeDataRetrieval, l.TimeProcessing, l.TimeRendering,
		ManyRecords = CASE WHEN l.[RowCount] > 50000 THEN 1 ELSE 0 END 
	from dbo.ExecutionLog3 l
		inner join #Ranges r
			ON l.TimeStart between r.StartDate AND r.EndDate
	where 1=1
	and l.itemPath <> ''
	and l.ItemPath like '%' + @ReportMatchingTag + '%'

	and l.Status = 'rsSuccess'
	--only want stuff during the business day 
	and datepart(hour, l.TimeStart) between 6 and 17
	and l.source = 'Live'
) ss
group by StartDate, EndDate, ItemPath 
) ss2
order by ItemPath, StartDate, EndDate 

