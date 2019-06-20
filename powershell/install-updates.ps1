<#
.SYNOPSIS
This script will automatically install all avaialable windows updates on a device and will automatically reboot if needed, after reboot, windows updates will continue to run until no more updates are available.
.PARAMETER URL
User the Computer parameter to specify the Computer to remotely install windows updates on.
#>

[CmdletBinding()]

param (

[parameter(Mandatory=$true,Position=1)]

[string[]]$computer,

[parameter(Mandatory=$true,Position=2)]

[string[]]$username,

[parameter(Mandatory=$true,Position=3)]

[string[]]$password

)

$pass = $password | ConvertTo-SecureString -AsPlainText -Force
$creds = New-Object -TypeName System.Management.Automation.PSCredential $username,$pass

#install pswindows updates module


Do{

  #starts up a remote powershell session to the computer

  do{
    $session = New-PSSession -ComputerName $computer -Authentication Negotiate -Credential $creds
    "reconnecting remotely to $computer"
    sleep -seconds 10
  } until ($session.state -match "Opened")

  #retrieves a list of available updates

  "Checking for new updates available on $computer"

  $updates = invoke-command -session $session -scriptblock {
    Get-wulist -verbose
  }

  #counts how many updates are available

  $updatenumber = ($updates.kb).count

  #if there are available updates proceed with installing the updates and then reboot the remote machine

  if ($updates -ne $null){

    #remote command to install windows updates, creates a scheduled task on remote computer

    invoke-command -ComputerName $computer -ScriptBlock {
      C:\Software\wu-check-install.ps1
    } -Authentication Negotiate -Credential $creds

    #Show update status until the amount of installed updates equals the same as the amount of updates available

    sleep -Seconds 30

    do {
      $updatestatus = Get-Content \\$computer\c$\PSWindowsUpdate.log

      "Currently processing the following update:"

      Get-Content \\$computer\c$\PSWindowsUpdate.log | select-object -last 1

      sleep -Seconds 10

      $ErrorActionPreference = 'SilentlyContinue'

      $installednumber = ([regex]::Matches($updatestatus, "Installed" )).count

      $ErrorActionPreference = 'Continue'

    }until ( $installednumber -eq $updatenumber)

  }

}until($updates -eq $null)

#removes schedule task from computer

invoke-command -computername $computer -ScriptBlock {
  Unregister-ScheduledTask -TaskName PSWindowsUpdate -Confirm:$false
} -Authentication Negotiate -Credential $creds

"Windows is now up to date on $computer"
