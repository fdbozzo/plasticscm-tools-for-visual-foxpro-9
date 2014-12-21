' PlasticSCM_VFP9_Pending_Changes_Regenerate_Binary.vbs (GitHub: https://github.com/fdbozzo/foxpro_plastic_diff_merge)
' 05/02/2014 - Fernando D. Bozzo (fdbozzo@gmail.com - http://fdbozzo.blogspot.com.es/)
'
'ENGLISH -------------------------------------------------------------------------------------------
' DESCRIPTION.....: PlasticSCM Tool Visual FoxPro 9 Text Regeneration of Workspace files with "Pending Changes"
'                   Copy this script in the same place of FoxBin2Prg.prg/exe
' CONFIGURATION...: Open PlasticSCM Preferences, tab Custom "Open with...", add this script and use
'                   as description "(VFP) Pending Changes: Regenerate Binaries"
' USE.............: From "Pending Changes" windows, select all files and "Open with..." this script
'
'ESPA�OL -------------------------------------------------------------------------------------------
' DESCRIPCI�N.....: Herramienta PlasticSCM para Regeneraci�n de Textos Visual FoxPro 9 de archivos del Workspace con "Cambios Pendientes"
'                   Copie este script en el mismo sitio que FoxBin2Prg.prg/exe
' CONFIGURACI�N...: Abra las Preferencias de PlasticSCM, solapa Custom "Abrir con...", agregue este script y use
'                   como descripci�n "(VFP) Pending Changes: Regenerar Binarios"
' USO.............: Desde la ventana "Cambios Pendientes", seleccione todos los archivos con "Abrir con..." este script
'---------------------------------------------------------------------------------------------------
Dim nExitCode, cEXETool, cEXETool2, nDebug
Dim cEndOfProcessMsg, cWithErrorsMsg, cConvCancelByUserMsg, nProcessedFilesCount, cErrFile
Set wshShell = CreateObject( "WScript.Shell" )
Set oVFP9 = CreateObject("VisualFoxPro.Application.9")
nExitCode = 0
'---------------------------------------------------------------------------------------------------
'Cumulative Flags:
' 1=Reserved
' 2=Reserved
' 4=Reserved
' 8=Show end of process message
nFlags = 8
'---------------------------------------------------------------------------------------------------
cEXETool2	= Replace(WScript.ScriptFullName, WScript.ScriptName, "foxpro_plasticscm_dm.exe")
cEXETool	= Replace(WScript.ScriptFullName, WScript.ScriptName, "foxpro_plasticscm_prg2bin.exe")
oVFP9.DoCmd( "SET PROCEDURE TO '" & cEXETool2 & "' ADDITIVE" )
oVFP9.DoCmd( "SET PROCEDURE TO '" & cEXETool & "' ADDITIVE" )
oVFP9.DoCmd( "PUBLIC oTarea" )
oVFP9.DoCmd( "oTarea = CREATEOBJECT('CL_SCM_2_LIB')" )
oVFP9.DoCmd( "oTarea.ProcesarArchivosPendientes('" & WScript.Arguments(0) & "')" )

If GetBit(nFlags, 4) Then
	cEndOfProcessMsg		= oVFP9.Eval("_SCREEN.o_FoxBin2Prg_Lang.C_END_OF_PROCESS_LOC")
	cWithErrorsMsg			= oVFP9.Eval("_SCREEN.o_FoxBin2Prg_Lang.C_WITH_ERRORS_LOC")
	cConvCancelByUserMsg	= oVFP9.Eval("_SCREEN.o_FoxBin2Prg_Lang.C_CONVERSION_CANCELLED_BY_USER_LOC")
	nProcessedFilesCount	= oVFP9.Eval("oTarea.o_FoxBin2prg.n_ProcessedFilesCount")

	If oVFP9.Eval("oTarea.l_Error") Then
		MsgBox cEndOfProcessMsg & "! (" & cWithErrorsMsg & ") [p:" & nProcessedFilesCount & "]" & Chr(13) & Chr(13) & oVFP9.Eval("oTarea.c_TextError"), 48+4096, WScript.ScriptName
	ElseIf oVFP9.Eval("oTarea.o_FoxBin2Prg.l_Error") Then
		MsgBox cEndOfProcessMsg & "! (" & cWithErrorsMsg & ") [p:" & nProcessedFilesCount & "]", 48+4096, WScript.ScriptName & " (" & oVFP9.Eval("oTarea.o_FoxBin2prg.c_FB2PRG_EXE_Version") & ")"
		oVFP9.DoCmd("oTarea.o_FoxBin2prg.writeErrorLog_Flush()")
		cErrFile = oVFP9.Eval("oTarea.o_FoxBin2prg.c_ErrorLogFile")
		WSHShell.run cErrFile
	ElseIf oVFP9.Eval("oTarea.c_TextError") <> "" Then
		MsgBox cEndOfProcessMsg & "!" & Chr(13) & Chr(13) & oVFP9.Eval("oTarea.c_TextError"), 64+4096, WScript.ScriptName
	Else
		MsgBox cEndOfProcessMsg & "! [p:" & nProcessedFilesCount & "]", 64+4096, WScript.ScriptName
	End If
End If

oVFP9.DoCmd( "CLEAR ALL" )
Set oVFP9 = Nothing
wshShell.SendKeys("{F5}")
WScript.Quit nExitCode


Function GetBit(lngValue, BitNum)
     Dim BitMask
     If BitNum < 32 Then BitMask = 2 ^ (BitNum - 1) Else BitMask = "&H80000000"
     GetBit = CBool(lngValue AND BitMask)
End Function
