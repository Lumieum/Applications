<# 
# Credit: https://www.reddit.com/r/PowerShell/comments/bdj592/windows_toast_notification_with_reboot/
    This will be super basic - this is the script that is called after the win32 app is ran. 
    The win32 app is "ran" (it runs a batch file) that copies files into %PROGRAMDATA%\RebootScript
    It then calls powershell.exe -ExecutionPolicy Bypass -File %PROGRAMDATA%\RebootScript\InitialSetup.ps1 

    The purpose of this file is simple - this is the logic where it does the following: 
        1. What do I want to do? Do I want to force a reboot / spam the user with notifications? 
        2. How do I want to enforce this? 
        3. Once I know this - I will create scheduled tasks, and then tell these to call further PS scripts. 

    Example (given in this file): 

    InstallDate = 06/13/2020, 1:35pm
    LastBootTime = 06/13/2020, 1:34pm

    If this is the case - the PC hasn't been rebooted. 

    If the LastBootTime is MORE than 2 hours after the InstallDate, then we simply exit (no reboot is necessary)
    If it's LESS than 2 hours, (or BEFORE the InstallDate), then we create a scheduled task to tell the user to reboot. 



    FOR TESTING: 
    At the bottom, there is an IF loop. 
        I have this IF loop currently calling "SetupDevice" (the function that actually RUNS the setup)
        It is declared in BOTH scenarios. AKA - No matter what - it runs. 

    IDEALLY, this "IF" would have some way of determining IF we need to run SetupDevice. 
    IF not, then it should simply "return" - without making any changes to the system. 

    Example: 
            if (($BootTimeDifference.Days -le "1") -and ($BootTimeDifference.Hours -le "2")) {
                SetupDevice
            } else {
                return
            }
    
    FOR NOW THOUGH - It's set to run SetupDevice in both conditions. 
#>

$global:ScriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition

#   Declare a variable for OSDates to determine the LastBootUpTime and InstallDate. These can be polled individually with $OSDates.InstallDate or $OSDates.LastBootUpTime
$OSDates = Get-CimInstance -ClassName win32_operatingsystem | Select-Object LastBootUpTime,InstallDate

