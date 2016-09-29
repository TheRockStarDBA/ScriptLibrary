IF OBJECT_ID('TempDB..#showfilestats1') IS NOT NULL
BEGIN
 DROP TABLE #showfilestats1 
END

CREATE TABLE #showfilestats1 (FileID INT, [FileGroup] INT, TotalExtents BIGINT, UsedExtents BIGINT, lname varchar(512), pname varchar(512))
INSERT INTO #showfilestats1 (FileID, [FileGroup], TotalExtents, UsedExtents, lname, pname)
 EXEC ('DBCC showfilestats')

SELECT ss.FileGroup, FileGroupName, ss.Physical_Name as FilePathName, ss.Logical_Name as FileLogicalName, ss.FileID, 
 ss.FileSize_GB, ss.UsedSize_GB,  [FreeSpace_GB] = ss.filesize_GB - ss.UsedSize_GB,
 [FilePctFull] = CONVERT(varchar(20),CONVERT(decimal(15,1),100*(ss.UsedSize_GB/ss.FileSize_GB)))+'%' ,
 ss.TotalDBSize_GB, ss.TotalUsedSize_GB,
 [PctOfTotalFileSize] = convert(varchar(20),convert(decimal(15,1),(100*ss.FileSize_GB / ss.TotalDBSize_GB))) + '%',
 [PctOfTotalUsedSize] = convert(varchar(20),convert(decimal(15,1),(100*ss.UsedSize_GB / ss.TotalUsedSize_GB))) + '%'
FROM (SELECT t.FileGroup, dsp.name as FileGroupName ,
 [Physical_Name]=t.pname, 
 [Logical_Name] = t.lname, 
 t.FileID, 
 [FileSize_GB] = CONVERT(DECIMAL(15,1),CONVERT(DECIMAL(15,3),t.TotalExtents)*64./1024./1024.),
 [UsedSize_GB] = CONVERT(DECIMAL(15,1),CONVERT(DECIMAL(15,3),t.UsedExtents)*64./1024./1024.), 
 [TotalDBSize_GB] = CONVERT(DECIMAL(15,1),CONVERT(DECIMAL(15,3),(SUM(TotalExtents) OVER ()))*64./1024./1024.),
 [TotalUsedSize_GB] = CONVERT(DECIMAL(15,1),CONVERT(DECIMAL(15,3),(SUM(UsedExtents) OVER ()))*64./1024./1024.)
FROM #showfilestats1 t 
 inner join sys.data_spaces dsp
  on dsp.data_space_id = t.FileGroup
) ss
ORDER BY FileGroup ASC
