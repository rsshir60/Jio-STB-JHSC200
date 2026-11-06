# Probe subnets for ADB devices on port 5555
param(
    [string[]]$Subnets = @("192.168.137", "10.184.160")
)

foreach ($subnet in $Subnets) {
    Write-Host "Scanning subnet ${subnet}.0/24..." -ForegroundColor Cyan
    $tasks = @()
    for ($i = 1; $i -le 254; $i++) {
        $ip = "$subnet.$i"
        $tasks += [PSCustomObject]@{
            IP = $ip
            PingTask = (New-Object System.Net.NetworkInformation.Ping).SendPingAsync($ip, 300)
        }
    }
    
    foreach ($t in $tasks) {
        try {
            $res = $t.PingTask.Result
            if ($res.Status -eq [System.Net.NetworkInformation.IPStatus]::Success) {
                Write-Host "Host alive: $($t.IP)" -ForegroundColor Green
                # Check port 5555
                $tcp = New-Object System.Net.Sockets.TcpClient
                $connect = $tcp.BeginConnect($t.IP, 5555, $null, $null)
                $success = $connect.AsyncWaitHandle.WaitOne(400, $false)
                if ($success -and $tcp.Connected) {
                    Write-Host "  -> Port 5555 OPEN on $($t.IP)!" -ForegroundColor Yellow
                    $tcp.EndConnect($connect)
                    $tcp.Close()
                } else {
                    $tcp.Close()
                }
            }
        } catch {}
    }
}
