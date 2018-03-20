pushd ..\Views
for %%f in (*.sql) do sqlcmd -S CSDW7U\MSSQL2008E -U sa -P MSSQL.2008E -d Nimble -i "%%f"
popd

pushd ..\Programmability\Functions\Scalar-valued Functions
for %%f in (*.sql) do sqlcmd -S CSDW7U\MSSQL2008E -U sa -P MSSQL.2008E -d Nimble -i "%%f"
popd

pushd ..\Programmability\Functions\Table-valued Functions
for %%f in (*.sql) do sqlcmd -S CSDW7U\MSSQL2008E -U sa -P MSSQL.2008E -d Nimble -i "%%f"
popd

pushd ..\Programmability\Stored Procedures
for %%f in (*.sql) do sqlcmd -S CSDW7U\MSSQL2008E -U sa -P MSSQL.2008E -d Nimble -i "%%f"
popd
