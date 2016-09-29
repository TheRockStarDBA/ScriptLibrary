use reportserver 
go
/******************************** Query 1 ****************************************/
--: Given an SRD, returns the various reports that reference that proc in their data sets
SELECT RSPath, ReportName, RDLXML, RDLString
FROM (
SELECT [Path] as RSPath, [name] AS ReportName
, CONVERT(XML, CONVERT(VARBINARY(MAX), Content)) AS RDLXML --has the whole report, but need to use XML functions to convert
, CONVERT(NVARCHAR(MAX),CONVERT(XML, CONVERT(VARBINARY(MAX), [Content]))) AS RDLstring
FROM ReportServer.dbo.Catalog
WHERE [type] = 2 --only want objects of type "Report"
) SS
WHERE RDLString LIKE '%procedurename%'
GO

/******************************** Query 2 ****************************************/
--: Given a Report Name, finds all data sets that it uses and the associated SQL query/procedure

/* This XML searches a structure like this: 
 <DataSets>
    <DataSet Name="MyProcName">
      <Query>
        <DataSourceName>myDSYo</DataSourceName>
        <CommandType>StoredProcedure</CommandType>
        <CommandText>MyProcName</CommandText>
        <rd:UseGenericDesigner>true</rd:UseGenericDesigner>
      </Query>
      <Fields>
        <Field Name="ID">
          <DataField>ID</DataField>
          <rd:TypeName>System.Int32</rd:TypeName>
        </Field>
      </Fields>
    </DataSet>
 */
SELECT 
	RSPath, 
	ReportName, 
	RDLXML, 
	[SourceDatabase] = x.value('(./*:DataSourceName/text())[1]', 'nvarchar(max)'),
	[CommandType] = ISNULL(x.value('(./*:CommandType/text())[1]','nvarchar(1024)'),'Query'), 
	[CommandText] = x.value('(./*:CommandText/text())[1]','nvarchar(max)') 
FROM (
	SELECT 
		[Path] as RSPath, 
		[name] as ReportName,
		[RDLXML] = CONVERT(XML, CONVERT(VARBINARY(MAX), Content)) --has the whole report, but convert to XML so we can XQuery it
	FROM ReportServer.dbo.Catalog 
	WHERE [type] = 2 --only want objects of type "Report"
	and [name] LIKE '%report%'
) SS
OUTER APPLY RDLXML.nodes('//*:Query') as r(x)

/******************************** Query 3 ****************************************/
--: Given a Report Name, finds all subreports used by this report

/* This XML searches a structure like this: 
  <ReportSections>
    <ReportSection>
      <Body>
        <ReportItems>
          <Subreport Name="SubReport_MyScoreboard">
            <ReportName>MyScoreboard</ReportName>
            <Parameters>
 */
SELECT 
	RSPath, 
	ReportName, 
	RDLXML, 
	[ReportName] = x.value('(./*:ReportName/text())[1]', 'nvarchar(max)')
FROM (
	SELECT 
		[Path] as RSPath, 
		[name] as ReportName,
		[RDLXML] = CONVERT(XML, CONVERT(VARBINARY(MAX), Content)) --has the whole report, but convert to XML so we can XQuery it
	FROM ReportServer.dbo.Catalog 
	WHERE [type] = 2 --only want objects of type "Report"
	and [name] LIKE '%reportName%'
) SS
OUTER APPLY RDLXML.nodes('//*:Subreport') as r(x)
