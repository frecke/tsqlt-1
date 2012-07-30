EXEC tSQLt.NewTestClass 'SpyFunctionTests';
GO
CREATE PROC SpyFunctionTests.[test SpyFunction should allow tester to not execute behavior of scalar function returning an int]
AS
BEGIN

    EXEC('
      create function dbo.InnerFunction()
      returns int
      as
      begin
          return cast(''Original InnerFunction was executed'' as int);
      end;
    ');
    
    EXEC tSQLt.FakeFunction 'dbo.InnerFunction';

    DECLARE @actual as int
    
    SELECT @actual = dbo.InnerFunction()
    
    EXEC tSQLt.AssertEquals null, @actual

END;
GO
CREATE PROC SpyFunctionTests.[test SpyFunction should allow tester to not execute behavior of scalar function returning a string]
AS
BEGIN

    EXEC('
      create function dbo.InnerFunction()
      returns nvarchar(max)
      as
      begin
          return ''Original InnerFunction was executed'';
      end;
    ');
    
    EXEC tSQLt.FakeFunction 'dbo.InnerFunction';
    
    DECLARE @actual as nvarchar(max)
    
    SELECT @actual = dbo.InnerFunction()
    
    EXEC tSQLt.AssertEqualsString null, @actual

END;
GO

CREATE PROC SpyFunctionTests.[test SpyFunction should allow tester to not execute behavior of inline table-valued function]
AS
BEGIN

    EXEC('
      create function dbo.InlineTableValuedFunction()
      returns table
      as
      return (
        SELECT col1 = ''Original InlineTableValuedFunction was executed'' 
      );'
    );

    EXEC tSQLt.FakeFunction 'dbo.InlineTableValuedFunction';

    DECLARE @actual as nvarchar(max)
    
    SELECT @actual = f.col1 FROM dbo.InlineTableValuedFunction() f
    EXEC tSQLt.AssertEqualsString null, @actual

END;
GO
CREATE PROC SpyFunctionTests.[test SpyFunction should allow tester to not execute behavior of multistatement table-valued function]
AS
BEGIN

    EXEC('
      create function dbo.MultistatementTableValuedFunction()
      returns @table TABLE (col1 nvarchar(max) )
      as
      BEGIN
        INSERT @table(col1) SELECT ''Original MultistatementTableValuedFunction was executed''
        RETURN
      END;'
    );

    EXEC tSQLt.FakeFunction 'dbo.MultistatementTableValuedFunction';

    DECLARE @actual as nvarchar(max)
    
    SELECT @actual = f.col1 FROM dbo.MultistatementTableValuedFunction() f
    EXEC tSQLt.AssertEqualsString null, @actual

END;
GO
/*
CREATE PROC SpyFunctionTests.[test SpyFunction should allow tester to not execute behavior of procedure with a parameter]
AS
BEGIN

    EXEC('CREATE PROC dbo.InnerProcedure @P1 VARCHAR(MAX) AS EXEC tSQLt.Fail ''InnerProcedure was executed '',@P1;');

    EXEC tSQLt.SpyFunction 'dbo.InnerProcedure';

    EXEC dbo.InnerProcedure 'with a parameter';

END;
GO

CREATE PROC SpyFunctionTests.[test SpyFunction should allow tester to not execute behavior of procedure with multiple parameters]
AS
BEGIN

    EXEC('CREATE PROC dbo.InnerProcedure @P1 VARCHAR(MAX), @P2 VARCHAR(MAX), @P3 VARCHAR(MAX) ' +
         'AS EXEC tSQLt.Fail ''InnerProcedure was executed '',@P1,@P2,@P3;');

    EXEC tSQLt.SpyFunction 'dbo.InnerProcedure';

    EXEC dbo.InnerProcedure 'with', 'multiple', 'parameters';

END;
GO

CREATE PROC SpyFunctionTests.[test SpyFunction should log calls]
AS
BEGIN

    EXEC('CREATE PROC dbo.InnerProcedure @P1 VARCHAR(MAX), @P2 VARCHAR(MAX), @P3 VARCHAR(MAX) ' +
         'AS EXEC tSQLt.Fail ''InnerProcedure was executed '',@P1,@P2,@P3;');

    EXEC tSQLt.SpyFunction 'dbo.InnerProcedure';

    EXEC dbo.InnerProcedure 'with', 'multiple', 'parameters';

    IF NOT EXISTS(SELECT 1 FROM dbo.InnerProcedure_SpyFunctionLog)
    BEGIN
        EXEC tSQLt.Fail 'InnerProcedure call was not logged!';
    END;

END;
GO

CREATE PROC SpyFunctionTests.[test SpyFunction should log calls with varchar parameters]
AS
BEGIN

    EXEC('CREATE PROC dbo.InnerProcedure @P1 VARCHAR(MAX), @P2 VARCHAR(10), @P3 VARCHAR(8000) ' +
         'AS EXEC tSQLt.Fail ''InnerProcedure was executed '',@P1,@P2,@P3;');

    EXEC tSQLt.SpyFunction 'dbo.InnerProcedure';

    EXEC dbo.InnerProcedure 'with', 'multiple', 'parameters';


    IF NOT EXISTS(SELECT 1
                   FROM dbo.InnerProcedure_SpyFunctionLog
                  WHERE P1 = 'with'
                    AND P2 = 'multiple'
                    AND P3 = 'parameters')
    BEGIN
        EXEC tSQLt.Fail 'InnerProcedure call was not logged correctly!';
    END;

END;
GO

CREATE PROC SpyFunctionTests.[test SpyFunction should allow NULL values for sysname parms]
AS
BEGIN
  EXEC('CREATE PROC dbo.InnerProcedure @P1 sysname ' +
       'AS EXEC tSQLt.Fail ''InnerProcedure was executed '',@P1;');

  EXEC tSQLt.SpyFunction 'dbo.InnerProcedure';

  EXEC dbo.InnerProcedure NULL;

  SELECT P1
    INTO #Actual
    FROM dbo.InnerProcedure_SpyFunctionLog;

  SELECT TOP(0) *
    INTO #Expected
    FROM #Actual;

  INSERT INTO #Expected(P1) VALUES(NULL);
  
  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO

CREATE PROC SpyFunctionTests.[test SpyFunction should allow NULL values for user defined types created as not nullable]
AS
BEGIN
  EXEC ('CREATE TYPE SpyFunctionTests.MyType FROM INT NOT NULL;');
  
  EXEC('CREATE PROC dbo.InnerProcedure @P1 SpyFunctionTests.MyType ' +
       'AS EXEC tSQLt.Fail ''InnerProcedure was executed '',@P1;');

  EXEC tSQLt.SpyFunction 'dbo.InnerProcedure';

  EXEC dbo.InnerProcedure NULL;

  SELECT P1
    INTO #Actual
    FROM dbo.InnerProcedure_SpyFunctionLog;

  SELECT TOP(0) *
    INTO #Expected
    FROM #Actual;

  INSERT INTO #Expected(P1) VALUES(NULL);
  
  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO

CREATE PROC SpyFunctionTests.[test SpyFunction should log call when output parameters are present]
AS
BEGIN
    EXEC('CREATE PROC dbo.InnerProcedure @P1 VARCHAR(100) OUT AS EXEC tSQLt.Fail ''InnerProcedure was executed;''');
    
    EXEC tSQLt.SpyFunction 'dbo.InnerProcedure';
    
    DECLARE @ActualOutputValue VARCHAR(100);
    
    EXEC dbo.InnerProcedure @P1 = @ActualOutputValue OUT;
    
    IF NOT EXISTS(SELECT 1
                    FROM dbo.InnerProcedure_SpyFunctionLog
                   WHERE P1 IS NULL)
    BEGIN
        EXEC tSQLt.Fail 'InnerProcedure call was not logged correctly!';
    END
END;
GO

CREATE PROC SpyFunctionTests.[test SpyFunction should log values of output parameters if input was provided for them]
AS
BEGIN
    EXEC('CREATE PROC dbo.InnerProcedure @P1 VARCHAR(100) OUT AS EXEC tSQLt.Fail ''InnerProcedure was executed;''');
    
    EXEC tSQLt.SpyFunction 'dbo.InnerProcedure';
    
    DECLARE @ActualOutputValue VARCHAR(100);
    SET @ActualOutputValue = 'HELLO';
    
    EXEC dbo.InnerProcedure @P1 = @ActualOutputValue OUT;
    
    IF NOT EXISTS(SELECT 1
                    FROM dbo.InnerProcedure_SpyFunctionLog
                   WHERE P1 = 'HELLO')
    BEGIN
        EXEC tSQLt.Fail 'InnerProcedure call was not logged correctly!';
    END
END;
GO

CREATE PROC SpyFunctionTests.[test SpyFunction should log values if a mix of input an output parameters are provided]
AS
BEGIN
    EXEC('CREATE PROC dbo.InnerProcedure @P1 VARCHAR(100) OUT, @P2 INT, @P3 BIT OUT AS EXEC tSQLt.Fail ''InnerProcedure was executed;''');
    
    EXEC tSQLt.SpyFunction 'dbo.InnerProcedure';
    
    EXEC dbo.InnerProcedure @P1 = 'PARAM1', @P2 = 2, @P3 = 0;
    
    IF NOT EXISTS(SELECT 1
                    FROM dbo.InnerProcedure_SpyFunctionLog
                   WHERE P1 = 'PARAM1'
                     AND P2 = 2
                     AND P3 = 0)
    BEGIN
        EXEC tSQLt.Fail 'InnerProcedure call was not logged correctly!';
    END
END;
GO

CREATE PROC SpyFunctionTests.[test SpyFunction should not log the default values of parameters if no value is provided]
AS
BEGIN
    EXEC('CREATE PROC dbo.InnerProcedure @P1 VARCHAR(100) = ''MY DEFAULT'' AS EXEC tSQLt.Fail ''InnerProcedure was executed;''');
    
    EXEC tSQLt.SpyFunction 'dbo.InnerProcedure';
    
    EXEC dbo.InnerProcedure;
    
    IF NOT EXISTS(SELECT 1
                    FROM dbo.InnerProcedure_SpyFunctionLog
                   WHERE P1 IS NULL)
    BEGIN
        EXEC tSQLt.Fail 'InnerProcedure call was not logged correctly!';
    END
END;
GO

CREATE PROC SpyFunctionTests.[test SpyFunction can be given a command to execute]
AS
BEGIN
    EXEC ('CREATE PROC dbo.InnerProcedure AS EXEC tSQLt.Fail ''InnerProcedure was executed'';');
    
    EXEC tSQLt.SpyFunction 'dbo.InnerProcedure', 'RETURN 1';
    
    DECLARE @ReturnVal INT;
    EXEC @ReturnVal = dbo.InnerProcedure;
    
    IF NOT EXISTS(SELECT 1 FROM dbo.InnerProcedure_SpyFunctionLog)
    BEGIN
        EXEC tSQLt.Fail 'InnerProcedure call was not logged!';
    END;
    
    EXEC tSQLt.AssertEquals 1, @ReturnVal;
END;
GO

CREATE PROC SpyFunctionTests.[test command given to SpyFunction can be used to set output parameters]
AS
BEGIN
    EXEC('CREATE PROC dbo.InnerProcedure @P1 VARCHAR(100) OUT AS EXEC tSQLt.Fail ''InnerProcedure was executed;''');
    
    EXEC tSQLt.SpyFunction 'dbo.InnerProcedure', 'SET @P1 = ''HELLO'';';
    
    DECLARE @ActualOutputValue VARCHAR(100);
    
    EXEC dbo.InnerProcedure @P1 = @ActualOutputValue OUT;
    
    EXEC tSQLt.AssertEqualsString 'HELLO', @ActualOutputValue;
    
    IF NOT EXISTS(SELECT 1
                    FROM dbo.InnerProcedure_SpyFunctionLog
                   WHERE P1 IS NULL)
    BEGIN
        EXEC tSQLt.Fail 'InnerProcedure call was not logged correctly!';
    END
END;
GO

CREATE PROC SpyFunctionTests.[test SpyFunction can have a cursor output parameter]
AS
BEGIN
    EXEC('CREATE PROC dbo.InnerProcedure @P1 CURSOR VARYING OUTPUT AS EXEC tSQLt.Fail ''InnerProcedure was executed;''');

    EXEC tSQLt.SpyFunction 'dbo.InnerProcedure';
    
    DECLARE @OutputCursor CURSOR;
    EXEC dbo.InnerProcedure @P1 = @OutputCursor OUTPUT; 
    
    IF NOT EXISTS(SELECT 1
                    FROM dbo.InnerProcedure_SpyFunctionLog)
    BEGIN
        EXEC tSQLt.Fail 'InnerProcedure call was not logged correctly!';
    END
END;
GO

CREATE PROC SpyFunctionTests.[test SpyFunction raises appropriate error if the procedure does not exist]
AS
BEGIN
    DECLARE @Msg NVARCHAR(MAX); SET @Msg = 'no error';
    
    BEGIN TRY
      EXEC tSQLt.SpyFunction 'SpyFunctionTests.DoesNotExist';
    END TRY
    BEGIN CATCH
        SET @Msg = ERROR_MESSAGE();
    END CATCH

    IF @Msg NOT LIKE '%Cannot use SpyFunction on %DoesNotExist% because the procedure does not exist%'
    BEGIN
        EXEC tSQLt.Fail 'Expected SpyFunction to throw a meaningful error, but message was: ', @Msg;
    END
END;
GO

CREATE PROC SpyFunctionTests.[test SpyFunction raises appropriate error if the procedure name given references another type of object]
AS
BEGIN
    DECLARE @Msg NVARCHAR(MAX); SET @Msg = 'no error';
    
    BEGIN TRY
      CREATE TABLE SpyFunctionTests.dummy (i int);
      EXEC tSQLt.SpyFunction 'SpyFunctionTests.dummy';
    END TRY
    BEGIN CATCH
        SET @Msg = ERROR_MESSAGE();
    END CATCH

    IF @Msg NOT LIKE '%Cannot use SpyFunction on %dummy% because the procedure does not exist%'
    BEGIN
        EXEC tSQLt.Fail 'Expected SpyFunction to throw a meaningful error, but message was: ', @Msg;
    END
END;
GO

CREATE PROC SpyFunctionTests.[test SpyFunction handles procedure names with spaces]
AS
BEGIN
    DECLARE @ErrorRaised INT; SET @ErrorRaised = 0;

    EXEC('CREATE PROC SpyFunctionTests.[Spyee Proc] AS RETURN 0;');

    EXEC tSQLt.SpyFunction 'SpyFunctionTests.[Spyee Proc]';
    
    EXEC SpyFunctionTests.[Spyee Proc];
    
    SELECT *
      INTO #Actual
      FROM SpyFunctionTests.[Spyee Proc_SpyFunctionLog];
    
    SELECT 1 _id_
      INTO #Expected
     WHERE 0=1;

    INSERT #Expected
    SELECT 1;
    
    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROC SpyFunctionTests.[test SpyFunction calls tSQLt.Private_RenameObjectToUniqueName on original proc]
AS
BEGIN
    DECLARE @ErrorRaised NVARCHAR(MAX); SET @ErrorRaised = 'No Error Raised';
    
    EXEC('CREATE PROC SpyFunctionTests.SpyeeProc AS RETURN 0;');

    EXEC tSQLt.SpyFunction 'tSQLt.Private_RenameObjectToUniqueName','RAISERROR(''Intentional Error'', 16, 10)';
    
    BEGIN TRY
        EXEC tSQLt.SpyFunction  'SpyFunctionTests.SpyeeProc';
    END TRY
    BEGIN CATCH
        SET @ErrorRaised = ERROR_MESSAGE();
    END CATCH
    
    EXEC tSQLt.AssertEqualsString 'Intentional Error', @ErrorRaised;
END;
GO
*/

EXEC tSQLt.Run 'SpyFunctionTests'