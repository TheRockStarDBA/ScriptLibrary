USE <db name>
GO

DECLARE @MaxID INT, @DecrementID INT, @Decrement INT = 50000000,
	@MaxDate DATE, @DecrementDate DATE;

SELECT @MaxID = IDcol, 
	@MaxDate = CONVERT(DATE, Datecol )
FROM (
	SELECT TOP 1 
		IDcol = <ID column, 
		Datecol = <date or datetime column
	FROM dbo.<large table>
	ORDER BY 1 DESC 
	) ss
;

SELECT @DecrementID = IDcol,
	@DecrementDate = CONVERT(DATE, Datecol)
FROM (
	SELECT TOP 1 
		IDcol = <ID column>, 
		Datecol = <date or datetime column
	FROM dbo.<large table>
	WHERE <ID column> <= (@MaxID - @Decrement)
	ORDER BY 1 DESC 
	) ss
;



IF @MaxID IS NULL OR @MaxDate IS NULL OR @DecrementID IS NULL OR @DecrementDate IS NULL
BEGIN
	SELECT 'One of the variables is NULL', @MaxID, @MaxDate, @DecrementID, @DecrementDate
END
ELSE
BEGIN
	select @MaxID, @MaxDate, @DecrementID, @DecrementDate, 
		(@MaxID - @DecrementID) as ID_diff, DATEDIFF(day, @DecrementDate, @MaxDate) as Day_diff,
		RatePerDay = (@MaxID - @DecrementID)*1. / DATEDIFF(day, @DecrementDate, @MaxDate)*1.,
		NumLeft = (2147483647-@MaxID)

	select ExhaustionDate = dateadd(day, col1, getdate())
	from 
		(select col1 = (2147483647-@MaxID)*1./
			((@MaxID - @DecrementID)*1. / DATEDIFF(day, @DecrementDate, @MaxDate)*1.)
		) ss

END
