' run-hidden.vbs - Executa o theme-agent.ps1 de forma 100% invisível (sem flash ou janela de console)
Option Explicit

Dim objShell, objFSO, strDir, strScript, strCommand, i, arg

Set objShell = CreateObject("WScript.Shell")
Set objFSO = CreateObject("Scripting.FileSystemObject")

' Caminho da pasta e do script theme-agent.ps1
strDir = objFSO.GetParentFolderName(WScript.ScriptFullName)
strScript = strDir & "\theme-agent.ps1"

' Comando base chamando o PowerShell em modo não interativo
strCommand = "powershell.exe -NoProfile -ExecutionPolicy Bypass -File """ & strScript & """"

' Repassa todos os argumentos recebidos para o script PowerShell
For i = 0 To WScript.Arguments.Count - 1
    arg = WScript.Arguments(i)
    If InStr(arg, " ") > 0 Then
        strCommand = strCommand & " """ & arg & """"
    Else
        strCommand = strCommand & " " & arg
    End If
Next

' Executa com janela oculta (0 = SW_HIDE) sem bloquear a chamada (False)
objShell.Run strCommand, 0, False
