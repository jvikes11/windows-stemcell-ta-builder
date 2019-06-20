
$username = "$env:VM_IP\$env:VM_ADMIN_USERNAME"
$password = $env:VM_ADMIN_PASSWORD | ConvertTo-SecureString -AsPlainText -Force
$creds = New-Object -TypeName System.Management.Automation.PSCredential $username,$password

Invoke-Command -ComputerName $env:VM_IP -ScriptBlock {
  $cd = Get-WMIObject -Class Win32_CDROMDrive
  cd $cd.Drive
  .\setup64.exe /s /v “/qn reboot=r”
} -Authentication Negotiate -Credential $creds
