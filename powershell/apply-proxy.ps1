﻿function Reload-InternetOptions
{
  $signature = @'
[DllImport("wininet.dll", SetLastError = true, CharSet=CharSet.Auto)]
public static extern bool InternetSetOption(IntPtr hInternet, int
dwOption, IntPtr lpBuffer, int dwBufferLength);
'@
  $interopHelper = Add-Type -MemberDefinition $signature -Name MyInteropHelper -PassThru

  $INTERNET_OPTION_SETTINGS_CHANGED = 39
  $INTERNET_OPTION_REFRESH = 37

  $result1 = $interopHelper::InternetSetOption(0, $INTERNET_OPTION_SETTINGS_CHANGED, 0, 0)
  $result2 = $interopHelper::InternetSetOption(0, $INTERNET_OPTION_REFRESH, 0, 0)

  $result1 -and $result2
}

netsh winhttp set proxy "$env:PROXY_URL"

Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings" -Name ProxyServer -Value "http://$env:PROXY_URL"
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings" -Name ProxyEnable -Value 1

Echo "Applying Proxy Settings"

Reload-InternetOptions

Echo "Completed Applying Proxy"
