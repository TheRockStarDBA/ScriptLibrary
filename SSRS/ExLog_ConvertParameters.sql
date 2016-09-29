USE ReportServer 
GO
SELECT top 100 
	l.ItemPath, l.TimeStart, l.TimeEnd, l.TimeDataRetrieval, l.TimeProcessing, l.TimeRendering,
	l.RequestType, l.Format, l.[RowCount], l.ByteCount,
	REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
		CONVERT(varchar(max),l.Parameters),
		'%3A',':'), '%2F', '/'), '%20', ' '),'%5C','\'),':isnull=true','=NULL'),'&',',@')
FROM dbo.ExecutionLog3 l
WHERE l.ItemPath = '/Live.Reports/<tag>'
AND l.Source = 'Live'
AND l.Status IN ('rsSuccess')
order by l.TimeStart desc;
