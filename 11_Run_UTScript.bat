ECHO ON
SET CurDir=C:\Utest

SET DB=%NEW_DBBUILD%
SET BIR=%NEW_BIRBUILD%

IF EXIST %CurDir%\report.html (DEL /f %CurDir%\report.html) ELSE (Echo Report Not Found)

CD %CurDir%\UT_Packages

Call UT_setup.bat

CD..

CD utPLSQL\source

SQLPLUS SYS/Manager1!@IQA101ASDB.WORLD as sysdba @install_headless.sql

CD..

CD..

Set PATH="C:\Program Files\Java\jre1.8.0_202\bin"

echo "PATH is:" %PATH%

start /wait cmd.exe /c utPLSQL-cli\bin\utplsql run bir_spmat/manager@//inmatapex1:1521/sdbft -D -c -f=ut_junit_reporter -o=junit_test_results.xml -f=ut_documentation_reporter -o=run.txt

ECHO %ERRORLEVEL%

SET JAVA_HOME=C:\Program Files\Java\jdk1.8.0_202

SET PATH=%JAVA_HOME%\bin;%PATH%

CD REPORT_GEN

JAVA Xmltohtml

JAVA GetFinalrepo %DB% %BIR%

IF %ERRORLEVEL% EQU 1 EXIT 0
IF %ERRORLEVEL% EQU 1 EXIT 0
