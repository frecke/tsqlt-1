IF OBJECT_ID('tSQLt.Private_CreateFunctionFake') IS NOT NULL DROP PROCEDURE tSQLt.Private_CreateFunctionFake;
GO
---Build+
CREATE PROCEDURE tSQLt.Private_CreateFunctionFake
    @FunctionObjectId INT,
    @OriginalProcedureName NVARCHAR(MAX),
    @LogTableName NVARCHAR(MAX),
    @CommandToExecute NVARCHAR(MAX) = NULL
AS
BEGIN
    DECLARE @Cmd NVARCHAR(MAX);
    DECLARE @FuncParmList NVARCHAR(MAX),
            @TableColList NVARCHAR(MAX),
            @FuncParmTypeList NVARCHAR(MAX),
            @TableColTypeList NVARCHAR(MAX),
            @ReturnScalar NVARCHAR(MAX),
            @ParameterId INT;
            
    DECLARE @Seperator CHAR(1),
            @FuncParmTypeListSeparater CHAR(1),
            @ParamName sysname,
            @TypeName sysname,
            @IsOutput BIT,
            @IsCursorRef BIT;
            

    --PRINT 'Called: Private_CreateFunctionFake for ' + @OriginalProcedureName
    --TODO: look into pulling out some of this functionality into shared functions. A lot of this is shared between functions and procedures.  
    SELECT @Seperator = '', @FuncParmTypeListSeparater = '', 
           @FuncParmList = '', @TableColList = '', @FuncParmTypeList = '', @TableColTypeList = '';
        
    DECLARE Parameters CURSOR FOR
     SELECT p.parameter_id, p.name, t.TypeName, is_output, is_cursor_ref
       FROM sys.parameters p
       CROSS APPLY tSQLt.Private_GetFullTypeName(p.user_type_id,p.max_length,p.precision,p.scale,NULL) t
      WHERE object_id = @FunctionObjectId;
    
    /*
    DECLARE @SQL nvarchar(max) = 'SELECT p.parameter_id, p.name, t.TypeName, is_output, is_cursor_ref' +
       ' FROM sys.parameters p' +
       ' CROSS APPLY tSQLt.Private_GetFullTypeName(p.user_type_id,p.max_length,p.precision,p.scale,NULL) t' +
       ' WHERE object_id = ' + cast(@FunctionObjectId as nvarchar(max)) +
       ';'
    
    EXEC (@SQL);
    */
    
    
    OPEN Parameters;
    
    FETCH NEXT FROM Parameters INTO @ParameterId, @ParamName, @TypeName, @IsOutput, @IsCursorRef;
    WHILE (@@FETCH_STATUS = 0)
    BEGIN
        IF @ParameterId = 0
        BEGIN
          SELECT @ReturnScalar = 'RETURNS ' +
                          CASE WHEN @TypeName LIKE '%nchar%'
                                 OR @TypeName LIKE '%nvarchar%'
                               THEN 'nvarchar(MAX)'
                               WHEN @TypeName LIKE '%char%'
                               THEN 'varchar(MAX)'
                               ELSE @TypeName
                          END
        END
        
        ELSE IF @IsCursorRef = 0
        BEGIN
            SELECT @FuncParmList = @FuncParmList + @Seperator + @ParamName, 
                   @TableColList = @TableColList + @Seperator + '[' + STUFF(@ParamName,1,1,'') + ']', 
                   @FuncParmTypeList = @FuncParmTypeList + @FuncParmTypeListSeparater + @ParamName + ' ' + @TypeName + ' = NULL ' + 
                                       CASE WHEN @IsOutput = 1 THEN ' OUT' 
                                            ELSE '' 
                                       END, 
                   @TableColTypeList = @TableColTypeList + ',[' + STUFF(@ParamName,1,1,'') + '] ' + 
                          CASE WHEN @TypeName LIKE '%nchar%'
                                 OR @TypeName LIKE '%nvarchar%'
                               THEN 'nvarchar(MAX)'
                               WHEN @TypeName LIKE '%char%'
                               THEN 'varchar(MAX)'
                               ELSE @TypeName
                          END + ' NULL';

            SELECT @Seperator = ',';        
            SELECT @FuncParmTypeListSeparater = ',';
        END
        ELSE
        BEGIN
            SELECT @FuncParmTypeList = @FuncParmTypeListSeparater + @ParamName + ' CURSOR VARYING OUTPUT';
            SELECT @FuncParmTypeListSeparater = ',';
        END;
        
        FETCH NEXT FROM Parameters INTO @ParameterId, @ParamName, @TypeName, @IsOutput, @IsCursorRef;
    END;
    
    CLOSE Parameters;
    DEALLOCATE Parameters;
    
    DECLARE @InsertStmt NVARCHAR(MAX);
    --PRINT '@TableColList = ' + @TableColList
    SELECT @InsertStmt = 'INSERT INTO ' + @LogTableName + 
                         CASE WHEN @TableColList = '' THEN ' DEFAULT VALUES'
                              ELSE ' (' + @TableColList + ') SELECT ' + @FuncParmList
                         END + ';';
                         
    SELECT @Cmd = 'CREATE TABLE ' + @LogTableName + ' (_id_ int IDENTITY(1,1) PRIMARY KEY CLUSTERED ' + @TableColTypeList + ');';
    --PRINT 'Private_CreateFunctionFake: ' + ISNULL(@Cmd,'INSERT STATEMENT IS NULL')
    EXEC(@Cmd);

    SELECT @Cmd = 'CREATE FUNCTION ' + @OriginalProcedureName + ' (' + ISNULL(@FuncParmTypeList,'') + ') ' + 
                  ISNULL(@ReturnScalar, 'RETURNS TABLE') +
                  CASE WHEN @ReturnScalar IS NOT NULL THEN
                        ' AS BEGIN ' +  
                        ISNULL(@CommandToExecute, 'RETURN NULL') + ';' +
                        ' END;'
                      ELSE
                        ' AS RETURN (' + ISNULL(@CommandToExecute,'SELECT col1 = NULL') + ')'
                 END
                  
    --PRINT 'Private_CreateFunctionFake: ' + ISNULL(@Cmd,'CREATE STATEMENT IS NULL')
    --PRINT '========'
    EXEC(@Cmd);
    
    RETURN 0;
END;
---Build-
GO
