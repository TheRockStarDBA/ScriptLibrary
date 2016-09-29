--From chapter 3 of Itzik's SQL 2005 book "T-SQL Querying". Removes literals so we can get the query pattern.
-- Not really needed anymore with the query_hash column's addition.

create function dbo.fn_SQLSigTSQL
	(@p1 ntext, @parselength int = 4000)
returns nvarchar(4000)
as
begin
	declare @pos as int;
	declare @mode as char(10);
	declare @maxlength as int;
	declare @p2 as nchar(4000);
	declare @currchar as char(1), @nextchar as char(1);
	declare @p2len as int;
	
	set @maxlength = LEN(rtrim(substring(@p1, 1, 4000)));
	set @maxlength = case when @maxlength > @parselength then @parselength else @maxlength end;
	
	set @pos = 1;
	set @p2 = '';
	set @p2len = 0;
	set @currchar = '';
	set @nextchar = '';
	set @mode = 'command';
	
	while (@pos <= @maxlength)
	begin
		set @currchar = SUBSTRING(@p1, @pos, 1);
		set @nextchar = SUBSTRING(@p1, @pos+1, 1);
		if @mode = 'command' 
		begin 
			set @p2 = LEFT(@p2, @p2len) + @currchar;
			set @p2len = @p2len + 1;
			if @currchar in (',', '(', ' ', '=', '<', '>', '!')
				and @nextchar between '0' and '9'
			begin 
				set @mode = 'number'; 
				set @p2 = LEFT(@p2,@p2len) + '#'; 
				set @p2len = @p2len + 1;
			end 
			
			if @currchar = '''' 
			begin 
				set @mode = 'literal'; 
				set @p2 = LEFT(@p2, @p2len) + '#'''; 
				set @p2len = @p2len + 2; 
			end 
		end 
		else if @mode = 'number' and @nextchar in (',', ')', ' ', '=', '<', '>', '!')
			set @mode = 'command';
		else if @mode = 'literal' and @currchar = '''' 
			set @mode = 'command'; 
			
		set @pos = @pos + 1;
	end 
	return @p2;
end
