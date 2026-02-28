param([string]$SessionName = "unknown")

$pidFile = "C:\Temp\claude-notify-$SessionName.pid"
if (Test-Path $pidFile) {
    $p = Get-Content $pidFile
    Stop-Process -Id $p -Force -ErrorAction SilentlyContinue
    Remove-Item $pidFile -Force -ErrorAction SilentlyContinue
}
