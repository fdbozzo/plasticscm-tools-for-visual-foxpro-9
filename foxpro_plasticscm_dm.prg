*------------------------------------------------------------------------------
*-- FOXPRO_PLASTICSCM_DM.PRG	- Visual FoxPro 9.0 DIFF/MERGE para PlasticSCM
*-- Fernando D. Bozzo			- 18/12/2013
*------------------------------------------------------------------------------
LPARAMETERS tcTool, tcSourcePath, tcDestinationPath, tcSourceSymbolic, tcDestinationSymbolic

#DEFINE CR_LF	CHR(13) + CHR(10)

LOCAL loEx AS EXCEPTION, loTool AS CL_SCM_LIB OF 'FOXPRO_PLASTICSCM_DM.PRG'
tcTool	= UPPER( EVL( tcTool, 'DIFF' ) )
loTool	= CREATEOBJECT('CL_SCM_LIB')

IF tcTool = 'DIFF'
	loTool.P_Diff( @loEx, tcSourcePath, tcDestinationPath, tcSourceSymbolic, tcDestinationSymbolic )
ELSE
ENDIF

IF _VFP.STARTMODE = 0
	RETURN
ENDIF

DECLARE ExitProcess IN Win32API INTEGER ExitCode

IF NOT ISNULL(loEx)
	loEx	= NULL
	RELEASE loEx
	ExitProcess(1)
ENDIF

QUIT
**********


