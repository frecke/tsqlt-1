IF OBJECT_ID('tSQLt.FakeFunction') IS NOT NULL DROP PROCEDURE tSQLt.FakeFunction;
GO
---Build+
CREATE PROCEDURE tSQLt.FakeFunction
    @FunctionName NVARCHAR(MAX),
    @CommandToExecute NVARCHAR(MAX) = NULL
AS
BEGIN
  DECLARE @FunctionObjectId INT;
  SELECT @FunctionObjectId = OBJECT_ID(@FunctionName);
  
  EXEC tSQLt.Private_ValidateFunctionCanBeUsedWithFakeFunction @FunctionName;
    
  DECLARE @LogTableName NVARCHAR(MAX);
  SELECT @LogTableName = QUOTENAME(OBJECT_SCHEMA_NAME(@FunctionObjectId)) + '.' + QUOTENAME(OBJECT_NAME(@FunctionObjectId)+'_FakeFunctionLog');
  
  EXEC tSQLt.Private_RenameObjectToUniqueNameUsingObjectId @FunctionObjectId;
  
  EXEC tSQLt.Private_CreateFunctionFake @FunctionObjectId, @FunctionName, @LogTableName, @CommandToExecute;
END
---Build-
GO