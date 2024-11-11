# Credit: https://www.reddit.com/r/PowerShell/comments/bdj592/windows_toast_notification_with_reboot/

# Register the AppID in the registry for use with the Action Center, if required
$global:ScriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
$App =  "{1AC14E77-02E7-4E5D-B744-2EB1AE5198B7}\WindowsPowerShell\v1.0\powershell.exe"
# Logo and Hero Images used for the file

#Logo is the small, circular image
$LogoImage = "file:///$global:ScriptPath/logo.png"

# Hero is the large file at the top, it only shows about ~400x220px (rough estimate)
$HeroImage = "file:///$global:ScriptPath/hero.jpeg"

# These are the variables for the text shown on the toast notification. 
$NotificationTitle = "Reboot Needed"
$NotificationText = "Please reboot your PC to complete setup."
$CompanyName = "Your Company Name"
$CompanyAddress = "1234 Main St"
$CompanyAddressCont = "Fake City, KS, 12345"

#Toast Notification (Visual)
[xml]$Toast = @"
<toast scenario="$Scenario">

<visual>
    <binding template="ToastGeneric">
      <text>$NotificationTitle</text>
      <text>$NotificationText</text>
<text placement="attribution">$CompanyName</text>

<image placement="appLogoOverride" hint-crop="circle" src="$LogoImage"/>

<group>
 <subgroup>
  <text hint-style="captionSubtle" hint-align="right">$CompanyAddress</text>
  <text hint-style="captionSubtle" hint-align="right">$CompanyAddressCont</text>
 </subgroup>
</group>

<image placement="hero" src="$HeroImage"/>

    </binding>
  </visual>

  <actions>

        <action arguments = "rebootnow:"
                content = 'Reboot Now'
                activationType="protocol"
                 />
                
        <action arguments = 'rebootin15mins:'
                content = 'In 15 Mins'
                activationType="protocol"
                 />

        <action arguments = 'rebootin4hours:'
                content = 'In 4 Hours'
                activationType="protocol"
                 />
    </actions>
</toast>
"@

$Load = [Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime]
$Load = [Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom.XmlDocument, ContentType = WindowsRuntime]

# Load the notification into the required format
$ToastXml = New-Object -TypeName Windows.Data.Xml.Dom.XmlDocument
$ToastXml.LoadXml($Toast.OuterXml)
[Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier($App).Show($ToastXml)
break