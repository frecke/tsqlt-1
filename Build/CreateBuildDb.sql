GO
IF DB_ID('$(DbName)') IS NOT NULL 
BEGIN
  ALTER DATABASE $(DbName) SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
  DROP DATABASE $(DbName);
END
GO
EXECUTE AS LOGIN = 'SA';
GO
CREATE DATABASE $(DbName) COLLATE SQL_Latin1_General_CP1_CS_AS WITH TRUSTWORTHY ON;
-- COLLATE SQL_Latin1_General_CP1_CS_AS
GO
