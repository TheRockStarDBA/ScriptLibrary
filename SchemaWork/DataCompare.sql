--Got this from Paul White's blog post here:
-- http://sqlblog.com/blogs/paul_white/archive/2011/06/22/undocumented-query-plans-equality-comparisons.aspx

--obviously, replace @Set1/@Set2 with table names, and the join condition with the PK field(s)
--remember to index appropriately

SELECT * 
FROM @Set1 AS t
	JOIN @Set2 AS s 
		ON s.pk = t.pk
WHERE NOT EXISTS (SELECT s.* INTERSECT SELECT t.*)


--Another way
--Use this to create a table comparison query when you need to compare two tables (or derived tables) on a column by column basis.

select 'AND COALESCE(n.' + c.[name] + ',' +
	CASE WHEN t.[name] = 'int' THEN '-99999'
		WHEN t.[name] = 'varchar' THEN '''<NL>'''
		WHEN t.[name] = 'datetime' THEN '''1905-05-05'''
		WHEN t.[name] = 'money' THEN '-5.55'
		WHEN t.[name] = 'decimal' THEN '-55.55'
		WHEN t.[name] = 'bit' THEN '''BITTTTTTTLLLLLYYYYYYYY'''
	END

+
') = COALESCE(o.' + c.[name] + ',' + 
	CASE WHEN t.[name] = 'int' THEN '-99999'
		WHEN t.[name] = 'varchar' THEN '''<NL>'''
		WHEN t.[name] = 'datetime' THEN '''1905-05-05'''
		WHEN t.[name] = 'money' THEN '-5.55'
		WHEN t.[name] = 'decimal' THEN '-55.55'
		WHEN t.[name] = 'bit' THEN '''BITTTTTTTLLLLLYYYYYYYY'''
	END
+
')' AS Col1

,c.xtype, t.[name]
from dbo.syscolumns c
	inner join dbo.systypes t
		on c.xtype = t.xtype
where id = object_id('dbo.ontrac_summarysnapshot_new')
order by colid
