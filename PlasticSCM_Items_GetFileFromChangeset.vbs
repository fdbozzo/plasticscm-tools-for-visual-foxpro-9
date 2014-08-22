'PlasticSCM_getFile.vbs
Dim WSHShell, nExitCode, cCMD, nDebug, strPath, oFSO, strOrigFile, strDestFile, nAnswer, nRet
Set WSHShell = WScript.CreateObject("WScript.Shell")
Set oFSO  = CreateObject( "Scripting.FileSystemObject" )
nExitCode = 0
nDebug = 0

If WScript.Arguments.Count = 0 Then
	nExitCode = 1
	MsgBox "Sin parámetros"
Else
	If InStr(WScript.Arguments(0),"#") > 0 Then
		strOrigFile = Left( WScript.Arguments(0), InStr(WScript.Arguments(0),"#") - 1 )
	Else
		strOrigFile = WScript.Arguments(0)
	End If
	
	strPath = SelectFolder( "" )
	strDestFile	= oFSO.BuildPath( strPath, oFSO.GetFileName( strOrigFile ) )

	If nDebug = 1 Then
		MsgBox "Se copiará el archivo [" & WScript.Arguments(0) & "] a [" & strDestFile & "]", vbOK + vbInformation, "Copiar archivo al workpsace"
	Else
		If strPath <> vbNull Then
			nAnswer = MsgBox("Se copiará el archivo [" & WScript.Arguments(0) & "] a [" & strDestFile & "]", vbYesNo + vbInformation, "Copiar archivo al workpsace")
			IF nAnswer = vbYes Then
				If oFSO.FileExists( strDestFile ) Then
					nRet = oFSO.DeleteFile( strDestFile, True )
				End If
				nRet = oFSO.MoveFile( WScript.Arguments(0), strDestFile )
			Else
				MsgBox "Copia Cancelada!", vbInformation, "Copiar archivo al workpsace"
			End If
		Else
			MsgBox "Copia Cancelada!", vbInformation, "Copiar archivo al workpsace"
		End If
	End If
End If

WScript.Quit(nExitCode)


Function SelectFolder( myStartFolder )
' This function opens a "Select Folder" dialog and will
' return the fully qualified path of the selected folder
'
' Argument:
'     myStartFolder    [string]    the root folder where you can start browsing;
'                                  if an empty string is used, browsing starts
'                                  on the local computer
'
' Returns:
' A string containing the fully qualified path of the selected folder
'
' Written by Rob van der Woude
' http://www.robvanderwoude.com

    ' Standard housekeeping
    Dim objFolder, objItem, objShell
    
    ' Custom error handling
    On Error Resume Next
    SelectFolder = vbNull

    ' Create a dialog object
	' cFlags: http://msdn.microsoft.com/es-es/library/windows/desktop/bb773205%28v=vs.85%29.aspx
    Set objShell  = CreateObject( "Shell.Application" )
    Set objFolder = objShell.BrowseForFolder( 0, "Select Folder", &H00000001 + &H00000010 + &H00000040 + &H000000200, myStartFolder )

    ' Return the path of the selected folder
    If IsObject( objfolder ) Then SelectFolder = objFolder.Self.Path

    ' Standard housekeeping
    Set objFolder = Nothing
    Set objshell  = Nothing
    On Error Goto 0
End Function