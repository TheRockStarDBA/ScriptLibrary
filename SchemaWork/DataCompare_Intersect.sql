--Got this from Paul White's blog post here:
-- http://sqlblog.com/blogs/paul_white/archive/2011/06/22/undocumented-query-plans-equality-comparisons.aspx

--obviously, replace @Set1/@Set2 with table names, and the join condition with the PK field(s)
--remember to index appropriately

SELECT * 
FROM @Set1 AS t
	JOIN @Set2 AS s 
		ON s.pk = t.pk
WHERE NOT EXISTS (SELECT s.* INTERSECT SELECT t.*)
