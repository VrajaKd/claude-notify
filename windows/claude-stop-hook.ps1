param([string]$SessionName = "unknown")
# Dismiss old popup
& 'C:\Temp\claude-dismiss.ps1' $SessionName
# Launch new popup as fully detached process, no console window
(New-Object Media.SoundPlayer 'C:\Windows\Media\Windows Exclamation.wav').PlaySync()
Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"C:\Temp\claude-notify.ps1`" `"$SessionName`"" -WindowStyle Hidden
