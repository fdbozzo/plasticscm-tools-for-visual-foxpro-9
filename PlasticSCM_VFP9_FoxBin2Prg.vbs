' PlasticSCM_VFP9_FoxBin2Prg.vbs (GitHub: https://github.com/fdbozzo/foxpro_plastic_diff_merge)
' 19/09/2014 - Fernando D. Bozzo (fdbozzo@gmail.com - http://fdbozzo.blogspot.com.es/)
'
'ENGLISH -------------------------------------------------------------------------------------------
' DESCRIPTION.....: PlasticSCM Tool Visual FoxPro 9 Text Regeneration of ALL Workspace files
'                   Copy this script in the same place of FoxBin2Prg.prg/exe
' CONFIGURATION...: Open PlasticSCM Preferences, tab Custom "Open with...", add this script and use
'                   as description "(VFP) FoxBin2Prg"
' USE.............: From "Pending Changes" or "Items" view, select ONE file and "Open with..." this script
'
'ESPAÑOL -------------------------------------------------------------------------------------------
' DESCRIPCIÓN.....: Herramienta PlasticSCM para Regeneración de Textos Visual FoxPro 9 de TODOS los archivos del Workspace
'                   Copie este script en el mismo sitio que FoxBin2Prg.prg/exe
' CONFIGURACIÓN...: Abra las Preferencias de PlasticSCM, solapa Custom "Abrir con...", agregue este script y use
'                   como descripción "(VFP) FoxBin2Prg"
' USO.............: Desde la vista "Cambios Pendientes" o "Items", seleccione UN archivo con "Abrir con..." este script
'---------------------------------------------------------------------------------------------------
Dim WSHShell, FileSystemObject, cEndOfProcessMsg, cWithErrorsMsg, cConvCancelByUserMsg, nProcessedFilesCount
Dim nExitCode, cEXETool, cEXETool2, nDebug
Set wshShell = CreateObject( "WScript.Shell" )
Set FileSystemObject = WScript.CreateObject("Scripting.FileSystemObject")
Set oVFP9 = CreateObject("VisualFoxPro.Application.9")
nExitCode = 0
'---------------------------------------------------------------------------------------------------
'Cumulative Flags:
' 0=OFF
' 1=Create FoxBin2prg LOG
' 2=Only show script calls (for testing without executing)
' 4=Don't show FoxBin2prg error modal messages
' 8=Show end of process message
' 16=Empty timestamps
nDebug = 1+0+4+8
'---------------------------------------------------------------------------------------------------

If WScript.Arguments.Count = 0 Then
	'SIN PARÁMETROS
	nExitCode = 1
	cErrMsg = "nDebug = " & nDebug
	If GetBit(nDebug, 1) Then
		cErrMsg	= cErrMsg & Chr(13) & "Bit 0 ON: (1) Create FoxBin2prg LOG"
	End If
	If GetBit(nDebug, 2) Then
		cErrMsg	= cErrMsg & Chr(13) & "Bit 1 ON: (2) Only show script calls"
	End If
	If GetBit(nDebug, 3) Then
		cErrMsg	= cErrMsg & Chr(13) & "Bit 2 ON: (4) Don't show FoxBin2prg error modal messages"
	End If
	If GetBit(nDebug, 4) Then
		cErrMsg	= cErrMsg & Chr(13) & "Bit 3 ON: (8) Show End of Process message"
	End If
	If GetBit(nDebug, 5) Then
		cErrMsg	= cErrMsg & Chr(13) & "Bit 4 ON: (16) Empty timestamps"
	End If
	MsgBox cErrMsg, 64, "No parameters - Debug Status"

ElseIf WScript.Arguments.Count > 1 Then
	MsgBox cErrMsg, 64, "You can select just ONE file with this script!"
	
