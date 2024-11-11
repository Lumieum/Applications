mkdir %PROGRAMDATA%\RebootScript
copy Files\*.* %PROGRAMDATA%\RebootScript\
powershell.exe -ExecutionPolicy Bypass -File %PROGRAMDATA%\RebootScript\InitialSetup.ps1