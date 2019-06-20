<#
.SYNOPSIS
This script will automatically install all avaialable windows updates on a device and will automatically reboot if needed, after reboot, windows updates will continue to run until no more updates are available.
.PARAMETER URL
User the Computer parameter to specify the Computer to remotely install windows updates on.
#>

[CmdletBinding()]

&C:\Software\apply-proxy.ps1
Start-sleep -seconds 10

#install pswindows updates module

Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force

install-module pswindowsupdate -force

Import-Module PSWindowsUpdate -force

Do{

  $updates = Get-wulist -verbose

  #counts how many updates are available

  $updatenumber = ($updates.kb).count

  #if there are available updates proceed with installing the updates and then reboot the remote machine

  if ($updates -ne $null){

    #remote command to install windows updates, creates a scheduled task on remote computer

    $Script = {
      import-module PSWindowsUpdate;
      Get-WindowsUpdate -AcceptAll -Install | Out-File C:\PSWindowsUpdate.log
    }

    Invoke-WUjob -ComputerName localhost -Script $Script -Confirm:$false -RunNow

    #Show update status until the amount of installed updates equals the same as the amount of updates available

    sleep -Seconds 30

    do {
      $updatestatus = Get-Content C:\PSWindowsUpdate.log

      "Currently processing the following update:"

      Get-Content C:\PSWindowsUpdate.log | select-object -last 1

      sleep -Seconds 10

      $ErrorActionPreference = 'SilentlyContinue'

      $installednumber = ([regex]::Matches($updatestatus, "Installed" )).count

      $ErrorActionPreference = 'Continue'

    }until ( $installednumber -eq $updatenumber)

    #restarts the remote computer and waits till it starts up again

    "restarting remote computer"

    Restart-Computer

  }

}until($updates -eq $null)
