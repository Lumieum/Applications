# Cleans up any Scheduled Tasks created after a reboot

Get-ScheduledTask -TaskPath "\RebootScripts\" | Unregister-ScheduledTask -Confirm:$false