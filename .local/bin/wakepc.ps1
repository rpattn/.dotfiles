$ErrorActionPreference = "Stop"

$Url = "http://100.74.90.52:9000/hooks/wakepc"
$Token = $env:WAKE_TOKEN

if (-not $Token) {
    Write-Error "WAKE_TOKEN is not set."
    exit 1
}

try {
    Invoke-WebRequest `
        -Method Post `
        -Uri "${Url}?token=$Token" `
	-UseBasicParsing | Out-Null

    Write-Host "Wake request sent."

    ping 100.103.64.22
}
catch {
    Write-Error "Failed to contact wake service: $_"
    exit 1
}