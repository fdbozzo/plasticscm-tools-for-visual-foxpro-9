*------------------------------------------------------------------------------
*-- FOXPRO_PLASTICSCM_DM.PRG	- Visual FoxPro 9.0 DIFF/MERGE para PlasticSCM
*-- Fernando D. Bozzo			- 18/12/2013
*------------------------------------------------------------------------------
* PAR�METROS:				(!=Obligatorio | ?=Opcional) (@=Pasar por referencia | v=Pasar por valor) (IN/OUT)
* toEx						(?@    OUT) Objeto con informaci�n del error
* tcSourcePath				(!v IN    ) Path del archivo origen
* tcDestinationPath			(!v IN    ) Path del archivo destino
* tcSourceSymbolic			(!v IN    ) Ruta simb�lica del archivo origen con informaci�n del changeset, branch o revisi�n
* tcDestinationSymbolic		(!v IN    ) Ruta simb�lica del archivo destino con informaci�n del changeset, branch o revisi�n
*-- Estos se usan para el MERGE:
* tcBasePath				(!v IN    ) Path del archivo base (base del archivo origen y del destino)
* tcBaseSymbolic			(!v IN    ) Ruta simb�lica del archivo base con informaci�n del changeset, branch o revisi�n
* tcOutputPath				(!v IN    ) Path del archivo de salida generado
*--------------------------------------------------------------------------------------------------------------
LPARAMETERS tcTool, tcSourcePath, tcDestinationPath, tcSourceSymbolic, tcDestinationSymbolic ;
	, tcBasePath, tcBaseSymbolic, tcOutputPath

#DEFINE CR_LF	CHR(13) + CHR(10)

LOCAL loEx AS EXCEPTION, loTool AS CL_SCM_LIB OF 'FOXPRO_PLASTICSCM_DM.PRG'
loEx	= NULL
tcTool	= UPPER( EVL( tcTool, 'DIFF' ) )
loTool	= CREATEOBJECT('CL_SCM_LIB')

DO CASE
CASE VARTYPE(loTool) <> 'O'
	loEx	= CREATEOBJECT("Exception")

CASE tcTool == 'DIFF'
	loTool.P_Diff( @loEx, tcSourcePath, tcDestinationPath, tcSourceSymbolic, tcDestinationSymbolic )

CASE tcTool == 'MERGE'
	loTool.P_Merge( @loEx, tcSourcePath, tcDestinationPath, tcSourceSymbolic, tcDestinationSymbolic, tcBasePath, tcBaseSymbolic, tcOutputPath )

OTHERWISE
	loEx	= CREATEOBJECT("Exception")
ENDCASE

loTool	= NULL

IF _VFP.STARTMODE = 0
	RETURN
ENDIF

DECLARE ExitProcess IN Win32API INTEGER ExitCode

IF NOT ISNULL(loEx)
	loEx	= NULL
	ExitProcess(1)
ENDIF

QUIT
*******************************************************************************


