@ECHO OFF
start "DISK WRITER" cmd /k powershell.exe -file "%~dp0cs_diskwrite.ps1" -executionpolicy bypass 
start "QUEUE MANAGER" cmd /k powershell.exe -file "%~dp0cs_bitsqueue.ps1" -executionpolicy bypass 
start "DOWNLOAD SEEKER" cmd /k powershell.exe -file "%~dp0cs_syphon.ps1" -executionpolicy bypass 
