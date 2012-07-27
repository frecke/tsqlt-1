IF OBJECT_ID('tSQLt.Private_RemoveSchemaBindingFromReferencingObjects') IS NOT NULL DROP PROCEDURE tSQLt.Private_RemoveSchemaBindingFromReferencingObjects;
GO
---Build+
CREATE PROCEDURE tSQLt.Private_RemoveSchemaBindingFromReferencingObjects
        @TableName NVARCHAR(MAX)
AS
BEGIN
  -- delete temptable
  IF EXISTS(SELECT * FROM tempdb..sysobjects WHERE id = OBJECT_ID('tempdb.dbo.#temp'))
    DROP TABLE #TEMP

  --recursively get all referencing dependencies
;WITH ReferencedDependencies (parentId, name, LEVEL)
  AS(
      SELECT DISTINCT o.object_id AS parentId, name = tSQLt.Private_GetQuotedFullName(o.object_id), 0 AS LEVEL
        FROM sys.sql_expression_dependencies AS d
        JOIN sys.objects AS o
          ON d.referencing_id = o.object_id
            AND o.type IN ('FN','IF','TF', 'V', 'P')
            AND is_schema_bound_reference = 1
        WHERE
          d.referencing_class = 1 AND d.referenced_id = OBJECT_ID(@TableName)
      UNION ALL
      SELECT o.object_id AS parentId, name = tSQLt.Private_GetQuotedFullName(o.object_id), LEVEL +1
        FROM sys.sql_expression_dependencies AS d
        JOIN sys.objects AS o
                ON d.referencing_id = o.object_id
            AND o.type IN ('FN','IF','TF', 'V', 'P')
            AND is_schema_bound_reference = 1
        JOIN ReferencedDependencies AS RD
                ON d.referenced_id = rd.parentId
  )

  -- select all objects referencing this table in reverse level order
  SELECT DISTINCT IDENTITY(INT, 1,1) AS id, name, LEVEL
  INTO #TEMP
  FROM ReferencedDependencies
  --WHERE OBJECT_DEFINITION(parentId) LIKE '%SCHEMABINDING%'
  ORDER BY LEVEL DESC
  OPTION (Maxrecursion 10000)
  
  --change the definition.
  DECLARE @currentRecord INT
  DECLARE @ReferencingTableName NVARCHAR(MAX)
  SET @currentRecord = 1
  WHILE (@currentRecord <= (SELECT COUNT(1) FROM #TEMP) )
  BEGIN
          SET @ReferencingTableName = ''
          SELECT @ReferencingTableName = #TEMP.name
            FROM #TEMP 
            WHERE #TEMP.id = @currentRecord
          EXEC tSQLt.Private_RemoveObjectSchemaBinding @ReferencingTableName  -- remove schema binding
          SET @currentRecord = @currentRecord + 1
  END
END