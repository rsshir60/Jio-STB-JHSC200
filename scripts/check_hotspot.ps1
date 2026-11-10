Add-Type -AssemblyName System.Runtime.WindowsRuntime
$p = [Windows.Networking.Connectivity.NetworkInformation, Windows.Networking.Connectivity, ContentType = WindowsRuntime]::GetInternetConnectionProfile()
$m = [Windows.Networking.NetworkOperators.NetworkOperatorTetheringManager, Windows.Networking.NetworkOperators, ContentType = WindowsRuntime]::CreateFromConnectionProfile($p)
Write-Output "Tethering state: $($m.TetheringOperationalState)"
Write-Output "Client count: $($m.ClientCount)"
$clients = $m.GetTetheringClients()
if ($clients) {
    foreach ($c in $clients) {
        Write-Output "MAC: $($c.MacAddress)"
        if ($c.HostNames) {
            foreach ($h in $c.HostNames) {
                Write-Output "  Host: $($h.CanonicalName)"
            }
        }
    }
}