function SetupDevice {
        <#
            Create all of the registry keys & files, etc
            This runs in the Administrator's context (under Administrative setup)
        #>

        New-PSDrive -Name HKCR -PSProvider Registry -Root HKEY_CLASSES_ROOT | Out-Null
    $RegPath = "HKCR:\rebootnow\"
    $RegistryBatchPath = (Get-ItemProperty "$RegPath\shell\open\command" -Name "(Default)")."(Default)"
    if (! ($RegistryBatchPath -eq "$global:ScriptPath\rebootnow.bat")) { 
        New-Item -Path "$RegPath" -Force
        New-ItemProperty -Path "$RegPath" -Name "(Default)" -Value "URL:Reboot Protocol" -PropertyType "String"
        New-ItemProperty -Path "$RegPath" -Name "URL Protocol" -Value "" -PropertyType "String"
        New-Item -Path "$RegPath\shell\open\command" -Force
        New-ItemProperty -Path "$RegPath\shell\open\command" -Name "(Default)" -Value $global:ScriptPath\rebootnow.bat -PropertyType "String"
    } 

    $RegPath = "HKCR:\rebootin15mins\"
    $RegistryBatchPath = (Get-ItemProperty "$RegPath\shell\open\command" -Name "(Default)")."(Default)"
    if (! ($RegistryBatchPath -eq "$global:ScriptPath\rebootin15m.bat")) { 
        New-Item -Path "$RegPath" -Force
        New-ItemProperty -Path "$RegPath" -Name "(Default)" -Value "URL:Reboot Protocol" -PropertyType "String"
        New-ItemProperty -Path "$RegPath" -Name "URL Protocol" -Value "" -PropertyType "String"
        New-Item -Path "$RegPath\shell\open\command" -Force
        New-ItemProperty -Path "$RegPath\shell\open\command" -Name "(Default)" -Value $global:ScriptPath\rebootin15m.bat -PropertyType "String"
    }

    $RegPath = "HKCR:\rebootin4hours\"
    $RegistryBatchPath = (Get-ItemProperty "$RegPath\shell\open\command" -Name "(Default)")."(Default)"
    if (! ($RegistryBatchPath -eq "$global:ScriptPath\rebootin4h.bat")) {
        New-Item -Path "$RegPath" -Force
        New-ItemProperty -Path "$RegPath" -Name "(Default)" -Value "URL:Reboot Protocol" -PropertyType "String"
        New-ItemProperty -Path "$RegPath" -Name "URL Protocol" -Value "" -PropertyType "String"
        New-Item -Path "$RegPath\shell\open\command" -Force
        New-ItemProperty -Path "$RegPath\shell\open\command" -Name "(Default)" -Value $global:ScriptPath\rebootin4h.bat -PropertyType "String"
    }

    #   Create reboot batch files if they don't exist
    if (! (Test-Path $global:ScriptPath\rebootnow.bat)) {  
        Set-Content -Path $global:ScriptPath\rebootnow.bat -Value "shutdown /g /t 60" -Encoding ASCII
    }
    if (! (Test-Path $global:ScriptPath\rebootin15m.bat)) {  
        Set-Content -Path $global:ScriptPath\rebootin15m.bat -Value "shutdown /g /t 900" -Encoding ASCII
    }
    if (! (Test-Path $global:ScriptPath\rebootin4h.bat)) {  
        Set-Content -Path $global:ScriptPath\rebootin4h.bat -Value "shutdown /g /t 14400" -Encoding ASCII
    }

    <# 
        Check for required entries in registry for when using Powershell as application for the toast
        Register the AppID in the registry for use with the Action Center, if required
    #>
    $RegPath = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Notifications\Settings"
    $App =  "{1AC14E77-02E7-4E5D-B744-2EB1AE5198B7}\WindowsPowerShell\v1.0\powershell.exe"
        
    #   Creating registry entries if they don't exists
    if (-NOT(Test-Path -Path "$RegPath\$App")) {
        New-Item -Path "$RegPath\$App" -Force
        New-ItemProperty -Path "$RegPath\$App" -Name "ShowInActionCenter" -Value 1 -PropertyType "DWORD"
    }
        
    #   Make sure the app used with the action center is enabled
    if ((Get-ItemProperty -Path "$RegPath\$App" -Name "ShowInActionCenter").ShowInActionCenter -ne "1")  {
        New-ItemProperty -Path "$RegPath\$App" -Name "ShowInActionCenter" -Value 1 -PropertyType "DWORD" -Force
    }


    <# 
        The name of the PS script that actually begins issueing the toast notifications. 
        Referenced via $global:ScriptPath\$RebootScriptName 
    #>
    $RebootScriptName = "RebootNotifications.ps1"

    # Create scheduled task

    $TaskName = "Initial Setup Reboot"
    # The description of the task
    $TaskDescr = "If the user hasn't rebooted, since their initial setup, prompt to reboot. "
    # The Task Action command
    $TaskCommand = "powershell.exe"
    # The PowerShell script to be executed
    $TaskScript = "$global:ScriptPath\$RebootScriptName"
    # The Task Action command argument
    $TaskArg = "-WindowStyle Hidden -NonInteractive -Executionpolicy unrestricted -file $TaskScript"
    
    # The time when the task starts, for demonstration purposes we run it 1 minute after we created the task
    $TaskStartTime = (Get-Date).AddSeconds(10)
    $TaskDuration = (New-TimeSpan -Days 31)
    $TaskRepetitionInterval = (New-TimeSpan -Hours 1)

    $TaskAction = New-ScheduledTaskAction -Execute $TaskCommand -Argument $TaskArg
    $TaskTrigger = New-ScheduledTaskTrigger -Once -At $TaskStartTime -RepetitionDuration $TaskDuration -RepetitionInterval $TaskRepetitionInterval
    $STPrin = New-ScheduledTaskPrincipal -GroupId "BUILTIN\Users" -RunLevel Limited
    Register-ScheduledTask -Action $TaskAction -Trigger $Tasktrigger -TaskName "$TaskName" -Description $TaskDescr -TaskPath "RebootScripts" -Principal $STPrin

    # Create cleanup Scheduled task (This will be triggered at the next machine startup)
    # This is necessary because it needs to run at the next startup, and delete the above scheduled task. 

    $CleanupScriptName = "cleanup.ps1"
    $TaskName = "Cleanup Tasks on Reboot"
    # The description of the task
    $TaskDescr = "Ensures scheduled tasks to prompt users to reboot do NOT persist after a reboot."
    # The Task Action command
    $TaskCommand = "powershell.exe"
    # The PowerShell script to be executed
    $TaskScript = "$global:ScriptPath\$CleanupScriptName"
    # The Task Action command argument
    $TaskArg = "-WindowStyle Hidden -NonInteractive -Executionpolicy unrestricted -file $TaskScript"

    
    # The time when the task starts, for demonstration purposes we run it 1 minute after we created the task
    $TaskStartTime = (Get-Date).AddSeconds(10)
    $TaskDuration = (New-TimeSpan -Days 31)
    $TaskRepetitionInterval = (New-TimeSpan -Hours 1)

    $TaskAction = New-ScheduledTaskAction -Execute $TaskCommand -Argument "$TaskArg"
    $TaskTrigger = New-ScheduledTaskTrigger -AtStartup
    $STPrin = New-ScheduledTaskPrincipal -UserId "SYSTEM" -RunLevel Highest -LogonType ServiceAccount
    Register-ScheduledTask -Action $TaskAction -Trigger $Tasktrigger -TaskName "$TaskName" -Description $TaskDescr -TaskPath "RebootScripts" -Principal $STPrin
}

#   Declares a variable that is the DIFFERENCE between these times
$BootTimeDifference = New-TimeSpan -Start $OSDates.InstallDate -End $OSDates.LastBootUpTime

if (($BootTimeDifference.Days -le "1") -and ($BootTimeDifference.Hours -le "2")) {
    SetupDevice
} else {
    SetupDevice
}