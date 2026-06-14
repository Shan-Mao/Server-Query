CreateObject("WScript.Shell").Run "cmd /c del /q """ & CreateObject("Scripting.FileSystemObject").GetParentFolderName(WScript.ScriptFullName) & "\server-config.ini""", 0, True