Else
	'CON PARÁMETROS
	cEXETool	= Replace(WScript.ScriptFullName, WScript.ScriptName, "foxbin2prg.exe")
	nFile_Count = 0
	oVFP9.DoCmd( "SET PROCEDURE TO '" & cEXETool & "'" )
	oVFP9.DoCmd( "PUBLIC oFoxBin2prg" )
	oVFP9.DoCmd( "oFoxBin2prg = CREATEOBJECT('c_foxbin2prg')" )
	oVFP9.DoCmd( "oFoxBin2prg.cargar_frm_avance()" )
	oVFP9.DoCmd( "oFoxBin2prg.o_frm_avance.Caption = '" & FileSystemObject.GetBaseName( WScript.ScriptName ) & " - ' + oFoxBin2Prg.c_loc_process_progress" )
	
	cFlagGenerateLog		= "'0'"
	cFlagDontShowErrMsg		= "'0'"
	cFlagShowCall			= "'0'"
	cFlagRecompile			= "'1'"

	If GetBit(nDebug, 1) Then
		cFlagGenerateLog	= "'1'"
	End If
	If GetBit(nDebug, 2) Then
		cFlagJustShowCall	= "1"
	End If
	If GetBit(nDebug, 3) Then
		cFlagDontShowErrMsg	= "'1'"
	End If
	If GetBit(nDebug, 5) Then
		cNoTimestamps	= "'1'"
	End If
	
	cFlagRecompile	= "'" & FileSystemObject.GetParentFolderName( WScript.Arguments(0) ) & "'"

	oVFP9.DoCmd( "oFoxBin2prg.o_frm_avance.Caption = '" & FileSystemObject.GetBaseName( WScript.ScriptName ) & " - ' + oFoxBin2Prg.c_loc_process_progress + '  (Press Esc to Cancel)'" )
	
	If nDebug = 0 Or nDebug = 2 Then
		cCMD	= "oFoxBin2prg.ejecutar( '" & WScript.Arguments(0) & "' )"
	Else
		cCMD	= "oFoxBin2prg.ejecutar(  '" & WScript.Arguments(0) & "','0','0','0'," _
			& cFlagDontShowErrMsg & "," & cFlagGenerateLog & ",'0','','',.F.,''," _
			& cFlagRecompile & "," & cNoTimestamps & " )"
	End If
	If cFlagJustShowCall = "1" Then
		MsgBox cCMD, 64, "PARAMETERS"
	Else
		oVFP9.DoCmd( cCMD )
		nExitCode = oVFP9.Eval("_SCREEN.ExitCode")
	End If

	If GetBit(nDebug, 4) Then
		cEndOfProcessMsg		= oVFP9.Eval("_SCREEN.o_FoxBin2Prg_Lang.C_END_OF_PROCESS_LOC")
		cWithErrorsMsg			= oVFP9.Eval("_SCREEN.o_FoxBin2Prg_Lang.C_WITH_ERRORS_LOC")
		cConvCancelByUserMsg	= oVFP9.Eval("_SCREEN.o_FoxBin2Prg_Lang.C_CONVERSION_CANCELLED_BY_USER_LOC")
		nProcessedFilesCount	= oVFP9.Eval("oFoxBin2prg.n_ProcessedFilesCount")

		If nExitCode = 1799 Then
			MsgBox cConvCancelByUserMsg & "! [p:" & nProcessedFilesCount & "]", 48+4096, WScript.ScriptName & " (" & oVFP9.Eval("oFoxBin2prg.c_FB2PRG_EXE_Version") & ")"
			oVFP9.DoCmd("oFoxBin2prg.writeErrorLog_Flush()")
			cErrFile = oVFP9.Eval("oFoxBin2prg.c_ErrorLogFile")
			WSHShell.run cErrFile

		ElseIf oVFP9.Eval("oFoxBin2prg.l_Error") Then
			MsgBox cEndOfProcessMsg & "! (" & cWithErrorsMsg & ") [p:" & nProcessedFilesCount & "]", 48+4096, WScript.ScriptName & " (" & oVFP9.Eval("oFoxBin2prg.c_FB2PRG_EXE_Version") & ")"
			oVFP9.DoCmd("oFoxBin2prg.writeErrorLog_Flush()")
			cErrFile = oVFP9.Eval("oFoxBin2prg.c_ErrorLogFile")
			WSHShell.run cErrFile
		Else
			MsgBox cEndOfProcessMsg & "! [p:" & nProcessedFilesCount & "]", 64+4096, WScript.ScriptName & " (" & oVFP9.Eval("oFoxBin2prg.c_FB2PRG_EXE_Version") & ")"
		End If
	End If

	oVFP9.DoCmd( "oFoxBin2prg = NULL" )
	oVFP9.DoCmd( "CLEAR ALL" )
	Set oVFP9 = Nothing
	wshShell.SendKeys("{F5}")
End If

WScript.Quit nExitCode


Function GetBit(lngValue, BitNum)
     Dim BitMask
     If BitNum < 32 Then BitMask = 2 ^ (BitNum - 1) Else BitMask = "&H80000000"
     GetBit = CBool(lngValue AND BitMask)
End Function
