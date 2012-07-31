/*
   Copyright 2011 tSQLt

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.
*/

EXEC tSQLt.NewTestClass 'Private_RemoveObjectSchemaBinding';
GO

CREATE PROC Private_RemoveObjectSchemaBinding.[test Private_RemoveObjectSchemaBinding remove with schemabinding and allow referenced tables to be renamed]
AS
BEGIN

  DECLARE @ErrorRaised NVARCHAR(MAX); SET @ErrorRaised = 'No Error Raised';

  --ARRANGE:
  --  create a table and a view with schemabinding that depends on the table
  CREATE TABLE Private_RemoveObjectSchemaBinding.TempTable1(i INT);
  
  DECLARE @ViewCreate nvarchar(max)
  SET @ViewCreate = 'CREATE VIEW Private_RemoveObjectSchemaBinding.vTempTable1 with SCHEMABINDING as SELECT i FROM Private_RemoveObjectSchemaBinding.TempTable1'
  EXEC (@ViewCreate)
  
  --ACT:
  EXEC tSQLt.Private_RemoveObjectSchemaBinding 'Private_RemoveObjectSchemaBinding.vTempTable1';
  
  --ASSERT:
  BEGIN TRY
    --Rename will fail if view schemabinding still on.
    EXEC sp_rename 'Private_RemoveObjectSchemaBinding.TempTable1', 'Private_RemoveObjectSchemaBinding.TempTable1_new'
  END TRY
  BEGIN CATCH
    SET @ErrorRaised = ERROR_MESSAGE()
    EXEC tSQLt.Fail @ErrorRaised
  END CATCH 
END;
GO

--EXEC tSQLt.Run 'Private_RemoveObjectSchemaBinding'