Set args = WScript.Arguments
If args.Count < 2 Then WScript.Quit
scriptFile = args(0)
sessionName = args(1)
CreateObject("WScript.Shell").Run "powershell.exe -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File """ & scriptFile & """ """ & sessionName & """", 0, False