DEFINE CLASS CL_SCM_LIB AS SESSION
	_MEMBERDATA	= [<VFPData>] ;
		+ [<memberdata name="csys16" display="cSys16"/>] ;
		+ [<memberdata name="ccm" display="cCM"/>] ;
		+ [<memberdata name="cexepath" display="cEXEPath"/>] ;
		+ [<memberdata name="changefileattribute" display="ChangeFileAttribute"/>] ;
		+ [<memberdata name="cplasticpath" display="cPlasticPath"/>] ;
		+ [<memberdata name="baseprocessformerge" display="BaseProcessForMerge"/>] ;
		+ [<memberdata name="converttobinaryprocess" display="ConvertToBinaryProcess"/>] ;
		+ [<memberdata name="copyfile" display="CopyFile"/>] ;
		+ [<memberdata name="ctextlog" display="cTextLog"/>] ;
		+ [<memberdata name="deletefile" display="DeleteFile"/>] ;
		+ [<memberdata name="destinationprocessfordiff" display="DestinationProcessForDiff"/>] ;
		+ [<memberdata name="destinationprocessformerge" display="DestinationProcessForMerge"/>] ;
		+ [<memberdata name="diffprocess" display="DiffProcess"/>] ;
		+ [<memberdata name="findworkspacefilename" display="FindWorkspaceFileName"/>] ;
		+ [<memberdata name="getsecondaryextensions" display="GetSecondaryExtensions"/>] ;
		+ [<memberdata name="initialize" display="Initialize"/>] ;
		+ [<memberdata name="ldebug" display="lDebug"/>] ;
		+ [<memberdata name="l_initialized" display="l_Initialized"/>] ;
		+ [<memberdata name="mergeprocess" display="MergeProcess"/>] ;
		+ [<memberdata name="movefile" display="MoveFile"/>] ;
		+ [<memberdata name="ofso" display="oFSO"/>] ;
		+ [<memberdata name="oshell" display="oShell"/>] ;
		+ [<memberdata name="p_diff" display="P_Diff"/>] ;
		+ [<memberdata name="p_merge" display="P_Merge"/>] ;
		+ [<memberdata name="runcommand" display="RunCommand"/>] ;
		+ [<memberdata name="sourceprocessfordiff" display="SourceProcessForDiff"/>] ;
		+ [<memberdata name="sourceprocessformerge" display="SourceProcessForMerge"/>] ;
		+ [<memberdata name="writelog" display="writeLog"/>] ;
		+ [</VFPData>]


	oShell			= NULL
	oFSO			= NULL
	cSys16			= ''
	cEXEPath		= ''
	lDebug			= .F.
	cPlasticPath	= ''
	cCM				= ''
	cTextLog		= ''
	l_Initialized	= .F.


	PROCEDURE INIT
		SET DATE TO YMD
		SET HOURS TO 24
		SET SAFETY OFF
		SET TALK OFF
		SET NOTIFY OFF
		THIS.writeLog( '---' + PROGRAM() + '----------' )
	ENDPROC


	PROCEDURE DESTROY
		IF NOT EMPTY(THIS.cTextLog)
			THIS.writeLog( '---' + PROGRAM() + '----------' )
			STRTOFILE( THIS.cTextLog, FORCEPATH( 'foxpro_plasticscm_dm.log', GETENV("TEMP") ), 1 )
		ENDIF
	ENDPROC


	PROCEDURE Initialize
		LPARAMETERS tcSourcePath, tcDestinationPath, tcSourceSymbolic, tcDestinationSymbolic ;
			, tcBasePath, tcBaseSymbolic, tcOutputPath

		WITH THIS AS CL_SCM_LIB OF 'FOXPRO_PLASTICSCM_DM.PRG'
			.writeLog()
			.writeLog( REPLICATE('#',80) )
			.writeLog( '---' + PROGRAM() + '----------' )
			.writeLog( 'SourcePath			=' + TRANSFORM(tcSourcePath) )
			.writeLog( 'DestinationPath		=' + TRANSFORM(tcDestinationPath) )
			.writeLog( 'SourceSymbolic		=' + TRANSFORM(tcSourceSymbolic) )
			.writeLog( 'DestinationSymbolic	=' + TRANSFORM(tcDestinationSymbolic) )
			
			IF NOT EMPTY(tcBasePath)
				.writeLog( 'BasePath			=' + TRANSFORM(tcBasePath) )
				.writeLog( 'BaseSymbolic		=' + TRANSFORM(tcBaseSymbolic) )
				.writeLog( 'OutputPath			=' + TRANSFORM(tcOutputPath) )
			ENDIF

			IF NOT .l_Initialized
				LOCAL lcPlasticSCM ;
					, loShell AS WScript.SHELL

				.oShell			= CREATEOBJECT("WScript.Shell")
				.oFSO			= CREATEOBJECT("scripting.filesystemobject")
				.cSys16			= SYS(16)
				.cSys16			= SUBSTR( .cSys16, AT( GETWORDNUM( .cSys16, 2), .cSys16 ) + LEN( GETWORDNUM( .cSys16, 2) ) + 1 )
				.cEXEPath		= JUSTPATH( .cSys16 )
				.lDebug			= ( FILE( FORCEEXT( .cSys16, 'LOG' ) ) )
				.cPlasticPath	= ''
				lcPlasticSCM	= loShell.RegRead('HKEY_CLASSES_ROOT\plastic\shell\open\command\')
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

				.l_Initialized	= .T.
			ENDIF
		ENDWITH && THIS AS CL_SCM_LIB OF 'FOXPRO_PLASTICSCM_DM.PRG'
	ENDPROC


	PROCEDURE P_Diff
		*--------------------------------------------------------------------------------------------------------------
		* PROCESA EL DIFF
		*--------------------------------------------------------------------------------------------------------------
		* PAR�METROS:				(!=Obligatorio | ?=Opcional) (@=Pasar por referencia | v=Pasar por valor) (IN/OUT)
		* toEx						(?@    OUT) Objeto con informaci�n del error
		* tcSourcePath				(!v IN    ) Path del archivo origen
		* tcDestinationPath			(!v IN    ) Path del archivo destino
		* tcSourceSymbolic			(!v IN    ) Ruta simb�lica del archivo origen con informaci�n del changeset, branch o revisi�n
		* tcDestinationSymbolic		(!v IN    ) Ruta simb�lica del archivo destino con informaci�n del changeset, branch o revisi�n
		*--------------------------------------------------------------------------------------------------------------
		LPARAMETERS toEx AS EXCEPTION, tcSourcePath, tcDestinationPath, tcSourceSymbolic, tcDestinationSymbolic

		TRY
			LOCAL lnExitCode AS INTEGER ;
				, loEx AS EXCEPTION ;
				, lcExtension_b, lcExtension_c, lcExtension_2, lcDestinationExtension, llNotInWorkspace ;
				, lcMenError, lcSourceSymbolicFileName, lcDestinationSymbolicFileName, lcWorkspaceFileName

			WITH THIS AS CL_SCM_LIB OF 'FOXPRO_PLASTICSCM_DM.PRG'
				STORE '' TO lcExtension_b, lcExtension_c, lcExtension_2, lcDestinationExtension
				.writeLog( '---' + PROGRAM() + '----------' )
				loEx				= NULL
				tcSourcePath		= STRTRAN( tcSourcePath, '\\', '\' )
				tcDestinationPath	= STRTRAN( tcDestinationPath, '\\', '\' )

				.Initialize( tcSourcePath, tcDestinationPath, tcSourceSymbolic, tcDestinationSymbolic )

				.FindWorkspaceFileName( @lcWorkspaceFileName, tcSourcePath, tcDestinationPath, tcSourceSymbolic, tcDestinationSymbolic )

				lcDestinationExtension	= JUSTEXT(tcDestinationPath)
				llNotInWorkspace 		= .T.

				.GetSecondaryExtensions( lcDestinationExtension, @lcExtension_b, @lcExtension_c, @lcExtension_2 )

				.SourceProcessForDiff( lcDestinationExtension, lcExtension_b, lcExtension_c, tcSourceSymbolic, tcSourcePath, tcDestinationPath, lcWorkspaceFileName )
				llNotInWorkspace	= .DestinationProcessForDiff( lcDestinationExtension, lcExtension_b, lcExtension_c, tcDestinationSymbolic, tcDestinationPath, lcWorkspaceFileName )
				.DiffProcess( lcDestinationExtension, lcExtension_b, lcExtension_c, lcExtension_2, tcSourcePath, tcDestinationPath, llNotInWorkspace )
			ENDWITH && THIS AS CL_SCM_LIB OF 'FOXPRO_PLASTICSCM_DM.PRG'

		CATCH TO toEx WHEN toEx.MESSAGE = '0'
			toEx	= NULL

		CATCH TO toEx
			lcMenError	= 'CurDir: ' + SYS(5)+CURDIR() + CR_LF ;
				+ 'Sys16: ' + SYS(16) + CR_LF ;
				+ 'Error ' + TRANSFORM(toEx.ERRORNO) + ', ' + toEx.MESSAGE + CR_LF ;
				+ toEx.PROCEDURE + ', line ' + TRANSFORM(toEx.LINENO) + CR_LF ;
				+ toEx.LINECONTENTS + CR_LF ;
				+ toEx.USERVALUE
			THIS.writeLog( lcMenError )
			*IF _VFP.StartMode = 0
			MESSAGEBOX( lcMenError, 0+16+4096, "ATENCI�N!!", 60000 )
			*ENDIF

		ENDTRY

		RETURN
	ENDPROC


	PROCEDURE P_Merge
		*--------------------------------------------------------------------------------------------------------------
		* PROCESA EL MERGE
		*--------------------------------------------------------------------------------------------------------------
		* PAR�METROS:				(!=Obligatorio | ?=Opcional) (@=Pasar por referencia | v=Pasar por valor) (IN/OUT)
		* toEx						(?@    OUT) Objeto con informaci�n del error
		* tcSourcePath				(!v IN    ) Path del archivo origen
		* tcDestinationPath			(!v IN    ) Path del archivo destino
		* tcSourceSymbolic			(!v IN    ) Ruta simb�lica del archivo origen con informaci�n del changeset, branch o revisi�n
		* tcDestinationSymbolic		(!v IN    ) Ruta simb�lica del archivo destino con informaci�n del changeset, branch o revisi�n
		* tcBasePath				(!v IN    ) Path del archivo base (base del archivo origen y del destino)
		* tcBaseSymbolic			(!v IN    ) Ruta simb�lica del archivo base con informaci�n del changeset, branch o revisi�n
		* tcOutputPath				(!v IN    ) Path del archivo de salida generado
		*--------------------------------------------------------------------------------------------------------------
		LPARAMETERS toEx AS EXCEPTION, tcSourcePath, tcDestinationPath, tcSourceSymbolic, tcDestinationSymbolic ;
			, tcBasePath, tcBaseSymbolic, tcOutputPath

		TRY
			LOCAL lnExitCode AS INTEGER ;
				, loEx AS EXCEPTION ;
				, lcExtension_b, lcExtension_c, lcExtension_2, lcDestinationExtension ;
				, lcMenError, lcSourceSymbolicFileName, lcDestinationSymbolicFileName, lcWorkspaceFileName ;
				, lcTextMergeResult

			WITH THIS AS CL_SCM_LIB OF 'FOXPRO_PLASTICSCM_DM.PRG'
				STORE '' TO lcExtension_b, lcExtension_c, lcExtension_2, lcDestinationExtension, lcTextMergeResult
				.writeLog( '---' + PROGRAM() + '----------' )
				loEx				= NULL
				tcSourcePath		= STRTRAN( tcSourcePath, '\\', '\' )
				tcDestinationPath	= STRTRAN( tcDestinationPath, '\\', '\' )

				.Initialize( tcSourcePath, tcDestinationPath, tcSourceSymbolic, tcDestinationSymbolic ;
					, tcBasePath, tcBaseSymbolic, tcOutputPath )

				lcDestinationExtension	= JUSTEXT(tcDestinationPath)

				.GetSecondaryExtensions( lcDestinationExtension, @lcExtension_b, @lcExtension_c, @lcExtension_2 )

				.SourceProcess( lcDestinationExtension, lcExtension_b, lcExtension_c, tcSourceSymbolic, tcSourcePath, tcDestinationPath, lcWorkspaceFileName )
				.BaseProcessForMerge( lcDestinationExtension, lcExtension_b, lcExtension_c, tcBaseSymbolic, tcBasePath, lcWorkspaceFileName )
				.DestinationProcessForMerge( lcDestinationExtension, lcExtension_b, lcExtension_c, tcDestinationSymbolic, tcDestinationPath, lcWorkspaceFileName )
				lcTextMergeResult	= .MergeProcess( lcDestinationExtension, lcExtension_b, lcExtension_c, lcExtension_2, tcSourcePath, tcBasePath, tcDestinationPath, tcOutputPath )
				.ConvertToBinaryProcess( lcDestinationExtension, lcExtension_b, lcExtension_c, lcExtension_2, lcTextMergeResult, tcDestinationPath, tcOutputPath )
			ENDWITH && THIS AS CL_SCM_LIB OF 'FOXPRO_PLASTICSCM_DM.PRG'

		CATCH TO toEx WHEN toEx.MESSAGE = '0'
			toEx	= NULL

		CATCH TO toEx
			lcMenError	= 'CurDir: ' + SYS(5)+CURDIR() + CR_LF ;
				+ 'Sys16: ' + SYS(16) + CR_LF ;
				+ 'Error ' + TRANSFORM(toEx.ERRORNO) + ', ' + toEx.MESSAGE + CR_LF ;
				+ toEx.PROCEDURE + ', line ' + TRANSFORM(toEx.LINENO) + CR_LF ;
				+ toEx.LINECONTENTS + CR_LF ;
				+ toEx.USERVALUE
			THIS.writeLog( lcMenError )
			*IF _VFP.StartMode = 0
			MESSAGEBOX( lcMenError, 0+16+4096, "ATENCI�N!!", 60000 )
			*ENDIF

		ENDTRY

		RETURN
	ENDPROC


	FUNCTION SourceProcessForDiff
		*--------------------------------------------------------------------------------------------------------------
		* PROCESO DEL ARCHIVO ORIGEN PARA EL DIFF
		*--------------------------------------------------------------------------------------------------------------
		* PAR�METROS:				(!=Obligatorio | ?=Opcional) (@=Pasar por referencia | v=Pasar por valor) (IN/OUT)
		* tcDestinationExtension	(!v IN    ) Extensi�n de destino
		* tcExtension_b				(!v IN    ) Extensi�n secundaria (PJT,VCT,SCT,FRT,LBT,MNT,FPT,DCT,...)
		* tcExtension_c				(!v IN    ) Extensi�n terciaria (CDX,DCX,...)
		* tcSourceSymbolic			(!v IN    ) Ruta simb�lica del archivo origen con informaci�n del changeset, branch o revisi�n
		* tcSourcePath				(!v IN    ) Path del archivo origen
		* tcDestinationPath			(!v IN    ) Path del archivo destino
		* tcWorkspaceFileName		(!v IN    ) Nombre del archivo en el workspace (inferido de los par�metros de entrada)
		*--------------------------------------------------------------------------------------------------------------
		LPARAMETERS tcDestinationExtension, tcExtension_b, tcExtension_c, tcSourceSymbolic, tcSourcePath ;
			, tcDestinationPath, tcWorkspaceFileName

		#IF .F.
			LOCAL THIS AS CL_SCM_LIB OF 'FOXPRO_PLASTICSCM_DM.PRG'
		#ENDIF

		TRY
			LOCAL lcSourceSymbolicExtensionReplaced, lcSourceSpecForCatCommand, lcSourcePathExtensionReplaced ;
				, laSourceSymbolicExtensionReplaced_Splited(1), lcCommand, lnCommandResult, lcSourcePathParsed

			WITH THIS AS CL_SCM_LIB OF 'FOXPRO_PLASTICSCM_DM.PRG'
				.writeLog( '---' + PROGRAM() + '----------' )
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
				* Ejemplo 1:	"C:\Program Files\PlasticSCM5\client\cm.exe" cat "c:\DESA\foxbin2prg\foxbin2prg.pjt" --file="C:\Temp\ff3bd392-3464-47d1-b096-734a08d46fd9.pjt"
				*-------------------------------------------------------------------------------
				lcCommand			= .cCM + ' cat ' + lcSourceSpecForCatCommand + ' --file="' + lcSourcePathExtensionReplaced + '"'
				lnCommandResult		= .RunCommand( lcCommand )

				IF (lnCommandResult == 1)
					ERROR "There was an error performing the diff operation."
				ENDIF

				lcSourcePathParsed	= ' "' + tcSourcePath + '" "0" "0" "0" "0" "0" "0" "' + tcWorkspaceFileName + '"'
				lcCommand			= '"' + FORCEPATH( 'foxbin2prg.exe', .cEXEPath ) + '"' + lcSourcePathParsed
				lnCommandResult		= .RunCommand( lcCommand )

				IF (lnCommandResult == 1)
					ERROR "Foxbin2prg devolvi� un error"
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


	FUNCTION SourceProcessForMerge
		*--------------------------------------------------------------------------------------------------------------
		* PROCESO DEL ARCHIVO ORIGEN PARA EL MERGE
		*--------------------------------------------------------------------------------------------------------------
		* PAR�METROS:				(!=Obligatorio | ?=Opcional) (@=Pasar por referencia | v=Pasar por valor) (IN/OUT)
		* tcDestinationExtension	(!v IN    ) Extensi�n de destino
		* tcExtension_b				(!v IN    ) Extensi�n secundaria (PJT,VCT,SCT,FRT,LBT,MNT,FPT,DCT,...)
		* tcExtension_c				(!v IN    ) Extensi�n terciaria (CDX,DCX,...)
		* tcSourceSymbolic			(!v IN    ) Ruta simb�lica del archivo origen con informaci�n del changeset, branch o revisi�n
		* tcSourcePath				(!v IN    ) Path del archivo origen
		* tcDestinationPath			(!v IN    ) Path del archivo destino
		* tcWorkspaceFileName		(!v IN    ) Nombre del archivo en el workspace (inferido de los par�metros de entrada)
		*--------------------------------------------------------------------------------------------------------------
		LPARAMETERS tcDestinationExtension, tcExtension_b, tcExtension_c, tcSourceSymbolic, tcSourcePath ;
			, tcDestinationPath, tcWorkspaceFileName

		#IF .F.
			LOCAL THIS AS CL_SCM_LIB OF 'FOXPRO_PLASTICSCM_DM.PRG'
		#ENDIF

		TRY
			LOCAL lcSourceSymbolicExtensionReplaced, lcSourceSpecForCatCommand, lcSourcePathExtensionReplaced ;
				, laSourceSymbolicExtensionReplaced_Splited(1), lcCommand, lnCommandResult, lcSourcePathParsed

			WITH THIS AS CL_SCM_LIB OF 'FOXPRO_PLASTICSCM_DM.PRG'
				.writeLog( '---' + PROGRAM() + '----------' )
				lnCommandResult		= 0
				lcSourceSymbolicExtensionReplaced	= FORCEEXT( tcSourceSymbolic, tcExtension_b )

				*-------------------------------------------------------------------------------
				* Ejemplo:	sourcesymbolic="c:\DESA\foxbin2prg\foxbin2prg.pjt#/main/v1.15p1#cs:62"
				*-------------------------------------------------------------------------------
				ALINES( laSourceSymbolicExtensionReplaced_Splited, lcSourceSymbolicExtensionReplaced, 4, '#')
				lcSourceSpecForCatCommand	= '"' + laSourceSymbolicExtensionReplaced_Splited[1] + '#' ;
					+ laSourceSymbolicExtensionReplaced_Splited[3] + '"'

				lcSourcePathExtensionReplaced	= FORCEEXT( tcSourcePath, tcExtension_b )

				*-------------------------------------------------------------------------------
				* Ejemplo:	lcCommand="C:\Program Files\PlasticSCM5\client\cm.exe" cat "c:\DESA\foxbin2prg\foxbin2prg.pjt" --file="C:\Temp\ff3bd392-3464-47d1-b096-734a08d46fd9.pjt"
				*-------------------------------------------------------------------------------
				lcCommand			= .cCM + ' cat ' + lcSourceSpecForCatCommand + ' --file="' + lcSourcePathExtensionReplaced + '"'
				lnCommandResult		= .RunCommand( lcCommand )

				IF (lnCommandResult == 1)
					ERROR "There was an error performing the merge operation."
				ENDIF

				lcSourcePathParsed	= ' "' + tcSourcePath + '" "0" "0" "0" "0" "0" "0" "' + tcWorkspaceFileName + '"'
				lcCommand			= '"' + FORCEPATH( 'foxbin2prg.exe', .cEXEPath ) + '"' + lcSourcePathParsed
				lnCommandResult		= .RunCommand( lcCommand )

				IF (lnCommandResult == 1)
					ERROR "Foxbin2prg devolvi� un error"
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


	FUNCTION BaseProcessForMerge
		*--------------------------------------------------------------------------------------------------------------
		* PROCESO DEL ARCHIVO BASE PARA EL MERGE
		*--------------------------------------------------------------------------------------------------------------
		* PAR�METROS:				(!=Obligatorio | ?=Opcional) (@=Pasar por referencia | v=Pasar por valor) (IN/OUT)
		* tcDestinationExtension	(!v IN    ) Extensi�n de destino
		* tcExtension_b				(!v IN    ) Extensi�n secundaria (PJT,VCT,SCT,FRT,LBT,MNT,FPT,DCT,...)
		* tcExtension_c				(!v IN    ) Extensi�n terciaria (CDX,DCX,...)
		* tcBaseSymbolic			(!v IN    ) Ruta simb�lica del archivo base con informaci�n del changeset, branch o revisi�n
		* tcBasePath				(!v IN    ) Path del archivo base
		* tcWorkspaceFileName		(!v IN    ) Nombre del archivo en el workspace (inferido de los par�metros de entrada)
		*--------------------------------------------------------------------------------------------------------------
		LPARAMETERS tcDestinationExtension, tcExtension_b, tcExtension_c, tcBaseSymbolic, tcBasePath, tcWorkspaceFileName

		#IF .F.
			LOCAL THIS AS CL_SCM_LIB OF 'FOXPRO_PLASTICSCM_DM.PRG'
		#ENDIF

		TRY
			LOCAL lcBaseSymbolicExtensionReplaced, lcBaseSpecForCatCommand, lcBasePathExtensionReplaced ;
				, laBaseSymbolicExtensionReplaced_Splited(1), lcCommand, lnCommandResult, lcBasePathParsed

			WITH THIS AS CL_SCM_LIB OF 'FOXPRO_PLASTICSCM_DM.PRG'
				.writeLog( '---' + PROGRAM() + '----------' )
				lnCommandResult		= 0
				lcBaseSymbolicExtensionReplaced	= FORCEEXT( tcBaseSymbolic, tcExtension_b )

				*-------------------------------------------------------------------------------
				* Ejemplo:	basesymbolic="c:\DESA\foxbin2prg\foxbin2prg.pjt#/main/v1.15p1#cs:62"
				*-------------------------------------------------------------------------------
				ALINES( laBaseSymbolicExtensionReplaced_Splited, lcBaseSymbolicExtensionReplaced, 4, '#')
				lcBaseSpecForCatCommand	= '"' + laBaseSymbolicExtensionReplaced_Splited[1] + '#' ;
					+ laBaseSymbolicExtensionReplaced_Splited[3] + '"'

				lcBasePathExtensionReplaced	= FORCEEXT( tcBasePath, tcExtension_b )

				*-------------------------------------------------------------------------------
				* Ejemplo:	lcCommand="C:\Program Files\PlasticSCM5\client\cm.exe" cat "c:\DESA\foxbin2prg\foxbin2prg.pjt" --file="C:\Temp\ff3bd392-3464-47d1-b096-734a08d46fd9.pjt"
				*-------------------------------------------------------------------------------
				lcCommand			= .cCM + ' cat ' + lcBaseSpecForCatCommand + ' --file="' + lcBasePathExtensionReplaced + '"'
				lnCommandResult		= .RunCommand( lcCommand )

				IF (lnCommandResult == 1)
					ERROR "There was an error performing the merge operation."
				ENDIF

				lcBasePathParsed	= ' "' + tcBasePath + '" "0" "0" "0" "0" "0" "0" "' + tcWorkspaceFileName + '"'
				lcCommand			= '"' + FORCEPATH( 'foxbin2prg.exe', .cEXEPath ) + '"' + lcBasePathParsed
				lnCommandResult		= .RunCommand( lcCommand )

				IF (lnCommandResult == 1)
					ERROR "Foxbin2prg devolvi� un error"
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


	FUNCTION DestinationProcessForDiff
		*--------------------------------------------------------------------------------------------------------------
		* PROCESO DEL ARCHIVO DESTINO PARA EL DIFF
		*--------------------------------------------------------------------------------------------------------------
		* PAR�METROS:				(!=Obligatorio | ?=Opcional) (@=Pasar por referencia | v=Pasar por valor) (IN/OUT)
		* tcDestinationExtension	(!v IN    ) Extensi�n de destino
		* tcExtension_b				(!v IN    ) Extensi�n secundaria (PJT,VCT,SCT,FRT,LBT,MNT,FPT,DCT,...)
		* tcExtension_c				(!v IN    ) Extensi�n terciaria (CDX,DCX,...)
		* tcDestinationSymbolic		(!v IN    ) Ruta simb�lica del archivo destino con informaci�n del changeset, branch o revisi�n
		* tcDestinationPath			(!v IN    ) Path del archivo destino
		* tcWorkspaceFileName		(!v IN    ) Nombre del archivo en el workspace (inferido de los par�metros de entrada)
		*--------------------------------------------------------------------------------------------------------------
		LPARAMETERS tcDestinationExtension, tcExtension_b, tcExtension_c, tcDestinationSymbolic ;
			, tcDestinationPath, tcWorkspaceFileName

		#IF .F.
			LOCAL THIS AS CL_SCM_LIB OF 'FOXPRO_PLASTICSCM_DM.PRG'
		#ENDIF

		TRY
			LOCAL lcDestinationSymbolicExtensionReplaced, lcDestinationSpecForCatCommand, lcDestinationPathExtensionReplaced ;
				, laDestinationSymbolicExtensionReplaced_Splited(1), lcCommand, lnCommandResult, lcDestinationPathParsed ;
				, llNotInWorkspace

			WITH THIS AS CL_SCM_LIB OF 'FOXPRO_PLASTICSCM_DM.PRG'
				.writeLog( '---' + PROGRAM() + '----------' )
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
					ENDIF

					lcDestinationPathParsed	= ' "' + tcDestinationPath + '" "0" "0" "0" "0" "0" "0" "' + tcWorkspaceFileName + '"'
					lcCommand				= '"' + FORCEPATH( 'foxbin2prg.exe', .cEXEPath ) + '"' + lcDestinationPathParsed
					lnCommandResult		= .RunCommand( lcCommand )

					IF (lnCommandResult == 1)
						ERROR "Foxbin2prg devolvi� un error"
					ENDIF

					llNotInWorkspace	= .T.

				ELSE
					lcDestinationPathParsed	= ' "' + tcDestinationPath + '" "0" "0" "0" "0" "0" "0" "' + tcWorkspaceFileName + '"'
					lcCommand			= '"' + FORCEPATH( 'foxbin2prg.exe', .cEXEPath ) + '"' + lcDestinationPathParsed
					lnCommandResult		= .RunCommand( lcCommand )

					IF (lnCommandResult == 1)
						ERROR "Foxbin2prg devolvi� un error"
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


	FUNCTION DestinationProcessForMerge
		*--------------------------------------------------------------------------------------------------------------
		* PROCESO DEL ARCHIVO DESTINO PARA EL MERGE
		*--------------------------------------------------------------------------------------------------------------
		* PAR�METROS:				(!=Obligatorio | ?=Opcional) (@=Pasar por referencia | v=Pasar por valor) (IN/OUT)
		* tcDestinationExtension	(!v IN    ) Extensi�n de destino
		* tcExtension_b				(!v IN    ) Extensi�n secundaria (PJT,VCT,SCT,FRT,LBT,MNT,FPT,DCT,...)
		* tcExtension_c				(!v IN    ) Extensi�n terciaria (CDX,DCX,...)
		* tcDestinationSymbolic		(!v IN    ) Ruta simb�lica del archivo destino con informaci�n del changeset, branch o revisi�n
		* tcDestinationPath			(!v IN    ) Path del archivo destino
		* tcWorkspaceFileName		(!v IN    ) Nombre del archivo en el workspace (inferido de los par�metros de entrada)
		*--------------------------------------------------------------------------------------------------------------
		LPARAMETERS tcDestinationExtension, tcExtension_b, tcExtension_c, tcDestinationSymbolic, tcDestinationPath, tcWorkspaceFileName

		#IF .F.
			LOCAL THIS AS CL_SCM_LIB OF 'FOXPRO_PLASTICSCM_DM.PRG'
		#ENDIF

		TRY
			LOCAL lcCommand, lnCommandResult, lcDestinationPathParsed

			WITH THIS AS CL_SCM_LIB OF 'FOXPRO_PLASTICSCM_DM.PRG'
				.writeLog( '---' + PROGRAM() + '----------' )
				lnCommandResult		= 0

				lcDestinationPathParsed	= ' "' + tcDestinationPath + '" "0" "0" "0" "0" "0" "0" "' + tcWorkspaceFileName + '"'
				lcCommand			= '"' + FORCEPATH( 'foxbin2prg.exe', .cEXEPath ) + '"' + lcDestinationPathParsed
				lnCommandResult		= .RunCommand( lcCommand )

				IF (lnCommandResult == 1)
					ERROR "Foxbin2prg devolvi� un error"
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


	FUNCTION DiffProcess
		*--------------------------------------------------------------------------------------------------------------
		* PROCESO DE DIFF
		*--------------------------------------------------------------------------------------------------------------
		* PAR�METROS:				(!=Obligatorio | ?=Opcional) (@=Pasar por referencia | v=Pasar por valor) (IN/OUT)
		* tcDestinationExtension	(!v IN    ) Extensi�n de destino
		* tcExtension_b				(!v IN    ) Extensi�n secundaria (PJT,VCT,SCT,FRT,LBT,MNT,FPT,DCT,...)
		* tcExtension_c				(!v IN    ) Extensi�n terciaria (CDX,DCX,...)
		* tcExtension_2				(!v IN    ) Extensi�n Texto (PJ2,VC2,SC2,FR2,LB2,MN2,DB2,DC2,...)
		* tcSourcePath				(!v IN    ) Path del archivo origen
		* tcDestinationPath			(!v IN    ) Path del archivo destino
		* tlNotInWorkspace			(!v IN    ) Indica si el archivo exist�a en el Workspace o no (si es una revisi�n, no existe)
		*--------------------------------------------------------------------------------------------------------------
		LPARAMETERS tcDestinationExtension, tcExtension_b, tcExtension_c, tcExtension_2, tcSourcePath, tcDestinationPath, tlNotInWorkspace

		#IF .F.
			LOCAL THIS AS CL_SCM_LIB OF 'FOXPRO_PLASTICSCM_DM.PRG'
		#ENDIF

		TRY
			LOCAL laDestinationSymbolicExtensionReplaced_Splited(1), lcCommand, lnCommandResult ;
				, lcConvertToTextSource, lcConvertToTextDestination, lcArguments

			WITH THIS AS CL_SCM_LIB OF 'FOXPRO_PLASTICSCM_DM.PRG'
				.writeLog( '---' + PROGRAM() + '----------' )
				lnCommandResult				= 0
				lcConvertToTextSource		= '"' + FORCEEXT( tcSourcePath, tcExtension_2 ) + '"'
				lcConvertToTextDestination	= '"' + FORCEEXT( tcDestinationPath, tcExtension_2 ) + '"'

				*-- Verifico si existe antes, porque puede que haya ocurrido un error (.ERR)
				IF FILE(lcConvertToTextSource) AND FILE( lcConvertToTextDestination )
					lcArguments			= " -s=" + lcConvertToTextSource + " -d=" + lcConvertToTextDestination
					lcCommand			= '"' + FORCEPATH( 'mergetool.exe', .cPlasticPath ) + '"' + lcArguments
					lnCommandResult		= .RunCommand( lcCommand )

					IF (lnCommandResult == 1)
						ERROR "mergetool devolvi� un error"
					ENDIF
				ELSE	&& Ocurri� un error
					.writeLog( 'No existe el archivo [' + lcConvertToTextSource + '] o [' +lcConvertToTextDestination  + ']' )
					DO CASE
					CASE FILE( '"' + tcSourcePath + '.ERR"' )
						lcCommand			= 'notepad.exe "' + tcSourcePath + '.ERR"'

					CASE FILE( '"' + tcDestinationPath + '.ERR"' )
						lcCommand			= 'notepad.exe "' + '"' + tcDestinationPath + '.ERR"'

					OTHERWISE
						.writeLog( 'No existen los archivos ["' + tcSourcePath + '.ERR' ;
							+ '"] y ["' + tcDestinationPath + '"]' )
					ENDCASE

					lnCommandResult		= .RunCommand( lcCommand, 1 )
					ERROR 'No existe alguno de los archivos Texto que dab�an generarse'
				ENDIF

				.DeleteFile( lcConvertToTextSource )
				.DeleteFile( '"' + FORCEEXT( tcSourcePath, tcExtension_b ) + '"' )
				.DeleteFile( tcSourcePath )

				IF tlNotInWorkspace
					.DeleteFile( lcConvertToTextDestination )
					.DeleteFile( '"' + FORCEEXT( tcDestinationPath, tcExtension_b ) + '"' )
					.DeleteFile( tcDestinationPath )
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


	FUNCTION MergeProcess
		*--------------------------------------------------------------------------------------------------------------
		* PROCESO DE MERGE
		*--------------------------------------------------------------------------------------------------------------
		* PAR�METROS:				(!=Obligatorio | ?=Opcional) (@=Pasar por referencia | v=Pasar por valor) (IN/OUT)
		* tcDestinationExtension	(!v IN    ) Extensi�n de destino
		* tcExtension_b				(!v IN    ) Extensi�n secundaria (PJT,VCT,SCT,FRT,LBT,MNT,FPT,DCT,...)
		* tcExtension_c				(!v IN    ) Extensi�n terciaria (CDX,DCX,...)
		* tcExtension_2				(!v IN    ) Extensi�n Texto (PJ2,VC2,SC2,FR2,LB2,MN2,DB2,DC2,...)
		* tcBasePath				(!v IN    ) Path del archivo base
		* tcDestinationPath			(!v IN    ) Path del archivo destino
		* tcOutputPath				(!v IN    ) Path del archivo de salida
		*--------------------------------------------------------------------------------------------------------------
		LPARAMETERS tcDestinationExtension, tcExtension_b, tcExtension_c, tcExtension_2, tcSourcePath, tcBasePath, tcDestinationPath, tcOutputPath

		#IF .F.
			LOCAL THIS AS CL_SCM_LIB OF 'FOXPRO_PLASTICSCM_DM.PRG'
		#ENDIF

		TRY
			LOCAL laDestinationSymbolicExtensionReplaced_Splited(1), lcCommand, lnCommandResult ;
				, lcConvertToTextSource, lcConvertToTextBase, lcConvertToTextDestination, lcArguments ;
				, ltTimePreMerge, ltTimePostMerge, laFileInfo(1,5)

			WITH THIS AS CL_SCM_LIB OF 'FOXPRO_PLASTICSCM_DM.PRG'
				.writeLog( '---' + PROGRAM() + '----------' )
				lnCommandResult				= 0
				lcConvertToTextSource		= '"' + FORCEEXT( tcSourcePath, tcExtension_2 ) + '"'
				lcConvertToTextBase			= '"' + FORCEEXT( tcBasePath, tcExtension_2 ) + '"'
				lcConvertToTextDestination	= '"' + FORCEEXT( tcDestinationPath, tcExtension_2 ) + '"'

				ADIR( laFileInfo, tcDestinationPath )
				ltTimePreMerge	= EVALUATE( '{^' + DTOC(laFileInfo(1,3)) + ' ' + TIME() + '}' )

				*-- Verifico si existe antes, porque puede que haya ocurrido un error (.ERR)
				IF FILE(lcConvertToTextSource) AND FILE(lcConvertToTextBase) AND FILE(lcConvertToTextDestination)
					lcArguments			= " -s=" + lcConvertToTextSource + " -b=" + lcConvertToTextBase ;
						+ " -d=" + lcConvertToTextDestination + " -r=" + lcConvertToTextDestination
					lcCommand			= '"' + FORCEPATH( 'mergetool.exe', .cPlasticPath ) + '"' + lcArguments
					lnCommandResult		= .RunCommand( lcCommand )

					IF (lnCommandResult == 1)
						ERROR "mergetool devolvi� un error"
					ENDIF

					ADIR( laFileInfo, tcDestinationPath )
					ltTimePostMerge	= EVALUATE( '{^' + DTOC(laFileInfo(1,3)) + ' ' + TIME() + '}' )

					*-- Borrar Source
					.DeleteFile( lcConvertToTextSource )
					.DeleteFile( '"' + FORCEEXT( tcSourcePath, tcExtension_b ) + '"' )
					IF NOT EMPTY(tcExtension_c)
						.DeleteFile( '"' + FORCEEXT( tcSourcePath, tcExtension_c ) + '"' )
					ENDIF
					*-- Borrar Base
					.DeleteFile( lcConvertToTextBase )
					.DeleteFile( '"' + FORCEEXT( tcBasePath, tcExtension_b ) + '"' )
					IF NOT EMPTY(tcExtension_c)
						.DeleteFile( '"' + FORCEEXT( tcBasePath, tcExtension_c ) + '"' )
					ENDIF

					* Check if the text merge has been succesfully performed
					IF ltTimePreMerge == ltTimePostMerge
						.DeleteFile( lcConvertToTextDestination )
						ERROR '0'
					ENDIF

				ELSE	&& Ocurri� un error
					.writeLog( 'No existe el archivo [' + lcConvertToTextSource + '] o [' +lcConvertToTextBase ;
						+ '] o [' +lcConvertToTextDestination + ']' )
					DO CASE
					CASE FILE( '"' + tcSourcePath + '.ERR"' )
						lcCommand			= 'notepad.exe "' + tcSourcePath + '.ERR"'

					CASE FILE( '"' + tcBasePath + '.ERR"' )
						lcCommand			= 'notepad.exe "' + tcBasePath + '.ERR"'

					CASE FILE( '"' + tcDestinationPath + '.ERR"' )
						lcCommand			= 'notepad.exe "' + '"' + tcDestinationPath + '.ERR"'

					OTHERWISE
						.writeLog( 'No existen los archivos ["' + tcSourcePath + '.ERR' ;
							+ '"] y ["' + tcDestinationPath + '"]' )
					ENDCASE

					lnCommandResult		= .RunCommand( lcCommand, 1 )
					ERROR 'No existe alguno de los archivos Texto que dab�an generarse'
				ENDIF

			ENDWITH &&	THIS AS CL_SCM_LIB OF 'FOXPRO_PLASTICSCM_DM.PRG'

		CATCH TO loEx
			IF _VFP.STARTMODE = 0 AND THIS.lDebug
				SET STEP ON
			ENDIF
			THROW
		ENDTRY

		RETURN lcConvertToTextDestination
	ENDFUNC


	PROCEDURE ConvertToBinaryProcess
		*--------------------------------------------------------------------------------------------------------------
		* PROCESO DE MERGE
		*--------------------------------------------------------------------------------------------------------------
		* PAR�METROS:				(!=Obligatorio | ?=Opcional) (@=Pasar por referencia | v=Pasar por valor) (IN/OUT)
		* tcDestinationExtension	(!v IN    ) Extensi�n de destino
		* tcExtension_b				(!v IN    ) Extensi�n secundaria (PJT,VCT,SCT,FRT,LBT,MNT,FPT,DCT,...)
		* tcExtension_c				(!v IN    ) Extensi�n terciaria (CDX,DCX,...)
		* tcExtension_2				(!v IN    ) Extensi�n Texto (PJ2,VC2,SC2,FR2,LB2,MN2,DB2,DC2,...)
		* tcTextMergeResult			(!v IN    ) Path del archivo MERGE resultante (en el TEMP)
		* tcDestinationPath			(!v IN    ) Path del archivo destino (en el Workspace)
		* tcOutputPath				(!v IN    ) Path del archivo de salida (en el TEMP)
		*--------------------------------------------------------------------------------------------------------------
		LPARAMETERS tcDestinationExtension, tcExtension_b, tcExtension_c, tcExtension_2, tcTextMergeResult, tcDestinationPath, tcOutputPath

		#IF .F.
			LOCAL THIS AS CL_SCM_LIB OF 'FOXPRO_PLASTICSCM_DM.PRG'
		#ENDIF

		TRY
			LOCAL lcDestinationPath_b, lcDestinationPath_c, lcCommand, lnCommandResult, lcBinarytMergeResult ;
				, loEx as Exception

			lcDestinationPath_b	= '"' + FORCEEXT( tcDestinationPath, tcExtension_b ) + '"'
			lcDestinationPath_c	= '"' + FORCEEXT( tcDestinationPath, tcExtension_c ) + '"'

			WITH THIS AS CL_SCM_LIB OF 'FOXPRO_PLASTICSCM_DM.PRG'
				.writeLog( '---' + PROGRAM() + '----------' )
				.ChangeFileAttribute( tcDestinationPath, '-R' )
				.ChangeFileAttribute( tcDestinationPath_b, '-R' )
				.ChangeFileAttribute( tcDestinationPath_c, '-R' )
				.DeleteFile(tcDestinationPath)
				.DeleteFile(tcDestinationPath_b)
				.DeleteFile(tcDestinationPath_c)

				*-- Regenera el BIN (PJX,VCX,SCX,etc)
				lcCommand			= '"' + FORCEPATH( 'foxbin2prg.exe', .cEXEPath ) + '"' + tcTextMergeResult
				lnCommandResult		= .RunCommand( lcCommand )

				IF (lnCommandResult == 1)
					ERROR "Foxbin2prg devolvi� un error"
				ENDIF
				
				* Restore file names using the initial format
				*(ver lo de la capitalizaci�n de tcDestinationPath con RENAME, para Extensi�n, ExtB y ExtC)
				
				
				* Overwrite the temporal output file to finish the merge operation
				lcBinarytMergeResult	= STRTRAN( tcTextMergeResult, '.' + tcExtension_2, '.' + tcDestinationExtension )
				.DeleteFile( tcOutputPath )
				.MoveFile( lcBinarytMergeResult, tcOutputPath )
				

			ENDWITH &&	THIS AS CL_SCM_LIB OF 'FOXPRO_PLASTICSCM_DM.PRG'

		CATCH TO loEx
			IF _VFP.STARTMODE = 0 AND THIS.lDebug
				SET STEP ON
			ENDIF
			THROW
		ENDTRY
	ENDPROC


	PROCEDURE FindWorkspaceFileName
		*--------------------------------------------------------------------------------------------------------------
		* BUSCA EL NOMBRE DEL ARCHIVO DEL WORKSPACE
		*--------------------------------------------------------------------------------------------------------------
		* PAR�METROS:				(!=Obligatorio | ?=Opcional) (@=Pasar por referencia | v=Pasar por valor) (IN/OUT)
		* tcWorkspaceFileName		(!@    OUT) Nombre del archivo del workspace encontrado
		* tcSourcePath				(!v IN    ) Path del archivo origen
		* tcDestinationPath			(!v IN    ) Path del archivo destino
		* tcSourceSymbolic			(!v IN    ) Ruta simb�lica del archivo origen con informaci�n del changeset, branch o revisi�n
		* tcDestinationSymbolic		(!v IN    ) Ruta simb�lica del archivo destino con informaci�n del changeset, branch o revisi�n
		*--------------------------------------------------------------------------------------------------------------
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


	PROCEDURE GetSecondaryExtensions
		*--------------------------------------------------------------------------------------------------------------
		* OBTENER LAS EXTENSIONES SECUNDARIAS Y DE TEXTO DE LA PRINCIPAL INDICADA
		*--------------------------------------------------------------------------------------------------------------
		* PAR�METROS:				(!=Obligatorio | ?=Opcional) (@=Pasar por referencia | v=Pasar por valor) (IN/OUT)
		* tcPrimaryExtension		(!v IN    ) Extensi�n principal del archivo destino
		* tcExtension_b				(?@    OUT) Extensi�n secundaria del archivo
		* tcExtension_c				(?@    OUT) Extensi�n terciaria del archivo
		* tcExtension_2				(?@    OUT) Extensi�n de la versi�n Texto
		*--------------------------------------------------------------------------------------------------------------
		LPARAMETERS tcPrimaryExtension, tcExtension_b, tcExtension_c, tcExtension_2
		STORE '' TO tcExtension_b, tcExtension_c, tcExtension_2

		DO CASE
		CASE tcDestinationExtension = "pjx"
			tcExtension_b	= "pjt"
			tcExtension_2	= "pj2"

		CASE tcDestinationExtension = "vcx"
			tcExtension_b	= "vct"
			tcExtension_2	= "vc2"

		CASE tcDestinationExtension = "scx"
			tcExtension_b	= "sct"
			tcExtension_2	= "sc2"

		CASE tcDestinationExtension = "frx"
			tcExtension_b	= "frt"
			tcExtension_2	= "fr2"

		CASE tcDestinationExtension = "lbx"
			tcExtension_b	= "lbt"
			tcExtension_2	= "lb2"

		CASE tcDestinationExtension = "dbf"
			tcExtension_b	= "fpt"
			tcExtension_c	= "cdx"	&& Ver como tratar esto cuando hay, o no, un CDX.
			tcExtension_2	= "db2"

		CASE tcDestinationExtension = "dbc"
			tcExtension_b	= "dct"
			tcExtension_c	= "dcx"
			tcExtension_2	= "dc2"

		OTHERWISE
			ERROR 'Extensi�n [' + TRANSFORM(tcDestinationExtension) + '] no soportada!'

		ENDCASE
	ENDPROC


	PROCEDURE DeleteFile
		*--------------------------------------------------------------------------------------------------------------
		* BORRA EL ARCHIVO INDICADO
		*--------------------------------------------------------------------------------------------------------------
		* PAR�METROS:				(!=Obligatorio | ?=Opcional) (@=Pasar por referencia | v=Pasar por valor) (IN/OUT)
		* tcFile					(!v IN    ) Archivo a borrar
		*--------------------------------------------------------------------------------------------------------------
		LPARAMETERS tcFile
		THIS.writeLog( 'ERASE ' + tcFile )
		ERASE ( tcFile )
	ENDPROC


	FUNCTION MoveFile
		*--------------------------------------------------------------------------------------------------------------
		* MUEVE O RENOMBRA UN ARCHIVO
		*--------------------------------------------------------------------------------------------------------------
		* PAR�METROS:				(!=Obligatorio | ?=Opcional) (@=Pasar por referencia | v=Pasar por valor) (IN/OUT)
		* tcOrigFileName			(!v IN    ) Nombre del archivo origen
		* tcDestFileName			(!v IN    ) Nombre del archivo destino
		*--------------------------------------------------------------------------------------------------------------
		LPARAMETERS tcOrigFileName, tcDestFileName
		LOCAL loFSO AS Scripting.FileSystemObject
		loFSO = THIS.oFSO
		THIS.writeLog( 'RENAME ' + tcOrigFileName + ' TO ' + tcDestFileName )
		RETURN loFSO.MoveFile( tcOrigFileName, tcDestFileName )
	ENDFUNC


	FUNCTION CopyFile
		*--------------------------------------------------------------------------------------------------------------
		* COPYA UN ARCHIVO
		*--------------------------------------------------------------------------------------------------------------
		* PAR�METROS:				(!=Obligatorio | ?=Opcional) (@=Pasar por referencia | v=Pasar por valor) (IN/OUT)
		* tcOrigFileName			(!v IN    ) Nombre del archivo origen
		* tcDestFileName			(!v IN    ) Nombre del archivo destino
		*--------------------------------------------------------------------------------------------------------------
		LPARAMETERS tcOrigFileName, tcDestFileName
		LOCAL loFSO AS Scripting.FileSystemObject
		loFSO = THIS.oFSO
		THIS.writeLog( 'COPY ' + tcOrigFileName + ' TO ' + tcDestFileName )
		RETURN loFSO.CopyFile( tcOrigFileName, tcDestFileName, .T. )
	ENDFUNC


	FUNCTION RunCommand
		*--------------------------------------------------------------------------------------------------------------
		* EJECUTAR UN COMANDO
		*--------------------------------------------------------------------------------------------------------------
		* PAR�METROS:				(!=Obligatorio | ?=Opcional) (@=Pasar por referencia | v=Pasar por valor) (IN/OUT)
		* tcCommand					(!v IN    ) Comando a ejecutar
		* tnWindowType				(!v IN    ) Tipo de ventana (0=Oculta, 1=Normal, etc)
		*--------------------------------------------------------------------------------------------------------------
		LPARAMETERS tcCommand, tnWindowType

		LOCAL lnCommandResult
		tnWindowType		= EVL(tnWindowType,0)
		THIS.writeLog( tcCommand )
		lnCommandResult		= THIS.oShell.RUN( tcCommand, tnWindowType, .T. )
		THIS.writeLog( '	=> retorn� ' + TRANSFORM(lnCommandResult) )

		RETURN lnCommandResult
	ENDFUNC


	FUNCTION writeLog
		*--------------------------------------------------------------------------------------------------------------
		* ESCRIBIR LOG
		*--------------------------------------------------------------------------------------------------------------
		* PAR�METROS:				(!=Obligatorio | ?=Opcional) (@=Pasar por referencia | v=Pasar por valor) (IN/OUT)
		* tcText					(!v IN    ) Texto a loguear
		* tnAppend					(!v IN    ) Indica si se debe agregar al final del log anterior (1) o en l�nea aparte (0)
		*--------------------------------------------------------------------------------------------------------------
		LPARAMETERS tcText, tnAppend

		#IF .F.
			LOCAL THIS AS CL_SCM_LIB OF 'FOXPRO_PLASTICSCM_DM.PRG'
		#ENDIF

		IF THIS.lDebug
			TRY
				tcText	= EVL(tcText,'')
				IF EVL(tnAppend,0) = 0
					tcText	= CR_LF + tcText
				ENDIF
				THIS.cTextLog	= THIS.cTextLog + tcText
			CATCH
			ENDTRY
		ENDIF

		RETURN
	ENDFUNC


	PROCEDURE ChangeFileAttribute
		* Using Win32 Functions in Visual FoxPro
		* example=103
		* Changing file attributes
		LPARAMETERS  tcFileName, tcAttrib
		tcAttrib	= UPPER(tcAttrib)

		#DEFINE FILE_ATTRIBUTE_READONLY		1
		#DEFINE FILE_ATTRIBUTE_HIDDEN		2
		#DEFINE FILE_ATTRIBUTE_SYSTEM		4
		#DEFINE FILE_ATTRIBUTE_DIRECTORY	16
		#DEFINE FILE_ATTRIBUTE_ARCHIVE		32
		#DEFINE FILE_ATTRIBUTE_NORMAL		128
		#DEFINE FILE_ATTRIBUTE_TEMPORARY	512
		#DEFINE FILE_ATTRIBUTE_COMPRESSED	2048

		DECLARE SHORT SetFileAttributes IN kernel32;
			STRING tcFileName, INTEGER dwFileAttributes

		DECLARE INTEGER GetFileAttributes IN kernel32 STRING tcFileName

		* read current attributes for this file
		dwFileAttributes = GetFileAttributes(tcFileName)

		IF dwFileAttributes = -1
			* the file does not exist
			RETURN
		ENDIF

		IF dwFileAttributes > 0
			IF '+R' $ tcAttrib
				dwFileAttributes = BITOR(dwFileAttributes, FILE_ATTRIBUTE_READONLY)
			ENDIF
			IF '+A' $ tcAttrib
				dwFileAttributes = BITOR(dwFileAttributes, FILE_ATTRIBUTE_ARCHIVE)
			ENDIF
			IF '+S' $ tcAttrib
				dwFileAttributes = BITOR(dwFileAttributes, FILE_ATTRIBUTE_SYSTEM)
			ENDIF
			IF '+H' $ tcAttrib
				dwFileAttributes = BITOR(dwFileAttributes, FILE_ATTRIBUTE_HIDDEN)
			ENDIF
			IF '+D' $ tcAttrib
				dwFileAttributes = BITOR(dwFileAttributes, FILE_ATTRIBUTE_DIRECTORY)
			ENDIF
			IF '+T' $ tcAttrib
				dwFileAttributes = BITOR(dwFileAttributes, FILE_ATTRIBUTE_TEMPORARY)
			ENDIF
			IF '+C' $ tcAttrib
				dwFileAttributes = BITOR(dwFileAttributes, FILE_ATTRIBUTE_COMPRESSED)
			ENDIF

			IF '-R' $ tcAttrib AND BITAND(dwFileAttributes, FILE_ATTRIBUTE_READONLY) = FILE_ATTRIBUTE_READONLY
				dwFileAttributes = dwFileAttributes - FILE_ATTRIBUTE_READONLY
			ENDIF
			IF '-A' $ tcAttrib AND BITAND(dwFileAttributes, FILE_ATTRIBUTE_ARCHIVE) = FILE_ATTRIBUTE_ARCHIVE
				dwFileAttributes = dwFileAttributes - FILE_ATTRIBUTE_ARCHIVE
			ENDIF
			IF '-S' $ tcAttrib AND BITAND(dwFileAttributes, FILE_ATTRIBUTE_SYSTEM) = FILE_ATTRIBUTE_SYSTEM
				dwFileAttributes = dwFileAttributes - FILE_ATTRIBUTE_SYSTEM
			ENDIF
			IF '-H' $ tcAttrib AND BITAND(dwFileAttributes, FILE_ATTRIBUTE_HIDDEN) = FILE_ATTRIBUTE_HIDDEN
				dwFileAttributes = dwFileAttributes - FILE_ATTRIBUTE_HIDDEN
			ENDIF
			IF '-D' $ tcAttrib AND BITAND(dwFileAttributes, FILE_ATTRIBUTE_DIRECTORY) = FILE_ATTRIBUTE_DIRECTORY
				dwFileAttributes = dwFileAttributes - FILE_ATTRIBUTE_DIRECTORY
			ENDIF
			IF '-T' $ tcAttrib AND BITAND(dwFileAttributes, FILE_ATTRIBUTE_TEMPORARY) = FILE_ATTRIBUTE_TEMPORARY
				dwFileAttributes = dwFileAttributes - FILE_ATTRIBUTE_TEMPORARY
			ENDIF
			IF '-C' $ tcAttrib AND BITAND(dwFileAttributes, FILE_ATTRIBUTE_COMPRESSED) = FILE_ATTRIBUTE_COMPRESSED
				dwFileAttributes = dwFileAttributes - FILE_ATTRIBUTE_COMPRESSED
			ENDIF

			* setting selected attributes
			=SetFileAttributes(tcFileName, dwFileAttributes)
		ENDIF
	ENDPROC


ENDDEFINE
