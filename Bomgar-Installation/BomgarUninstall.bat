IF EXIST C:\Temp\BomgarInstall.txt del C:\Temp\BomgarInstall.txt
taskkill /im bomgar-scc.exe /f
@wmic service where "name like 'bomgar%%'" Call Delete
MsiExec.exe /X{B0216814-FD81-445B-9A4B-444FF45707BA} /q
for /d %%G in ("c:\programdata\bomgar*") do rd /s /q "%%~G"
EXIT 0
