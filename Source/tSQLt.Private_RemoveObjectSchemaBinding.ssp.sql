--Changes definition of an object by removing the 'with schemabinding' option.
--Some objects cannot be renamed because they are used in dependant objects 
--that have been declared 'whe schemabinding'. This prevents renaming objects
--which causes problems for tSQLt.FakeTables and tSQLt.SpyProcedure.

IF OBJECT_ID('tSQLt.Private_RemoveObjectSchemaBinding') IS NOT NULL DROP PROCEDURE tSQLt.Private_RemoveObjectSchemaBinding;
GO
---Build+
CREATE PROCEDURE tSQLt.Private_RemoveObjectSchemaBinding
    @ObjectName NVARCHAR(MAX)
AS
BEGIN   
   DECLARE @ObjectId INT = OBJECT_ID(@ObjectName);
   
   DECLARE @Sql NVARCHAR(MAX) = OBJECT_DEFINITION(@ObjectId)
   SET @Sql = REPLACE(@Sql,'CREATE', 'ALTER')
   SET @Sql = REPLACE(@Sql,'with schemabinding', '') -- remove schema binding
   --print @Sql
   EXEC sp_executeSQL @Sql
END
---Build-
GO
