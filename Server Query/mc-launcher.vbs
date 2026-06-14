' 静默启动器 - 无 CMD 黑窗
Set shell = CreateObject("WScript.Shell")
shell.Run "taskkill /f /im mc-server.exe >nul 2>&1", 0, True
WScript.Sleep 300
Set fso = CreateObject("Scripting.FileSystemObject")
exePath = fso.GetParentFolderName(WScript.ScriptFullName) & "\mc-server.exe"
shell.Run """" & exePath & """", 1, False
