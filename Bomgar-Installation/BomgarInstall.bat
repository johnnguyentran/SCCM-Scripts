IF EXIST C:\Temp\BomgarInstall.txt del C:\Temp\BomgarInstall.txt

:Step1
IF EXIST C:\ProgramData\bomgar* GOTO Service
GOTO x64

:Service
sc query | findstr bomgar
IF NOT %ERRORLEVEL% EQU 0 GOTO x64
EXIT 0

:x64
for /d %%G in ("c:\programdata\bomgar*") do rd /s /q "%%~G"
c:\windows\system32\xcopy.exe \\networkdirectory\bomgar\bomgar-scc-win64.msi c:\windows\temp /Y
c:\windows\system32\msiexec.exe /i c:\windows\temp\bomgar-scc-win64.msi KEY_INFO=keyinformationgoeshere /qn
TIMEOUT 30
GOTO LOOP
EXIT 0

:Loop
IF NOT EXIST c:\Temp MD c:\Temp
IF EXIST C:\Temp\BomgarInstall.txt EXIT
echo.The code loop has been initiated. >> c:\temp\BomgarInstall.txt
GOTO Step1
