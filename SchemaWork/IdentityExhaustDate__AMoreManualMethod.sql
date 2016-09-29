-- The T-SQL below gives the rate-per-day calculation and exhaustion date, but requires more manual input.

declare		
	@MaxID int = 1934907947, 
	@MaxDate int = 20160927, 

	--@DecrementID int = 1883370950,	--going back about 51 M
	--@DecrementDate int = 20160824	-- 1.52 M per day, 140 days left, Feb 14 2017

	--@DecrementID int = 1835166744,		--going back about 100 M
	--@DecrementDate int = 20160724	--1.53 M per day, 138 days left, Feb 12, 2017

	--@DecrementID int = 1734190003,		--going back about 200 M
	--@DecrementDate int = 20160517	--1.51 M per day, 140 days left, Feb 14, 2017

	--@DecrementID int = 1635283803,		--going back about 300 M
	--@DecrementDate int = 20160310	--1.49 M per day, 142 days left, Feb 16, 2017

	--@DecrementID int = 1535114454,		--going back about 400 M
	--@DecrementDate int = 20151231	--1.48 M per day, 144 days left, Feb 18, 2017

	@DecrementID int = 1234647043,		--going back about 700 M
	@DecrementDate int = 20150526	--1.42 M per day, 149 days left, Feb 22, 2017
select *,
	ExhaustionDate = dateadd(day, DaysLeft, getdate())
from (
	select 
		delta1, earlydate, laterdate,
		RatePerDay = CONVERT(int, RatePerDay), 
		NumLeft, 
		DaysLeft = (NumLeft*1.) / RatePerDay
	from (
		select 
			delta1, 
			earlydate, laterdate, 
			RatePerDay = ( delta1 *1. ) / ( datediff(day, earlydate, laterdate) * 1.),
			NumLeft = (2147483647-@MaxID)
		from 
			(select 
				@MaxID - @DecrementID as delta1, 
				convert(date,convert(varchar(20),@DecrementDate)) as earlydate, 
				convert(date,convert(varchar(20),@MaxDate)) as laterdate) ss
	) ss2
) ss3
--1,934,907,947 
