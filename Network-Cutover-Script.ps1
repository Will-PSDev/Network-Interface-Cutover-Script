#declare parameters
param (
    [string]$adapterDisable = "Ethernet",
    [string]$ExpectedGateway = "10.0.0.1",
    [string]$Adapter = "Ethernet 2",
    [string]$newIP = "10.0.0.2",
    [int]$prefix = 24,
    [int]$index = 13,
    [string]$dns1 = "8.8.8.8",
    [string]$dns2 = "8.8.4.4"
)

#actual attempted network changes
Disable-NetAdapter -Name $adapterDisable -Confirm:$false
New-NetIPAddress -InterfaceIndex $index -IPAddress $newIP -PrefixLength $prefix -DefaultGateway $ExpectedGateway
Enable-NetAdapter -Name $Adapter
Set-DnsClientServerAddress -InterfaceAlias $Adapter -ServerAddresses ($dns1, $dns2)

#I've learned windows is sometimes stubborn with taking the gateway address, this  is some code to validate the gateway and attempt to re-apply the gateway settings if lost. I plan to clean this up in future versions
try {
    $Gateway = (Get-NetIPConfiguration -InterfaceAlias $Adapter -ErrorAction Stop).IPv4DefaultGateway.NextHop

    if ($Gateway -eq $ExpectedGateway) {
        Write-Host "Gateway matches."
    }
    elseif ($null -eq $Gateway) {
        Write-Host "Adapter exists but has no default gateway."
        Set-NetIPAddress -InterfaceIndex $index -IPAddress $newIP -PrefixLength $prefix -DefaultGateway $ExpectedGateway
    }
    else {
        Write-Host "Gateway is $Gateway (expected $ExpectedGateway)."
        Set-NetIPAddress -InterfaceIndex $index -IPAddress $newIP -PrefixLength $prefix -DefaultGateway $ExpectedGateway
    }
}
catch {
    Write-Host "Adapter '$Adapter' was not found."
    Set-NetIPAddress -InterfaceIndex $index -IPAddress $newIP -PrefixLength $prefix -DefaultGateway $ExpectedGateway
}
 