DEFINE CLASS CL_SCM_LIB AS CUSTOM
	_MEMBERDATA	= [<VFPData>] ;
		+ [<memberdata name="oshell" display="oShell"/>] ;
		+ [<memberdata name="csys16" display="cSys16"/>] ;
		+ [<memberdata name="ccm" display="cCM"/>] ;
		+ [<memberdata name="cexepath" display="cEXEPath"/>] ;
		+ [<memberdata name="cplasticpath" display="cPlasticPath"/>] ;
		+ [<memberdata name="findworkspacefilename" display="FindWorkspaceFileName"/>] ;
		+ [<memberdata name="ldebug" display="lDebug"/>] ;
		+ [<memberdata name="p_diff" display="P_Diff"/>] ;
		+ [<memberdata name="runcommand" display="RunCommand"/>] ;
		+ [<memberdata name="sourceprocess" display="SourceProcess"/>] ;
		+ [<memberdata name="destinationprocess" display="DestinationProcess"/>] ;
		+ [<memberdata name="diffprocess" display="DiffProcess"/>] ;
		+ [<memberdata name="writelog" display="writeLog"/>] ;
		+ [</VFPData>]


	oShell			= NULL
	cSys16			= ''
	cEXEPath		= ''
	lDebug			= .F.
	cPlasticPath	= ''
	cCM				= ''


	PROCEDURE P_Diff
		LPARAMETERS toEx AS EXCEPTION, tcSourcePath, tcDestinationPath, tcSourceSymbolic, tcDestinationSymbolic

		TRY
			LOCAL lnExitCode AS INTEGER ;
				, loEx AS EXCEPTION ;
				, lcPlasticSCM, lcExtension_b, lcExtension_c, lcExtension_2, lcDestinationExtension, llNotInWorkspace ;
				, lcMenError, lcSourceSymbolicFileName, lcDestinationSymbolicFileName, lcWorkspaceFileName ;
				, loShell AS WScript.SHELL

			WITH THIS AS CL_SCM_LIB OF 'FOXPRO_PLASTICSCM_DM.PRG'
				STORE '' TO lcPlasticSCM, lcExtension_b, lcExtension_c, lcExtension_2, lcDestinationExtension
				loEx				= NULL
				.oShell				= CREATEOBJECT("WScript.Shell")
				loShell				= .oShell
				.cSys16				= SYS(16)
				.cSys16				= SUBSTR( .cSys16, AT( GETWORDNUM(.cSys16, 2), .cSys16 ) + LEN( GETWORDNUM(.cSys16, 2) ) + 1 )
				.cEXEPath			= JUSTPATH( .cSys16 )
				.lDebug				= ( FILE( FORCEEXT(.cSys16, 'LOG') ) )
				tcSourcePath		= STRTRAN( tcSourcePath, '\\', '\' )
				tcDestinationPath	= STRTRAN( tcDestinationPath, '\\', '\' )
				.cPlasticPath		= ''
				lcPlasticSCM		= loShell.RegRead('HKEY_CLASSES_ROOT\plastic\shell\open\command\')

				.writeLog()
				.writeLog( REPLICATE('#',80) )
				.writeLog( 'SourcePath			=' + TRANSFORM(tcSourcePath) )
				.writeLog( 'DestinationPath		=' + TRANSFORM(tcDestinationPath) )
				.writeLog( 'SourceSymbolic		=' + TRANSFORM(tcSourceSymbolic) )
				.writeLog( 'DestinationSymbolic	=' + TRANSFORM(tcDestinationSymbolic) )
				.writeLog( REPLICATE('-',80) )
				.writeLog( 'sys(16)			=' + TRANSFORM(.cSys16) )
				.writeLog( 'cEXEPath		=' + TRANSFORM(.cEXEPath) )
				.writeLog( 'lcPlasticSCM	=' + TRANSFORM(lcPlasticSCM) )

				IF EMPTY( lcPlasticSCM )
					.cCM	= '"cm.exe"'
				ELSE
					.cCM	= STRTRAN( STREXTRACT( lcPlasticSCM, '"', '"', 1, 4 ), 'plastic.exe', 'cm.exe' )
					.cPlasticPath		= JUSTPATH(.cCM)
				ENDIF
				
				.FindWorkspaceFileName( @lcWorkspaceFileName, tcSourcePath, tcDestinationPath, tcSourceSymbolic, tcDestinationSymbolic )

				lcDestinationExtension	= JUSTEXT(tcDestinationPath)
				llNotInWorkspace 		= .T.

				DO CASE
				CASE lcDestinationExtension = "pjx"
					lcExtension_b	= "pjt"
					lcExtension_2	= "pj2"

				CASE lcDestinationExtension = "vcx"
					lcExtension_b	= "vct"
					lcExtension_2	= "vc2"

				CASE lcDestinationExtension = "scx"
					lcExtension_b	= "sct"
					lcExtension_2	= "sc2"

				CASE lcDestinationExtension = "frx"
					lcExtension_b	= "frt"
					lcExtension_2	= "fr2"

				CASE lcDestinationExtension = "lbx"
					lcExtension_b	= "lbt"
					lcExtension_2	= "lb2"

				CASE lcDestinationExtension = "dbf"
					lcExtension_b	= "fpt"
					lcExtension_c	= "cdx"	&& Ver como tratar esto cuando hay, o no, un CDX.
					lcExtension_2	= "db2"

				CASE lcDestinationExtension = "dbc"
					lcExtension_b	= "dct"
					lcExtension_2	= "dc2"

				OTHERWISE
					ERROR 'Extensión [' + TRANSFORM(lcDestinationExtension) + '] no soportada!'

				ENDCASE

				.SourceProcess( lcDestinationExtension, lcExtension_b, lcExtension_c, tcSourceSymbolic ;
					, tcSourcePath, tcDestinationPath, lcWorkspaceFileName )
				llNotInWorkspace  = .DestinationProcess( lcDestinationExtension, lcExtension_b, lcExtension_c ;
					, tcDestinationSymbolic, tcDestinationPath, lcWorkspaceFileName )
				.DiffProcess( lcDestinationExtension, lcExtension_b, lcExtension_c, lcExtension_2, tcSourcePath ;
					, tcDestinationPath, llNotInWorkspace )
			ENDWITH && THIS AS CL_SCM_LIB OF 'FOXPRO_PLASTICSCM_DM.PRG'

		CATCH TO loEx
			lcMenError	= 'CurDir: ' + SYS(5)+CURDIR() + CR_LF ;
				+ 'Sys16: ' + SYS(16) + CR_LF ;
				+ 'Error ' + TRANSFORM(loEx.ERRORNO) + ', ' + loEx.MESSAGE + CR_LF ;
				+ loEx.PROCEDURE + ', line ' + TRANSFORM(loEx.LINENO) + CR_LF ;
				+ loEx.LINECONTENTS
			THIS.writeLog( lcMenError )
			*IF _VFP.StartMode = 0
			MESSAGEBOX( lcMenError, 0+16+4096, "ATENCIÓN!!", 60000 )
			*ENDIF

		FINALLY
			loShell	= NULL

		ENDTRY

		RETURN
	ENDPROC



	FUNCTION SourceProcess
		LPARAMETERS tcDestinationExtension, tcExtension_b, tcExtension_c, tcSourceSymbolic, tcSourcePath ;
			, tcDestinationPath, tcWorkspaceFileName

		#IF .F.
			LOCAL THIS AS CL_SCM_LIB OF 'FOXPRO_PLASTICSCM_DM.PRG'
		#ENDIF

		TRY
			LOCAL lcSourceSymbolicExtensionReplaced, lcSourceSpecForCatCommand, lcSourcePathExtensionReplaced ;
				, laSourceSymbolicExtensionReplaced_Splited(1), lcCommand, lnCommandResult, lcSourcePathParsed ;
				, loShell AS WScript.SHELL

			WITH THIS AS CL_SCM_LIB OF 'FOXPRO_PLASTICSCM_DM.PRG'
				loShell				= .oShell
				lnCommandResult		= 0
				lcSourceSymbolicExtensionReplaced	= FORCEEXT( tcSourceSymbolic, tcExtension_b )

				* Parse source symbolic when operation is: "Diff with previous revision"
				IF '@' $ lcSourceSymbolicExtensionReplaced
					*-------------------------------------------------------------------------------
					* Ejemplo 1:	sourcesymbolic="c:\DESA\foxbin2prg\foxbin2prg.pjx#cs:61@br:/main/inicio soporte MNX fdbozzo" 
					* Ejemplo 2:	sourcesymbolic="cs:61@br:/main/inicio soporte MNX fdbozzo"			==> Al hacer un DIFF luego de un MERGE sin confirmar
					*-------------------------------------------------------------------------------
					ALINES( laSourceSymbolicExtensionReplaced_Splited, lcSourceSymbolicExtensionReplaced, 4, '@')
					lcSourceSpecForCatCommand	= '"' + laSourceSymbolicExtensionReplaced_Splited[1] + '"'

					IF NOT '#' $ lcSourceSpecForCatCommand
						*-- Cuando se hace un MERGE y no se confirman los cambios, el DIFF no devuelve
						*-- el nombre del archivo en SourceFile, sino en DestinationFile
						.writeLog( '=> Se cambia lcSourceSpecForCatCommand de [' + lcSourceSpecForCatCommand ;
							+ '] a ["' + FORCEEXT( tcDestinationPath, tcExtension_b) + '#' + SUBSTR(lcSourceSpecForCatCommand,2) + ']' )
						lcSourceSpecForCatCommand	= '"' + FORCEEXT( tcDestinationPath, tcExtension_b) + '#' + SUBSTR(lcSourceSpecForCatCommand,2)
						*tcWorkspaceFileName			= tcDestinationPath
					ENDIF

				ELSE	&& Parse source symbolic when operation is: "Diff between revision A and revision B"
					*-------------------------------------------------------------------------------
					* Ejemplo 1:	sourcesymbolic="rev:c:\DESA\foxbin2prg\foxbin2prg.pjx#cs:61"
					* Ejemplo 2:	sourcesymbolic="c:\DESA\foxbin2prg\foxbin2prg.prg#br:/main/v1.12 DESA" 
					*-------------------------------------------------------------------------------
					ALINES( laSourceSymbolicExtensionReplaced_Splited, lcSourceSymbolicExtensionReplaced, 4, 'rev:')
					lcSourceSpecForCatCommand	= '"' + laSourceSymbolicExtensionReplaced_Splited[1] + '"'
				ENDIF

				lcSourcePathExtensionReplaced	= FORCEEXT( tcSourcePath, tcExtension_b )

				*-------------------------------------------------------------------------------
				* Ejemplo 1:	
				*-------------------------------------------------------------------------------
				lcCommand			= .cCM + ' cat ' + lcSourceSpecForCatCommand + ' --file="' + lcSourcePathExtensionReplaced + '"'
				lnCommandResult		= .RunCommand( lcCommand )

				IF (lnCommandResult == 1)
					ERROR "There was an error performing the diff operation."
					*Environment.Exit(0);

				ELSE
					lcSourcePathParsed	= ' "' + tcSourcePath + '" "0" "0" "0" "0" "0" "0" "' + tcWorkspaceFileName + '"'
					lcCommand			= '"' + FORCEPATH( 'foxbin2prg.exe', .cEXEPath ) + '"' + lcSourcePathParsed
					lnCommandResult		= .RunCommand( lcCommand )

					IF (lnCommandResult == 1)
						ERROR "Foxbin2prg devolvió un error"
					ENDIF
				ENDIF
			ENDWITH &&	THIS AS CL_SCM_LIB OF 'FOXPRO_PLASTICSCM_DM.PRG'

		CATCH TO loEx
			IF _VFP.STARTMODE = 0 AND THIS.lDebug
				SET STEP ON
			ENDIF
			THROW
		ENDTRY

		RETURN
	ENDFUNC


	FUNCTION DestinationProcess
		LPARAMETERS tcDestinationExtension, tcExtension_b, tcExtension_c, tcDestinationSymbolic ;
			, tcDestinationPath, tcWorkspaceFileName

		#IF .F.
			LOCAL THIS AS CL_SCM_LIB OF 'FOXPRO_PLASTICSCM_DM.PRG'
		#ENDIF

		TRY
			LOCAL lcDestinationSymbolicExtensionReplaced, lcDestinationSpecForCatCommand, lcDestinationPathExtensionReplaced ;
				, laDestinationSymbolicExtensionReplaced_Splited(1), lcCommand, lnCommandResult, lcDestinationPathParsed ;
				, llNotInWorkspace ;
				, loShell AS WScript.SHELL

			WITH THIS AS CL_SCM_LIB OF 'FOXPRO_PLASTICSCM_DM.PRG'
				loShell				= .oShell
				lnCommandResult		= 0

				* Parse destination symbolic when operation is: "Diff between revision A and revision B"
				IF "rev:" $ tcDestinationSymbolic
					lcDestinationSymbolicExtensionReplaced = FORCEEXT( tcDestinationSymbolic, tcExtension_b )
					ALINES( laDestinationSymbolicExtensionReplaced_Splited, lcDestinationSymbolicExtensionReplaced, 4, "rev:" )
					lcDestinationSpecForCatCommand		= '"' + laDestinationSymbolicExtensionReplaced_Splited[1] + '"'
					lcDestinationPathExtensionReplaced	= FORCEEXT( tcDestinationPath, tcExtension_b )

					lcCommand 			= .cCM + ' cat ' + lcDestinationSpecForCatCommand + ' --file="' + lcDestinationPathExtensionReplaced + '"'
					lnCommandResult		= .RunCommand( lcCommand )

					IF (lnCommandResult == 1)
						ERROR "There was an error performing the diff (rev) operation."
						*Environment.Exit(0);

					ELSE
						lcDestinationPathParsed	= ' "' + tcDestinationPath + '" "0" "0" "0" "0" "0" "0" "' + tcWorkspaceFileName + '"'
						lcCommand				= '"' + FORCEPATH( 'foxbin2prg.exe', .cEXEPath ) + '"' + lcDestinationPathParsed
						lnCommandResult		= .RunCommand( lcCommand )

						IF (lnCommandResult == 1)
							ERROR "Foxbin2prg devolvió un error"
						ENDIF
					ENDIF

					llNotInWorkspace	= .T.

				ELSE
					lcDestinationPathParsed	= ' "' + tcDestinationPath + '" "0" "0" "0" "0" "0" "0" "' + tcWorkspaceFileName + '"'
					lcCommand			= '"' + FORCEPATH( 'foxbin2prg.exe', .cEXEPath ) + '"' + lcDestinationPathParsed
					lnCommandResult		= .RunCommand( lcCommand )

					IF (lnCommandResult == 1)
						ERROR "Foxbin2prg devolvió un error"
					ENDIF
				ENDIF
			ENDWITH &&	THIS AS CL_SCM_LIB OF 'FOXPRO_PLASTICSCM_DM.PRG'

		CATCH TO loEx
			IF _VFP.STARTMODE = 0 AND THIS.lDebug
				SET STEP ON
			ENDIF
			THROW
		ENDTRY

		RETURN llNotInWorkspace
	ENDFUNC


	FUNCTION DiffProcess
		LPARAMETERS tcDestinationExtension, tcExtension_b, tcExtension_c, tcExtension_2, tcSourcePath, tcDestinationPath, tlNotInWorkspace

		#IF .F.
			LOCAL THIS AS CL_SCM_LIB OF 'FOXPRO_PLASTICSCM_DM.PRG'
		#ENDIF

		TRY
			LOCAL laDestinationSymbolicExtensionReplaced_Splited(1), lcCommand, lnCommandResult ;
				, lcConvertToTextSource, lcConvertToTextDestination, lcArguments ;
				, loShell AS WScript.SHELL

			WITH THIS AS CL_SCM_LIB OF 'FOXPRO_PLASTICSCM_DM.PRG'
				loShell						= .oShell
				lnCommandResult				= 0
				lcConvertToTextSource		= '"' + FORCEEXT( tcSourcePath, tcExtension_2 ) + '"'
				lcConvertToTextDestination	= '"' + FORCEEXT( tcDestinationPath, tcExtension_2 ) + '"'
				
				*-- Verifico si existe antes, porque puede que haya ocurrido un error (.ERR)
				IF FILE(lcConvertToTextSource) AND FILE( lcConvertToTextDestination )
					lcArguments			= " -s=" + lcConvertToTextSource + " -d=" + lcConvertToTextDestination
					lcCommand			= '"' + FORCEPATH( 'mergetool.exe', .cPlasticPath ) + '"' + lcArguments
					lnCommandResult		= .RunCommand( lcCommand )

					IF (lnCommandResult == 1)
						ERROR "mergetool devolvió un error"
					ENDIF
				ELSE	&& Ocurrió un error
					.writeLog( 'No existe el archivo [' + lcConvertToTextSource + '] o [' +lcConvertToTextDestination  + ']' )
					DO CASE
					CASE FILE( '"' + tcSourcePath + '.ERR"' )
						lcCommand			= 'notepad.exe "' + tcSourcePath + '.ERR"'
						lnCommandResult		= .RunCommand( lcCommand, 1 )

					CASE FILE( '"' + tcDestinationPath + '.ERR"' )
						lcCommand			= 'notepad.exe "' + '"' + tcDestinationPath + '.ERR"'
						lnCommandResult		= .RunCommand( lcCommand, 1 )

					OTHERWISE
						.writeLog( 'No existen los archivos ["' + tcSourcePath + '.ERR' ;
							+ '"] y ["' + tcDestinationPath + '"]' )
					ENDCASE
				ENDIF

				.writeLog( 'ERASE ' + lcConvertToTextSource )
				.writeLog( 'ERASE ' + '"' + FORCEEXT( tcSourcePath, tcExtension_b ) + '"' )
				.writeLog( 'ERASE "' + tcSourcePath + '"' )
				ERASE ( lcConvertToTextSource )
				ERASE ( '"' + FORCEEXT( tcSourcePath, tcExtension_b ) + '"' )
				ERASE ( tcSourcePath )

				IF tlNotInWorkspace
					.writeLog( 'ERASE ' + lcConvertToTextDestination )
					.writeLog( 'ERASE ' + '"' + FORCEEXT( tcDestinationPath, tcExtension_b ) + '"' )
					.writeLog( 'ERASE "' + tcDestinationPath + '"' )
					ERASE ( lcConvertToTextDestination )
					ERASE ( '"' + FORCEEXT( tcDestinationPath, tcExtension_b ) + '"' )
					ERASE ( tcDestinationPath )
				ENDIF
			ENDWITH &&	THIS AS CL_SCM_LIB OF 'FOXPRO_PLASTICSCM_DM.PRG'

		CATCH TO loEx
			IF _VFP.STARTMODE = 0 AND THIS.lDebug
				SET STEP ON
			ENDIF
			THROW
		ENDTRY

		RETURN
	ENDFUNC


	PROCEDURE FindWorkspaceFileName
		LPARAMETERS tcWorkspaceFileName, tcSourcePath, tcDestinationPath, tcSourceSymbolic, tcDestinationSymbolic

		TRY
			LOCAL lcSymbolicFileName
			tcWorkspaceFileName	= ''

			*-- Intento obtener el nombre original del archivo del workspace, para usarlo en las vistas texto
			*-- y que no aparezcan los nombres temporales dentro.
			IF '#' $ tcSourceSymbolic
				lcSymbolicFileName	= GETWORDNUM( STRTRAN(tcSourceSymbolic, 'rev:', ''), 1, '#' )

				IF NOT EMPTY(lcSymbolicFileName) &&AND FILE(lcSymbolicFileName)
					tcWorkspaceFileName	= lcSymbolicFileName
					THIS.writeLog( 'WorkspaceFileName=' + tcWorkspaceFileName + ' (opc.1)' )
					EXIT
				ENDIF
			ENDIF

			IF '#' $ tcDestinationSymbolic
				lcSymbolicFileName	= GETWORDNUM( STRTRAN(tcDestinationSymbolic, 'rev:', ''), 1, '#' )

				IF NOT EMPTY(lcSymbolicFileName) &&AND FILE(lcSymbolicFileName)
					tcWorkspaceFileName	= lcSymbolicFileName
					THIS.writeLog( 'WorkspaceFileName=' + tcWorkspaceFileName + ' (opc.2)' )
					EXIT
				ENDIF
			ENDIF

			IF '@' $ tcSourceSymbolic
				lcSymbolicFileName	= tcDestinationPath

				IF NOT EMPTY(lcSymbolicFileName) &&AND FILE(lcSymbolicFileName)
					tcWorkspaceFileName	= lcSymbolicFileName
					THIS.writeLog( 'WorkspaceFileName=' + tcWorkspaceFileName + ' (opc.3)' )
					EXIT
				ENDIF
			ENDIF
		ENDTRY

	ENDPROC


	FUNCTION RunCommand
		LPARAMETERS tcCommand, tnWindowType

		LOCAL lnCommandResult
		tnWindowType		= EVL(tnWindowType,0)
		THIS.writeLog( tcCommand )
		lnCommandResult		= THIS.oShell.RUN( tcCommand, tnWindowType, .T. )
		THIS.writeLog( '	=> retornó ' + TRANSFORM(lnCommandResult) )
		
		RETURN lnCommandResult
	ENDFUNC


	FUNCTION writeLog
		LPARAMETERS tcText

		#IF .F.
			LOCAL THIS AS CL_SCM_LIB OF 'FOXPRO_PLASTICSCM_DM.PRG'
		#ENDIF

		IF THIS.lDebug
			TRY
				tcText	= EVL(tcText,'')
				STRTOFILE( TRANSFORM(tcText) + CR_LF, FORCEPATH( 'foxpro_plasticscm_dm.log', GETENV("TEMP") ), 1 )
			CATCH
			ENDTRY
		ENDIF

		RETURN
	ENDFUNC


ENDDEFINE
