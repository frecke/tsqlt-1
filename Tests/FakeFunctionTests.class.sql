EXEC tSQLt.NewTestClass 'FakeFunctionTests';
GO
CREATE PROC FakeFunctionTests.[test FakeFunction should allow tester to not execute behavior of scalar function returning an int]
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
CREATE PROC FakeFunctionTests.[test FakeFunction should allow tester to not execute behavior of scalar function returning a string]
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

CREATE PROC FakeFunctionTests.[test FakeFunction should allow tester to not execute behavior of inline table-valued function]
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
CREATE PROC FakeFunctionTests.[test FakeFunction should allow tester to not execute behavior of multistatement table-valued function]
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

CREATE PROC FakeFunctionTests.[test FakeFunction should allow tester to not execute behavior of function with a parameter]
AS
BEGIN

     EXEC('
      create function dbo.InnerFunction(@P1 NVARCHAR(MAX))
      returns nvarchar(max)
      as
      begin
          return ''Original InnerFunction was executed'';
      end;
    ');
    
    EXEC tSQLt.FakeFunction 'dbo.InnerFunction';

    DECLARE @actual as int
    
    SELECT @actual = dbo.InnerFunction('test')
    
    EXEC tSQLt.AssertEquals null, @actual
END;
GO

CREATE PROC FakeFunctionTests.[test FakeFunction should allow tester to not execute behavior of function with multiple parameters]
AS
BEGIN

    EXEC('
      create function dbo.InnerFunction(@P1 VARCHAR(MAX), @P2 VARCHAR(MAX), @P3 VARCHAR(MAX) )
      returns nvarchar(max)
      as
      begin
          return ''Original InnerFunction was executed'';
      end;
    ');
    
    EXEC tSQLt.FakeFunction 'dbo.InnerFunction';

    DECLARE @actual as int
    
    SELECT @actual = dbo.InnerFunction('test','with','multiple')
    
    EXEC tSQLt.AssertEquals null, @actual
    
END;
GO

CREATE PROC FakeFunctionTests.[test FakeFunction should allow NULL values for sysname parms]
AS
BEGIN

  EXEC('
      create function dbo.InnerFunction(@p1 sysname)
      returns nvarchar(max)
      as
      begin
          return ''Original InnerFunction was executed'';
      end;
    ');
    
  EXEC tSQLt.FakeFunction 'dbo.InnerFunction';
    

  DECLARE @actual as int
    
  SELECT @actual = dbo.InnerFunction(null)
    
  EXEC tSQLt.AssertEquals null, @actual

END;
GO

CREATE PROC FakeFunctionTests.[test FakeFunction should allow NULL values for user defined types created as not nullable]
AS
BEGIN
  EXEC ('CREATE TYPE FakeFunctionTests.MyType FROM INT NOT NULL;');
  
  
  EXEC('
      create function dbo.InnerFunction(@p1 FakeFunctionTests.MyType)
      returns nvarchar(max)
      as
      begin
          return ''Original InnerFunction was executed'';
      end;
    ');
    
  EXEC tSQLt.FakeFunction 'dbo.InnerFunction';
    

  DECLARE @actual as int
    
  SELECT @actual = dbo.InnerFunction(null)
    
  EXEC tSQLt.AssertEquals null, @actual
  
END;
GO

CREATE PROC FakeFunctionTests.[test FakeFunction can be given a return value to execute for scalar valued function]
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
    
    EXEC tSQLt.FakeFunction 'dbo.InnerFunction', 'RETURN ''Faked return value'' ';

    DECLARE @actual as nvarchar(max)
    
    SELECT @actual = dbo.InnerFunction()
    
    EXEC tSQLt.AssertEqualsString 'Faked return value', @actual
END;
GO
CREATE PROC FakeFunctionTests.[test FakeFunction can be given a statement to execute for table valued function]
AS
BEGIN
    EXEC('
      create function dbo.InnerFunction()
      returns @table table (col1 nvarchar(max), col2 int)
      as
      begin
          insert into @table values (''test val'', 500)
          return
      end;
    ');
    
    EXEC tSQLt.FakeFunction 'dbo.InnerFunction', 'SELECT col1=''faked val'', col2=100';

    SELECT * INTO actual FROM dbo.InnerFunction()
    
    SELECT col1='faked val', col2=100 INTO expected
    
    EXEC tSQLt.AssertEqualsTable 'expected', 'actual'
END;
GO

CREATE PROC FakeFunctionTests.[test FakeFunction raises appropriate error if the function does not exist]
AS
BEGIN
    DECLARE @Msg NVARCHAR(MAX); SET @Msg = 'no error';
    
    BEGIN TRY
      EXEC tSQLt.FakeFunction 'FakeFunctionTests.DoesNotExist';
    END TRY
    BEGIN CATCH
        SET @Msg = ERROR_MESSAGE();
    END CATCH

    IF @Msg NOT LIKE '%Cannot use FakeFunction on %DoesNotExist% because the function does not exist%'
    BEGIN
        EXEC tSQLt.Fail 'Expected FakeFunction to throw a meaningful error, but message was: ', @Msg;
    END
END;
GO

CREATE PROC FakeFunctionTests.[test FakeFunction raises appropriate error if the function name given references another type of object]
AS
BEGIN
    DECLARE @Msg NVARCHAR(MAX); SET @Msg = 'no error';
    
    BEGIN TRY
      CREATE TABLE FakeFunctionTests.dummy (i int);
      EXEC tSQLt.FakeFunction 'FakeFunctionTests.dummy';
    END TRY
    BEGIN CATCH
        SET @Msg = ERROR_MESSAGE();
    END CATCH

    IF @Msg NOT LIKE '%Cannot use FakeFunction on %dummy% because the function does not exist%'
    BEGIN
        EXEC tSQLt.Fail 'Expected FakeFunction to throw a meaningful error, but message was: ', @Msg;
    END
END;
GO

CREATE PROC FakeFunctionTests.[test FakeFunction handles function names with spaces]
AS
BEGIN
    DECLARE @ErrorRaised INT; SET @ErrorRaised = 0;

    EXEC('
      create function dbo.[Inner Function]()
      returns nvarchar(max)
      as
      begin
          return ''Original InnerFunction was executed'';
      end;
    ');

    EXEC tSQLt.FakeFunction 'dbo.[Inner Function]';
    
    DECLARE @actual nvarchar(max)
    SELECT @actual = dbo.[Inner Function]();
         
    EXEC tSQLt.AssertEqualsString null, @actual;
END;
GO

CREATE PROC FakeFunctionTests.[test FakeFunction calls tSQLt.Private_RenameObjectToUniqueName on original proc]
AS
BEGIN
    DECLARE @ErrorRaised NVARCHAR(MAX); SET @ErrorRaised = 'No Error Raised';
    
    EXEC('
      create function dbo.InnerFunction()
      returns nvarchar(max)
      as
      begin
          return ''Original InnerFunction was executed'';
      end;
    ');

    EXEC tSQLt.SpyProcedure 'tSQLt.Private_RenameObjectToUniqueName','RAISERROR(''Intentional Error'', 16, 10)';
    
    BEGIN TRY
        EXEC tSQLt.FakeFunction  'dbo.InnerFunction';
    END TRY
    BEGIN CATCH
        SET @ErrorRaised = ERROR_MESSAGE();
    END CATCH
    
    EXEC tSQLt.AssertEqualsString 'Intentional Error', @ErrorRaised;
END;
GO

--EXEC tSQLt.Run 'FakeFunctionTests'