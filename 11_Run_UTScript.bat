ECHO ON

SET DB=%NEW_DBBUILD%--1
SET BIR=%NEW_BIRBUILD%--2

IF EXIST %CD%\report.html (DEL /f %CurDir%\report.html) ELSE (Echo Report Not Found)

Set /p Codedir = %CD%

echo %Codedir%

CD UnitTestRunner

Call setup.bat

CD /d C:\Softwares_Required\07_UnitTestSoftware

Set PATH="C:\Program Files\Java\jre1.8.0_221\bin"

echo "PATH is:" %PATH%

start /wait cmd.exe /c utPLSQL-cli\bin\utplsql run bir_spmat/managerqa//inmat101sp:1521/sdbft -D -c -f=ut_junit_reporter -o=junit_test_results.xml -f=ut_documentation_reporter -o=run.txt

ECHO %ERRORLEVEL%

SET JAVA_HOME=C:\Program Files\Java\jdk1.8.0_221

SET PATH=%JAVA_HOME%\bin;%PATH%

CD %Codedir%

CD REPORT_GEN

JAVAC Xmltohtml.java

JAVA Xmltohtml

JAVA GetFinalrepo %DB% %BIR%

IF %ERRORLEVEL% EQU 1 EXIT 0
IF %ERRORLEVEL% EQU 1 EXIT 0
