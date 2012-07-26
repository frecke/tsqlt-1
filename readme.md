
## What is tSQLt?
tSQLt is a database unit testing framework for Microsoft SQL Server. tSQLt is compatible with SQL Server 2005 (service pack 2 required) and above on all editions.

Find out more at the official website for [tSQLt](http://tsqlt.org/).

### Main Features 
tSQLt allows you to implement unit tests in T-SQL. This is important as you do not have to switch between various tools to create your code and your unit tests. tSQLt also provides the following features to make it easier to create and manage unit tests:

* Tests are automatically run within transactions – this keeps tests independent and reduces any cleanup work you need
* Tests can be grouped together within a schema – allowing you to organize your tests and use common setup methods
* Output can be generated in plain text or XML – making it easier to integrate with a continuous integration tool
* Provides the ability to fake tables and views, and to create stored procedure spies – allowing you to isolate the code which you are testing

### NO AFFILIATION WITH TSQLT.ORG
This is my personal fork of the tSQLt project used for making experimental changes. This is not a way to contibute officially to the tSQLt project. Feel free to fork this project, and I will entertain pull requests for this copy of the repo, but don't expect these changes to show up in future tSQLt projects. I have no affiliation with the project other than an interested user and hacker. 

#### So Why This Repo?
The tSQLt project uses SVN for source control, and I personally like to use Git for my local source control and use git-svn for SNV repo integration. If these changes prove useful, I will attempt to contribute them back to the official [tSQLt repository](http://sourceforge.net/projects/tsqlt/)