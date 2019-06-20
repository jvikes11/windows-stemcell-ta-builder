
$username = "$env:VM_IP\$env:VM_ADMIN_USERNAME"
$password = $env:VM_ADMIN_PASSWORD | ConvertTo-SecureString -AsPlainText -Force
$creds = New-Object -TypeName System.Management.Automation.PSCredential $username,$password

Invoke-Command -ComputerName $env:VM_IP -ScriptBlock {
  New-Item -Path C:\Software -ItemType Directory;
} -Authentication Negotiate -Credential $creds

$session = New-PSSession -ComputerName $env:VM_IP -Authentication Negotiate -Credential $creds
Copy-Item -Path pipeline/powershell/* -Destination C:\Software -ToSession $session;

Invoke-Command -ComputerName $env:VM_IP -ArgumentList $env:MSI_DOWNLOAD_URL -ScriptBlock {
    param($msi_download_url);
    Invoke-WebRequest -Uri $msi_download_url -OutFile "C:\Software\install.msi";
    msiexec.exe /i C:\Software\install.msi /passive;
    Start-Sleep -Seconds 20;
} -Authentication Negotiate -Credential $creds

pipeline/powershell/install-updates.ps1 -Computer $env:VM_IP

Invoke-Command -ComputerName $env:VM_IP -ScriptBlock {
  Set-Service -Name BESClient -StartupType Disabled -Status Stopped
} -Authentication Negotiate -Credential $creds
