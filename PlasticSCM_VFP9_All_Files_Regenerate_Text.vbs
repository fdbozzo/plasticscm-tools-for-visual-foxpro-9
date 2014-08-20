' PlasticSCM_VFP9_All_Files_Regenerate_Text.vbs
' 05/02/2014 - Fernando D. Bozzo (fdbozzo@gmail.com - http://fdbozzo.blogspot.com.es/)
'
'ENGLISH -------------------------------------------------------------------------------------------
' DESCRIPTION.....: PlasticSCM Tool Visual FoxPro 9 Binary Regeneration of ALL Workspace files
'                   Copy this script in the same place of FoxBin2Prg.prg/exe
' CONFIGURATION...: Open PlasticSCM Preferences, tab Custom "Open with...", add this script and use
'                   as description "(VFP) All Files: Regenerate Text versions"
' USE.............: From "Pending Changes" windows, select all files and "Open with..." this script
'
'ESPAÑOL -------------------------------------------------------------------------------------------
' DESCRIPCIÓN.....: Herramienta PlasticSCM para Regeneración de Binarios Visual FoxPro 9 de TODOS los archivos del Workspace
'                   Copie este script en el mismo sitio que FoxBin2Prg.prg/exe
' CONFIGURACIÓN...: Abra las Preferencias de PlasticSCM, solapa Custom "Abrir con...", agregue este script y use
'                   como descripción "(VFP) Todos los Archivos: Regenerar versiones Texto"
' USO.............: Desde la ventana "Cambios Pendientes", seleccione todos los archivos con "Abrir con..." este script
'---------------------------------------------------------------------------------------------------
Dim nExitCode, cEXETool, cEXETool2, nDebug
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
cEXETool	= Replace(WScript.ScriptFullName, WScript.ScriptName, "foxpro_plasticscm_bin2prg.exe")
oVFP9.DoCmd( "SET PROCEDURE TO '" & cEXETool2 & "' ADDITIVE" )
oVFP9.DoCmd( "SET PROCEDURE TO '" & cEXETool & "' ADDITIVE" )
oVFP9.DoCmd( "PUBLIC oTarea" )
oVFP9.DoCmd( "oTarea = CREATEOBJECT('CL_SCM_2_LIB')" )
oVFP9.DoCmd( "oTarea.ProcesarArchivos('" & WScript.Arguments(0) & "')" )
wshShell.SendKeys("{F5}")

If GetBit(nFlags, 4) Then
	If oVFP9.Eval("oTarea.l_Error") Then
		MsgBox "End of Process! (with errors)" & Chr(13) & Chr(13) & oVFP9.Eval("oTarea.c_TextError"), 48, WScript.ScriptName
	ElseIf oVFP9.Eval("oTarea.c_TextError") <> "" Then
		MsgBox "End of Process!" & Chr(13) & Chr(13) & oVFP9.Eval("oTarea.c_TextError"), 64, WScript.ScriptName
	Else
		MsgBox "End of Process!", 64, WScript.ScriptName
	End If
End If

oVFP9.DoCmd( "CLEAR ALL" )
Set oVFP9 = Nothing
WScript.Quit(nExitCode)


Function GetBit(lngValue, BitNum)
     Dim BitMask
     If BitNum < 32 Then BitMask = 2 ^ (BitNum - 1) Else BitMask = "&H80000000"
     GetBit = CBool(lngValue AND BitMask)
End Function
