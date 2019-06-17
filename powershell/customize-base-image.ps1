
$username = "$vm_ip\$vm_admin_username"
$password = $vm_admin_password | ConvertTo-SecureString -AsPlainText -Force
$creds = New-Object -TypeName System.Management.Automation.PSCredential $username,$password

Set-Item -Path WSMan:\localhost\Client\TrustedHosts "$vm_ip" -Force

Invoke-Command -ComputerName $vm_ip -ScriptBlock {
  New-Item -Path C:\Software -ItemType Directory;
} -Authentication Default -Credential $creds

Copy-Item pipeline/powershell/* '\\$vm_ip\C$\Software';

Invoke-Command -ComputerName $vm_ip -ScriptBlock {
    powershell C:\Software\configure-server.ps1;
    Invoke-WebRequest -Uri "$msi_download_url" -OutFile "C:\Software\.";
    msiexec.exe /i C:\Software\*.msi /passive;
    powershell C:\Software\apply-proxy.ps1;
} -Authentication Default -Credential $creds

powershell pipeline/powershell/install-updates.ps1 -computer $vm_ip

Invoke-Command -ComputerName $vm_ip -ScriptBlock {
  Set-Service -Name BESClient -StartupType Disabled -Status Stopped
} -Authentication Default -Credential $creds
