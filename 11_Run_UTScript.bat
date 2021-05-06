ECHO ON

SET DB=%NEW_DBBUILD%--1
SET BIR=%NEW_BIRBUILD%--2

IF EXIST %CD%\Report_Gen\report.html (DEL /f %CurDir%\Report_Gen\report.html) ELSE (Echo Report Not Found)

CD UnitTestRunner

Call setup.bat

CD..

ROBOCOPY C:\Softwares_Required\07_UnitTestSoftware\utPLSQL-cli .\utPLSQL-cli /e /NP /NFL /IS /IT

Set PATH="C:\Program Files\Java\jre1.8.0_221\bin"

echo "PATH is:" %PATH%

start /wait cmd.exe /c utPLSQL-cli\bin\utplsql run bir_spmat/managerqa@//inmat101sp:1521/sdbft -D -c -f=ut_junit_reporter -o=junit_test_results.xml -f=ut_documentation_reporter -o=run.txt

ECHO %ERRORLEVEL%

SET JAVA_HOME=C:\Program Files\Java\jdk1.8.0_221

SET PATH=%JAVA_HOME%\bin;%PATH%

CD REPORT_GEN

JAVAC Xmltohtml.java

JAVA Xmltohtml

JAVAC GetFinalrepo.java

JAVA GetFinalrepo %DB% %BIR%

IF %ERRORLEVEL% EQU 1 EXIT 0
IF %ERRORLEVEL% EQU 1 EXIT 0
