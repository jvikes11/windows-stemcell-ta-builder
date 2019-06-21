Param (
    [Parameter(Mandatory=$true)][string]$proxy_url
)

Echo "Applying Proxy Settings"

$proxy_reg_string="F            " + $proxy_url + "                                        "

netsh winhttp set proxy $proxy_url

Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings" -Name ProxyServer -Value "http://$proxy_url"
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings" -Name ProxyEnable -Value 1
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings\Connections" -Name DefaultConnectionSettings -Value ([System.Text.Encoding]::UTF8.GetBytes($proxy_reg_string)) -Type Binary

Echo "Completed Applying Proxy"
