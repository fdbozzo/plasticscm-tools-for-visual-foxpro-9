*------------------------------------------------------------------------------
*-- FOXPRO_PLASTICSCM_DM.PRG	- Visual FoxPro 9.0 DIFF/MERGE para PlasticSCM
*-- Fernando D. Bozzo			- 18/12/2013
*------------------------------------------------------------------------------
* PARÁMETROS:				(!=Obligatorio | ?=Opcional) (@=Pasar por referencia | v=Pasar por valor) (IN/OUT)
* tcSourcePath				(!v IN    ) Path del archivo origen
* tcDestinationPath			(!v IN    ) Path del archivo destino
* tcSourceSymbolic			(!v IN    ) Ruta simbólica del archivo origen con información del changeset, branch o revisión
* tcDestinationSymbolic		(!v IN    ) Ruta simbólica del archivo destino con información del changeset, branch o revisión
*-- Estos se usan para el MERGE:
* tcBasePath				(!v IN    ) Path del archivo base (base del archivo origen y del destino)
* tcBaseSymbolic			(!v IN    ) Ruta simbólica del archivo base con información del changeset, branch o revisión
* tcOutputPath				(!v IN    ) Path del archivo de salida generado
*--------------------------------------------------------------------------------------------------------------
LPARAMETERS P01, P02, P03, P04, P05, P06, P07, P08, P09, P10

#DEFINE CR_LF	CHR(13) + CHR(10)

TRY
	LOCAL loEx AS EXCEPTION, loTool AS CL_SCM_LIB OF 'FOXPRO_PLASTICSCM_DM.PRG'
	LOCAL lsBuffer, lnAddress, lnBufsize, lnPcount ;
		, lcOperation, lcSourcePath, lcDestinationPath, lcSourceSymbolic, lcDestinationSymbolic ;
		, lcBasePath, lcBaseSymbolic, lcOutputPath
	loEx	= NULL
	*tcTool	= UPPER( EVL( tcTool, 'DIFF' ) )
	loTool	= CREATEOBJECT('CL_SCM_LIB')
	_SCREEN.AddProperty( 'ExitCode', 0 )

	lnPcount	= PCOUNT()
	
	IF lnPcount <= 1	&& Fox no los ve... pero están ahí :)
		* Obtengo la linea completa de comandos
		* Adaptado de http://www.news2news.com/vfp/?example=51&function=78
		* Facilitado por Mario Lopez en el foro FoxPro de Google Español - 23/12/2013
		* https://groups.google.com/d/msg/publicesvfoxpro/llS-kTNrG9M/LA4D3fd152IJ
		*-----------------------------------------------------------------------------
		DECLARE INTEGER GetCommandLine IN kernel32
		DECLARE INTEGER GlobalSize IN kernel32 INTEGER hMem
		DECLARE RtlMoveMemory IN kernel32 As CopyMemory STRING @Destination, INTEGER Source, INTEGER nLength

		lnAddress = GetCommandLine()  && returns an address in memory
		lnBufsize = GlobalSize(lnAddress)

		* allocating and filling a buffer
		IF lnBufsize <> 0
		    lsBuffer = REPLICATE(CHR(0), lnBufsize)
		    = CopyMemory(@lsBuffer, lnAddress, lnBufsize)
		ENDIF

		lsBuffer = CHRTRAN(lsBuffer, CHR(0)+'"', " ")
		loTool.writeLog( 'Buffer de parámetros: [' + lsBuffer + ']' )

		FOR I = 1 TO OCCURS("'", lsBuffer) / 2
			*loTool.writeLog( '- Se asignará [' + TRANSFORM( STREXTRACT(lsBuffer, "'", "'", I*2-1, 0) ) ;
				+ '] a [' + TRANSFORM( ('P' + TRANSFORM(I,'@L ##') ) ) + ']' )
			STORE STREXTRACT(lsBuffer, "'", "'", I*2-1, 0) TO ('P' + TRANSFORM(I,'@L ##'))
			lnPcount	= lnPcount + 1
		ENDFOR
		
		RELEASE lsBuffer, lnAddress, lnBufsize
		CLEAR DLLS 'GetCommandLine', 'GlobalSize', 'RtlMoveMemory'
	ENDIF

	IF .F.
		loTool.lDebug = .T.
		loTool.writeLog( '---' + PADR( PROGRAM(),77, '-' ) )
		loTool.writeLog( 'P01	=' + (EVL(P01,'')) )
		loTool.writeLog( 'P02	=' + (EVL(P02,'')) )
		loTool.writeLog( 'P03	=' + (EVL(P03,'')) )
		loTool.writeLog( 'P04	=' + (EVL(P04,'')) )
		loTool.writeLog( 'P05	=' + (EVL(P05,'')) )
		loTool.writeLog( 'P06	=' + (EVL(P06,'')) )
		loTool.writeLog( 'P07	=' + (EVL(P07,'')) )
		loTool.writeLog( 'P08	=' + (EVL(P08,'')) )
		loTool.writeLog( 'P09	=' + (EVL(P09,'')) )
		loTool.writeLog( 'P10	=' + (EVL(P10,'')) )
		lcOperation = 'ERR'
		*ERROR 'Error'
	ENDIF

	lcOperation	= UPPER(EVL(P01,'DIFF'))
	loTool.cOperation	= lcOperation

	DO CASE
	CASE VARTYPE(loTool) <> 'O'
		loEx	= CREATEOBJECT("Exception")

	CASE lcOperation == 'CHECKIN'
		loTool.P_Checkin( @loEx )

	CASE lcOperation == 'CHECKOUT'
		loTool.P_Checkout( @loEx )

	CASE lcOperation == 'DIFF'
		lcSourcePath			= P02
		lcDestinationPath		= P03
		lcSourceSymbolic		= P04
		lcDestinationSymbolic	= P05
		loTool.P_Diff( @loEx, lcSourcePath, lcDestinationPath, lcSourceSymbolic, lcDestinationSymbolic )

	CASE lcOperation == 'MERGE'
		lcSourcePath			= P02
		lcDestinationPath		= P03
		lcSourceSymbolic		= P04
		lcDestinationSymbolic	= P05
		lcBasePath				= P06
		lcBaseSymbolic			= P07
		lcOutputPath			= P08
		loTool.P_Merge( @loEx, lcSourcePath, lcDestinationPath, lcSourceSymbolic, lcDestinationSymbolic, lcBasePath, lcBaseSymbolic, lcOutputPath )

	OTHERWISE
		loEx	= CREATEOBJECT("Exception")
	ENDCASE

CATCH TO loEx
	lcMenError	= 'CurDir: ' + SYS(5)+CURDIR() + CR_LF ;
		+ 'Error ' + TRANSFORM(loEx.ERRORNO) + ', ' + loEx.MESSAGE + CR_LF ;
		+ loEx.PROCEDURE + ', line ' + TRANSFORM(loEx.LINENO) + CR_LF ;
		+ loEx.LINECONTENTS + CR_LF ;
		+ loEx.USERVALUE
	loTool.writeLog( lcMenError )

FINALLY
	loTool	= NULL
ENDTRY

IF NOT ISNULL(loEx)
	loEx	= NULL
	_SCREEN.AddProperty( 'ExitCode', 1 )
ENDIF

IF _VFP.STARTMODE <= 1
	RETURN
ENDIF

IF NOT ISNULL(loEx)
	DECLARE ExitProcess IN Win32API INTEGER ExitCode
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
		+ [<memberdata name="coperation" display="cOperation"/>] ;
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
		+ [<memberdata name="p_checkin" display="P_Checkin"/>] ;
		+ [<memberdata name="p_checkout" display="P_Checkout"/>] ;
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
	cOperation		= ''
	l_Initialized	= .F.


	PROCEDURE INIT
		SET DATE TO YMD
		SET HOURS TO 24
		SET SAFETY OFF
		SET TALK OFF
		SET NOTIFY OFF
		THIS.writeLog()
		THIS.writeLog( REPLICATE('#',80) )
		*THIS.writeLog( '---' + PROGRAM() + ' >>> Inicio' )
	ENDPROC


	PROCEDURE DESTROY
		IF NOT EMPTY(THIS.cTextLog)
			*THIS.writeLog( '---' + PROGRAM() + ' <<< Fin.' )
			STRTOFILE( THIS.cTextLog + CR_LF, FORCEPATH( 'foxpro_plasticscm_dm.log', GETENV("TEMP") ), 1 )
		ENDIF
	ENDPROC


	PROCEDURE Initialize
		LPARAMETERS tcSourcePath, tcDestinationPath, tcSourceSymbolic, tcDestinationSymbolic, tcBasePath, tcBaseSymbolic, tcOutputPath

		WITH THIS AS CL_SCM_LIB OF 'FOXPRO_PLASTICSCM_DM.PRG'
			IF INLIST( .cOperation, 'DIFF', 'MERGE' )
				.writeLog( '---' + PADR( PROGRAM(),77, '-' ) )
				.writeLog( 'SourcePath			=' + TRANSFORM(EVL(tcSourcePath,'')) )
				.writeLog( 'DestinationPath		=' + TRANSFORM(EVL(tcDestinationPath,'')) )
				.writeLog( 'SourceSymbolic		=' + TRANSFORM(EVL(tcSourceSymbolic,'')) )
				.writeLog( 'DestinationSymbolic	=' + TRANSFORM(EVL(tcDestinationSymbolic,'')) )
				.writeLog( 'BasePath			=' + TRANSFORM(EVL(tcBasePath,'')) )
				.writeLog( 'BaseSymbolic		=' + TRANSFORM(EVL(tcBaseSymbolic,'')) )
				.writeLog( 'OutputPath			=' + TRANSFORM(EVL(tcOutputPath,'')) )
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
				.writeLog( 'sys(16)				=' + TRANSFORM(.cSys16) )
				.writeLog( 'cEXEPath			=' + TRANSFORM(.cEXEPath) )

				IF INLIST( .cOperation, 'DIFF', 'MERGE' )
					loShell			= .oShell
					lcPlasticSCM	= loShell.RegRead('HKEY_CLASSES_ROOT\plastic\shell\open\command\')
					.writeLog( 'lcPlasticSCM		=' + TRANSFORM(lcPlasticSCM) )

					IF EMPTY( lcPlasticSCM )
						.cCM	= '"cm.exe"'
					ELSE
						.cCM	= STRTRAN( STREXTRACT( lcPlasticSCM, '"', '"', 1, 4 ), 'plastic.exe', 'cm.exe' )
						.cPlasticPath		= JUSTPATH(.cCM)
					ENDIF
				ENDIF
				.writeLog( REPLICATE('-',80) )

				.l_Initialized	= .T.
			ENDIF
		ENDWITH && THIS AS CL_SCM_LIB OF 'FOXPRO_PLASTICSCM_DM.PRG'
	ENDPROC


	PROCEDURE P_Checkin
		*--------------------------------------------------------------------------------------------------------------
		* PROCESA EL CHECKIN
		*--------------------------------------------------------------------------------------------------------------
		* PARÁMETROS:				(!=Obligatorio | ?=Opcional) (@=Pasar por referencia | v=Pasar por valor) (IN/OUT)
		* toEx						(?@    OUT) Objeto con información del error
		*--------------------------------------------------------------------------------------------------------------
		LPARAMETERS toEx AS EXCEPTION

		TRY
			LOCAL lcMenError, lcStdIn ;
				, loFSO AS Scripting.FileSystemObject ;
				, loStdIn AS Scripting.TextStream ;
				, loStdOut AS Scripting.TextStream ;
				, loStdErr AS Scripting.TextStream

			WITH THIS AS CL_SCM_LIB OF 'FOXPRO_PLASTICSCM_DM.PRG'
				.writeLog( '---' + PADR( PROGRAM(),77, '-' ) )
				toEx				= NULL

				.Initialize()

				loFSO	= .oFSO
				loStdIn = loFSO.GetStandardStream(0)	&& Standard Input
				*.writeLog( 'StdIn: --------------------' )

				TRY
					lcStdIn	= loStdIn.ReadAll()
				CATCH
					lcStdIn	= ''
				FINALLY
					.writeLog( lcStdIn )
					.writeLog( '' )
				ENDTRY

				*TRY
				*	loStdOut = loFSO.GetStandardStream(1)	&& Standard Output
				*	loStdOut.Write( lcStdIn )
				*CATCH
				*ENDTRY
			ENDWITH && THIS AS CL_SCM_LIB OF 'FOXPRO_PLASTICSCM_DM.PRG'

		CATCH TO toEx WHEN toEx.MESSAGE = '0'
			toEx	= NULL

		CATCH TO toEx
			lcMenError	= 'CurDir: ' + SYS(5)+CURDIR() + CR_LF ;
				+ 'Error ' + TRANSFORM(toEx.ERRORNO) + ', ' + toEx.MESSAGE + CR_LF ;
				+ toEx.PROCEDURE + ', line ' + TRANSFORM(toEx.LINENO) + CR_LF ;
				+ toEx.LINECONTENTS + CR_LF ;
				+ toEx.USERVALUE
			THIS.writeLog( lcMenError )
			*IF _VFP.StartMode = 0
			MESSAGEBOX( lcMenError, 0+16+4096, "ATENCIÓN!!", 60000 )
			*ENDIF

		FINALLY
			IF VARTYPE(loStdIn) = 'O'
				loStdIn.Close()
			ENDIF
		ENDTRY

		RETURN
	ENDPROC


	PROCEDURE P_Checkout
		*--------------------------------------------------------------------------------------------------------------
		* PROCESA EL CHECKOUT
		*--------------------------------------------------------------------------------------------------------------
		* PARÁMETROS:				(!=Obligatorio | ?=Opcional) (@=Pasar por referencia | v=Pasar por valor) (IN/OUT)
		* toEx						(?@    OUT) Objeto con información del error
		*--------------------------------------------------------------------------------------------------------------
		LPARAMETERS toEx AS EXCEPTION

		TRY
			LOCAL lcMenError, lcStdIn ;
				, loFSO AS Scripting.FileSystemObject ;
				, loStdIn AS Scripting.TextStream ;
				, loStdOut AS Scripting.TextStream ;
				, loStdErr AS Scripting.TextStream

			WITH THIS AS CL_SCM_LIB OF 'FOXPRO_PLASTICSCM_DM.PRG'
				.writeLog( '---' + PADR( PROGRAM(),77, '-' ) )
				toEx				= NULL

				.Initialize()

				loFSO	= .oFSO
				loStdIn = loFSO.GetStandardStream(0)	&& Standard Input
				*.writeLog( 'StdIn: --------------------' )

				TRY
					lcStdIn	= loStdIn.ReadAll()
				CATCH
					lcStdIn	= ''
				FINALLY
					.writeLog( lcStdIn )
					.writeLog( '' )
				ENDTRY

				*TRY
				*	loStdOut = loFSO.GetStandardStream(1)	&& Standard Output
				*	loStdOut.Write( lcStdIn )
				*CATCH
				*ENDTRY
			ENDWITH && THIS AS CL_SCM_LIB OF 'FOXPRO_PLASTICSCM_DM.PRG'

		CATCH TO toEx WHEN toEx.MESSAGE = '0'
			toEx	= NULL

		CATCH TO toEx
			lcMenError	= 'CurDir: ' + SYS(5)+CURDIR() + CR_LF ;
				+ 'Error ' + TRANSFORM(toEx.ERRORNO) + ', ' + toEx.MESSAGE + CR_LF ;
				+ toEx.PROCEDURE + ', line ' + TRANSFORM(toEx.LINENO) + CR_LF ;
				+ toEx.LINECONTENTS + CR_LF ;
				+ toEx.USERVALUE
			THIS.writeLog( lcMenError )
			*IF _VFP.StartMode = 0
			MESSAGEBOX( lcMenError, 0+16+4096, "ATENCIÓN!!", 60000 )
			*ENDIF

		FINALLY
			IF VARTYPE(loStdIn) = 'O'
				loStdIn.Close()
			ENDIF
		ENDTRY

		RETURN
	ENDPROC


	PROCEDURE P_Diff
		*--------------------------------------------------------------------------------------------------------------
		* PROCESA EL DIFF
		*--------------------------------------------------------------------------------------------------------------
		* PARÁMETROS:				(!=Obligatorio | ?=Opcional) (@=Pasar por referencia | v=Pasar por valor) (IN/OUT)
		* toEx						(?@    OUT) Objeto con información del error
		* tcSourcePath				(!v IN    ) Path del archivo origen
		* tcDestinationPath			(!v IN    ) Path del archivo destino
		* tcSourceSymbolic			(!v IN    ) Ruta simbólica del archivo origen con información del changeset, branch o revisión
		* tcDestinationSymbolic		(!v IN    ) Ruta simbólica del archivo destino con información del changeset, branch o revisión
		*--------------------------------------------------------------------------------------------------------------
		LPARAMETERS toEx AS EXCEPTION, tcSourcePath, tcDestinationPath, tcSourceSymbolic, tcDestinationSymbolic

		TRY
			LOCAL lnExitCode AS INTEGER ;
				, loEx AS EXCEPTION ;
				, lcExtension_b, lcExtension_c, lcExtension_2, lcDestinationExtension, llNotInWorkspace ;
				, lcMenError, lcSourceSymbolicFileName, lcDestinationSymbolicFileName, lcWorkspaceFileName

			WITH THIS AS CL_SCM_LIB OF 'FOXPRO_PLASTICSCM_DM.PRG'
				STORE '' TO lcWorkspaceFileName, lcExtension_b, lcExtension_c, lcExtension_2, lcDestinationExtension
				.writeLog( '---' + PADR( PROGRAM(),77, '-' ) )
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
				+ 'Error ' + TRANSFORM(toEx.ERRORNO) + ', ' + toEx.MESSAGE + CR_LF ;
				+ toEx.PROCEDURE + ', line ' + TRANSFORM(toEx.LINENO) + CR_LF ;
				+ toEx.LINECONTENTS + CR_LF ;
				+ toEx.USERVALUE
			THIS.writeLog( lcMenError )
			*IF _VFP.StartMode = 0
			MESSAGEBOX( lcMenError, 0+16+4096, "ATENCIÓN!!", 60000 )
			*ENDIF

		ENDTRY

		RETURN
	ENDPROC


	PROCEDURE P_Merge
		*--------------------------------------------------------------------------------------------------------------
		* PROCESA EL MERGE
		*--------------------------------------------------------------------------------------------------------------
		* PARÁMETROS:				(!=Obligatorio | ?=Opcional) (@=Pasar por referencia | v=Pasar por valor) (IN/OUT)
		* toEx						(?@    OUT) Objeto con información del error
		* tcSourcePath				(!v IN    ) Path del archivo origen
		* tcDestinationPath			(!v IN    ) Path del archivo destino
		* tcSourceSymbolic			(!v IN    ) Ruta simbólica del archivo origen con información del changeset, branch o revisión
		* tcDestinationSymbolic		(!v IN    ) Ruta simbólica del archivo destino con información del changeset, branch o revisión
		* tcBasePath				(!v IN    ) Path del archivo base (base del archivo origen y del destino)
		* tcBaseSymbolic			(!v IN    ) Ruta simbólica del archivo base con información del changeset, branch o revisión
		* tcOutputPath				(!v IN    ) Path del archivo de salida generado
		*--------------------------------------------------------------------------------------------------------------
		LPARAMETERS toEx AS EXCEPTION, tcSourcePath, tcDestinationPath, tcSourceSymbolic, tcDestinationSymbolic, tcBasePath, tcBaseSymbolic, tcOutputPath

		TRY
			LOCAL lnExitCode AS INTEGER ;
				, loEx AS EXCEPTION ;
				, lcExtension_b, lcExtension_c, lcExtension_2, lcDestinationExtension ;
				, lcMenError, lcSourceSymbolicFileName, lcDestinationSymbolicFileName, lcWorkspaceFileName ;
				, lcTextMergeResult

			WITH THIS AS CL_SCM_LIB OF 'FOXPRO_PLASTICSCM_DM.PRG'
				STORE '' TO lcWorkspaceFileName, lcExtension_b, lcExtension_c, lcExtension_2, lcDestinationExtension, lcTextMergeResult
				.writeLog( '---' + PADR( PROGRAM(),77, '-' ) )
				loEx				= NULL
				tcSourcePath		= STRTRAN( tcSourcePath, '\\', '\' )
				tcBasePath			= STRTRAN( tcBasePath, '\\', '\' )
				tcDestinationPath	= STRTRAN( tcDestinationPath, '\\', '\' )
				tcOutputPath		= STRTRAN( tcOutputPath, '\\', '\' )

				.Initialize( tcSourcePath, tcDestinationPath, tcSourceSymbolic, tcDestinationSymbolic, tcBasePath, tcBaseSymbolic, tcOutputPath )

				lcDestinationExtension	= JUSTEXT(tcDestinationPath)
				lcWorkspaceFileName		= tcDestinationPath

				.GetSecondaryExtensions( lcDestinationExtension, @lcExtension_b, @lcExtension_c, @lcExtension_2 )

				.SourceProcessForMerge( lcDestinationExtension, lcExtension_b, lcExtension_c, tcSourceSymbolic, tcSourcePath, tcDestinationPath, lcWorkspaceFileName )
				.BaseProcessForMerge( lcDestinationExtension, lcExtension_b, lcExtension_c, tcBaseSymbolic, tcBasePath, lcWorkspaceFileName )
				.DestinationProcessForMerge( lcDestinationExtension, lcExtension_b, lcExtension_c, tcDestinationSymbolic, tcDestinationPath, lcWorkspaceFileName )
				lcTextMergeResult	= .MergeProcess( lcDestinationExtension, lcExtension_b, lcExtension_c, lcExtension_2, tcSourcePath, tcBasePath, tcDestinationPath, tcOutputPath )
				.ConvertToBinaryProcess( lcDestinationExtension, lcExtension_b, lcExtension_c, lcExtension_2, lcTextMergeResult, tcDestinationPath, tcOutputPath )
			ENDWITH && THIS AS CL_SCM_LIB OF 'FOXPRO_PLASTICSCM_DM.PRG'

		CATCH TO toEx WHEN toEx.MESSAGE = '0'
			toEx	= NULL

		CATCH TO toEx
			lcMenError	= 'CurDir: ' + SYS(5)+CURDIR() + CR_LF ;
				+ 'Error ' + TRANSFORM(toEx.ERRORNO) + ', ' + toEx.MESSAGE + CR_LF ;
				+ toEx.PROCEDURE + ', line ' + TRANSFORM(toEx.LINENO) + CR_LF ;
				+ toEx.LINECONTENTS + CR_LF ;
				+ toEx.USERVALUE
			THIS.writeLog( lcMenError )
			*IF _VFP.StartMode = 0
			MESSAGEBOX( lcMenError, 0+16+4096, "ATENCIÓN!!", 60000 )
			*ENDIF

		ENDTRY

		RETURN
	ENDPROC


	FUNCTION SourceProcessForDiff
		*--------------------------------------------------------------------------------------------------------------
		* PROCESO DEL ARCHIVO ORIGEN PARA EL DIFF
		*--------------------------------------------------------------------------------------------------------------
		* PARÁMETROS:				(!=Obligatorio | ?=Opcional) (@=Pasar por referencia | v=Pasar por valor) (IN/OUT)
		* tcDestinationExtension	(!v IN    ) Extensión de destino
		* tcExtension_b				(!v IN    ) Extensión secundaria (PJT,VCT,SCT,FRT,LBT,MNT,FPT,DCT,...)
		* tcExtension_c				(!v IN    ) Extensión terciaria (CDX,DCX,...)
		* tcSourceSymbolic			(!v IN    ) Ruta simbólica del archivo origen con información del changeset, branch o revisión
		* tcSourcePath				(!v IN    ) Path del archivo origen
		* tcDestinationPath			(!v IN    ) Path del archivo destino
		* tcWorkspaceFileName		(!v IN    ) Nombre del archivo en el workspace (inferido de los parámetros de entrada)
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
				.writeLog( '---' + PADR( PROGRAM(),77, '-' ) )
				lnCommandResult		= 0
				lcSourceSymbolicExtensionReplaced	= STRTRAN( tcSourceSymbolic, '.' + tcDestinationExtension, '.' + tcExtension_b )

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
							+ '] a ["' + STRTRAN( tcDestinationPath, '.' + tcDestinationExtension, '.' + tcExtension_b) + '#' + SUBSTR(lcSourceSpecForCatCommand,2) + ']' )
						lcSourceSpecForCatCommand	= '"' + STRTRAN( tcDestinationPath, '.' + tcDestinationExtension, '.' + tcExtension_b) + '#' + SUBSTR(lcSourceSpecForCatCommand,2)
					ENDIF

				ELSE	&& Parse source symbolic when operation is: "Diff between revision A and revision B"
					*-------------------------------------------------------------------------------
					* Ejemplo 1:	sourcesymbolic="rev:c:\DESA\foxbin2prg\foxbin2prg.pjx#cs:61"
					* Ejemplo 2:	sourcesymbolic="c:\DESA\foxbin2prg\foxbin2prg.prg#br:/main/v1.12 DESA"
					*-------------------------------------------------------------------------------
					ALINES( laSourceSymbolicExtensionReplaced_Splited, lcSourceSymbolicExtensionReplaced, 4, 'rev:')
					lcSourceSpecForCatCommand	= '"' + laSourceSymbolicExtensionReplaced_Splited[1] + '"'
				ENDIF

				lcSourcePathExtensionReplaced	= STRTRAN( tcSourcePath, '.' + tcDestinationExtension, '.' + tcExtension_b )

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
					ERROR "Foxbin2prg devolvió un error"
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
		* PARÁMETROS:				(!=Obligatorio | ?=Opcional) (@=Pasar por referencia | v=Pasar por valor) (IN/OUT)
		* tcDestinationExtension	(!v IN    ) Extensión de destino
		* tcExtension_b				(!v IN    ) Extensión secundaria (PJT,VCT,SCT,FRT,LBT,MNT,FPT,DCT,...)
		* tcExtension_c				(!v IN    ) Extensión terciaria (CDX,DCX,...)
		* tcSourceSymbolic			(!v IN    ) Ruta simbólica del archivo origen con información del changeset, branch o revisión
		* tcSourcePath				(!v IN    ) Path del archivo origen
		* tcDestinationPath			(!v IN    ) Path del archivo destino
		* tcWorkspaceFileName		(!v IN    ) Nombre del archivo en el workspace (inferido de los parámetros de entrada)
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
				.writeLog( '---' + PADR( PROGRAM(),77, '-' ) )
				lnCommandResult		= 0
				lcSourceSymbolicExtensionReplaced	= STRTRAN( tcSourceSymbolic, tcDestinationExtension, tcExtension_b )

				*-------------------------------------------------------------------------------
				* Ejemplo:	sourcesymbolic="c:\DESA\foxbin2prg\foxbin2prg.pjt#/main/v1.15p1#cs:62"
				*-------------------------------------------------------------------------------
				ALINES( laSourceSymbolicExtensionReplaced_Splited, lcSourceSymbolicExtensionReplaced, 4, '#')
				lcSourceSpecForCatCommand	= '"' + laSourceSymbolicExtensionReplaced_Splited[1] + '#' ;
					+ laSourceSymbolicExtensionReplaced_Splited[3] + '"'

				lcSourcePathExtensionReplaced	= STRTRAN( tcSourcePath, '.' + tcDestinationExtension, '.' + tcExtension_b )

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
					ERROR "Foxbin2prg devolvió un error"
				ENDIF

				IF THIS.lDebug
					*MESSAGEBOX( 'FoxBin2prg se le envió el archivo Origen [' + tcSourcePath + ']' + CR_LF ;
						+ '(Ya se generó el PJ2. Ver si el archivo está en el directorio Origen)' ;
						, 0+64+4096 ;
						, 'PUNTO DE CONTROL EN "' + PROGRAM() + '"' ;
						, 600000 )
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
		* PARÁMETROS:				(!=Obligatorio | ?=Opcional) (@=Pasar por referencia | v=Pasar por valor) (IN/OUT)
		* tcDestinationExtension	(!v IN    ) Extensión de destino
		* tcExtension_b				(!v IN    ) Extensión secundaria (PJT,VCT,SCT,FRT,LBT,MNT,FPT,DCT,...)
		* tcExtension_c				(!v IN    ) Extensión terciaria (CDX,DCX,...)
		* tcBaseSymbolic			(!v IN    ) Ruta simbólica del archivo base con información del changeset, branch o revisión
		* tcBasePath				(!v IN    ) Path del archivo base
		* tcWorkspaceFileName		(!v IN    ) Nombre del archivo en el workspace (inferido de los parámetros de entrada)
		*--------------------------------------------------------------------------------------------------------------
		LPARAMETERS tcDestinationExtension, tcExtension_b, tcExtension_c, tcBaseSymbolic, tcBasePath, tcWorkspaceFileName

		#IF .F.
			LOCAL THIS AS CL_SCM_LIB OF 'FOXPRO_PLASTICSCM_DM.PRG'
		#ENDIF

		TRY
			LOCAL lcBaseSymbolicExtensionReplaced, lcBaseSpecForCatCommand, lcBasePathExtensionReplaced ;
				, laBaseSymbolicExtensionReplaced_Splited(1), lcCommand, lnCommandResult, lcBasePathParsed

			WITH THIS AS CL_SCM_LIB OF 'FOXPRO_PLASTICSCM_DM.PRG'
				.writeLog( '---' + PADR( PROGRAM(),77, '-' ) )
				lnCommandResult		= 0
				lcBaseSymbolicExtensionReplaced	= STRTRAN( tcBaseSymbolic, '.' + tcDestinationExtension, '.' + tcExtension_b )

				*-------------------------------------------------------------------------------
				* Ejemplo:	basesymbolic="c:\DESA\foxbin2prg\foxbin2prg.pjt#/main/v1.15p1#cs:62"
				*-------------------------------------------------------------------------------
				ALINES( laBaseSymbolicExtensionReplaced_Splited, lcBaseSymbolicExtensionReplaced, 4, '#')
				lcBaseSpecForCatCommand	= '"' + laBaseSymbolicExtensionReplaced_Splited[1] + '#' ;
					+ laBaseSymbolicExtensionReplaced_Splited[3] + '"'

				lcBasePathExtensionReplaced	= STRTRAN( tcBasePath, '.' + tcDestinationExtension, '.' + tcExtension_b )

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
					ERROR "Foxbin2prg devolvió un error"
				ENDIF

				IF THIS.lDebug
					*MESSAGEBOX( 'FoxBin2prg se le envió el archivo Base [' + tcBasePath + ']' + CR_LF ;
						+ '(Ya se generó el PJ2. Ver si el archivo está en el directorio Base)' ;
						, 0+64+4096 ;
						, 'PUNTO DE CONTROL EN "' + PROGRAM() + '"' ;
						, 600000 )
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
		* PARÁMETROS:				(!=Obligatorio | ?=Opcional) (@=Pasar por referencia | v=Pasar por valor) (IN/OUT)
		* tcDestinationExtension	(!v IN    ) Extensión de destino
		* tcExtension_b				(!v IN    ) Extensión secundaria (PJT,VCT,SCT,FRT,LBT,MNT,FPT,DCT,...)
		* tcExtension_c				(!v IN    ) Extensión terciaria (CDX,DCX,...)
		* tcDestinationSymbolic		(!v IN    ) Ruta simbólica del archivo destino con información del changeset, branch o revisión
		* tcDestinationPath			(!v IN    ) Path del archivo destino
		* tcWorkspaceFileName		(!v IN    ) Nombre del archivo en el workspace (inferido de los parámetros de entrada)
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
				.writeLog( '---' + PADR( PROGRAM(),77, '-' ) )
				lnCommandResult		= 0

				* Parse destination symbolic when operation is: "Diff between revision A and revision B"
				IF "rev:" $ tcDestinationSymbolic
					lcDestinationSymbolicExtensionReplaced = STRTRAN( tcDestinationSymbolic, '.' + tcDestinationExtension, '.' + tcExtension_b )
					ALINES( laDestinationSymbolicExtensionReplaced_Splited, lcDestinationSymbolicExtensionReplaced, 4, "rev:" )
					lcDestinationSpecForCatCommand		= '"' + laDestinationSymbolicExtensionReplaced_Splited[1] + '"'
					lcDestinationPathExtensionReplaced	= STRTRAN( tcDestinationPath, '.' + tcDestinationExtension, '.' + tcExtension_b )

					lcCommand 			= .cCM + ' cat ' + lcDestinationSpecForCatCommand + ' --file="' + lcDestinationPathExtensionReplaced + '"'
					lnCommandResult		= .RunCommand( lcCommand )

					IF (lnCommandResult == 1)
						ERROR "There was an error performing the diff (rev) operation."
					ENDIF

					lcDestinationPathParsed	= ' "' + tcDestinationPath + '" "0" "0" "0" "0" "0" "0" "' + tcWorkspaceFileName + '"'
					lcCommand				= '"' + FORCEPATH( 'foxbin2prg.exe', .cEXEPath ) + '"' + lcDestinationPathParsed
					lnCommandResult		= .RunCommand( lcCommand )

					IF (lnCommandResult == 1)
						ERROR "Foxbin2prg devolvió un error"
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


	FUNCTION DestinationProcessForMerge
		*--------------------------------------------------------------------------------------------------------------
		* PROCESO DEL ARCHIVO DESTINO PARA EL MERGE
		*--------------------------------------------------------------------------------------------------------------
		* PARÁMETROS:				(!=Obligatorio | ?=Opcional) (@=Pasar por referencia | v=Pasar por valor) (IN/OUT)
		* tcDestinationExtension	(!v IN    ) Extensión de destino
		* tcExtension_b				(!v IN    ) Extensión secundaria (PJT,VCT,SCT,FRT,LBT,MNT,FPT,DCT,...)
		* tcExtension_c				(!v IN    ) Extensión terciaria (CDX,DCX,...)
		* tcDestinationSymbolic		(!v IN    ) Ruta simbólica del archivo destino con información del changeset, branch o revisión
		* tcDestinationPath			(!v IN    ) Path del archivo destino
		* tcWorkspaceFileName		(!v IN    ) Nombre del archivo en el workspace (inferido de los parámetros de entrada)
		*--------------------------------------------------------------------------------------------------------------
		LPARAMETERS tcDestinationExtension, tcExtension_b, tcExtension_c, tcDestinationSymbolic, tcDestinationPath, tcWorkspaceFileName

		#IF .F.
			LOCAL THIS AS CL_SCM_LIB OF 'FOXPRO_PLASTICSCM_DM.PRG'
		#ENDIF

		TRY
			LOCAL lcCommand, lnCommandResult, lcDestinationPathParsed

			WITH THIS AS CL_SCM_LIB OF 'FOXPRO_PLASTICSCM_DM.PRG'
				.writeLog( '---' + PADR( PROGRAM(),77, '-' ) )
				lnCommandResult		= 0

				lcDestinationPathParsed	= ' "' + tcDestinationPath + '" "0" "0" "0" "0" "0" "0" "' + tcWorkspaceFileName + '"'
				lcCommand			= '"' + FORCEPATH( 'foxbin2prg.exe', .cEXEPath ) + '"' + lcDestinationPathParsed
				lnCommandResult		= .RunCommand( lcCommand )

				IF (lnCommandResult == 1)
					ERROR "Foxbin2prg devolvió un error"
				ENDIF

				IF THIS.lDebug
					*MESSAGEBOX( 'FoxBin2prg se le envió el archivo destino [' + tcDestinationPath + ']' + CR_LF ;
						+ '(Ya se generó el PJ2. Ver si el archivo está en el directorio Destino)' ;
						, 0+64+4096 ;
						, 'PUNTO DE CONTROL EN "' + PROGRAM() + '"' ;
						, 600000 )
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
		* PARÁMETROS:				(!=Obligatorio | ?=Opcional) (@=Pasar por referencia | v=Pasar por valor) (IN/OUT)
		* tcDestinationExtension	(!v IN    ) Extensión de destino
		* tcExtension_b				(!v IN    ) Extensión secundaria (PJT,VCT,SCT,FRT,LBT,MNT,FPT,DCT,...)
		* tcExtension_c				(!v IN    ) Extensión terciaria (CDX,DCX,...)
		* tcExtension_2				(!v IN    ) Extensión Texto (PJ2,VC2,SC2,FR2,LB2,MN2,DB2,DC2,...)
		* tcSourcePath				(!v IN    ) Path del archivo origen
		* tcDestinationPath			(!v IN    ) Path del archivo destino
		* tlNotInWorkspace			(!v IN    ) Indica si el archivo existía en el Workspace o no (si es una revisión, no existe)
		*--------------------------------------------------------------------------------------------------------------
		LPARAMETERS tcDestinationExtension, tcExtension_b, tcExtension_c, tcExtension_2, tcSourcePath, tcDestinationPath, tlNotInWorkspace

		#IF .F.
			LOCAL THIS AS CL_SCM_LIB OF 'FOXPRO_PLASTICSCM_DM.PRG'
		#ENDIF

		TRY
			LOCAL laDestinationSymbolicExtensionReplaced_Splited(1), lcCommand, lnCommandResult ;
				, lcConvertToTextSource, lcConvertToTextDestination, lcArguments

			WITH THIS AS CL_SCM_LIB OF 'FOXPRO_PLASTICSCM_DM.PRG'
				.writeLog( '---' + PADR( PROGRAM(),77, '-' ) )
				lnCommandResult				= 0
				lcConvertToTextSource		= '"' + STRTRAN( tcSourcePath, '.' + tcDestinationExtension, '.' + tcExtension_2 ) + '"'
				lcConvertToTextDestination	= '"' + STRTRAN( tcDestinationPath, '.' + tcDestinationExtension, '.' + tcExtension_2 ) + '"'

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

					CASE FILE( '"' + tcDestinationPath + '.ERR"' )
						lcCommand			= 'notepad.exe "' + '"' + tcDestinationPath + '.ERR"'

					OTHERWISE
						.writeLog( 'No existen los archivos ["' + tcSourcePath + '.ERR' ;
							+ '"] y ["' + tcDestinationPath + '"]' )
					ENDCASE

					lnCommandResult		= .RunCommand( lcCommand, 1 )
					ERROR 'No existe alguno de los archivos Texto que dabían generarse'
				ENDIF

				.DeleteFile( lcConvertToTextSource )
				.DeleteFile( '"' + STRTRAN( tcSourcePath, '.' + tcDestinationExtension, '.' + tcExtension_b ) + '"' )
				.DeleteFile( tcSourcePath )

				IF tlNotInWorkspace
					.DeleteFile( lcConvertToTextDestination )
					.DeleteFile( '"' + STRTRAN( tcDestinationPath, '.' + tcDestinationExtension, '.' + tcExtension_b ) + '"' )
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
		* PARÁMETROS:				(!=Obligatorio | ?=Opcional) (@=Pasar por referencia | v=Pasar por valor) (IN/OUT)
		* tcDestinationExtension	(!v IN    ) Extensión de destino
		* tcExtension_b				(!v IN    ) Extensión secundaria (PJT,VCT,SCT,FRT,LBT,MNT,FPT,DCT,...)
		* tcExtension_c				(!v IN    ) Extensión terciaria (CDX,DCX,...)
		* tcExtension_2				(!v IN    ) Extensión Texto (PJ2,VC2,SC2,FR2,LB2,MN2,DB2,DC2,...)
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
				, ltTimePreMerge, ltTimePostMerge, laFileInfo(1,5), lcConvertToTextOutput

			WITH THIS AS CL_SCM_LIB OF 'FOXPRO_PLASTICSCM_DM.PRG'
				.writeLog( '---' + PADR( PROGRAM(),77, '-' ) )
				lnCommandResult				= 0
				lcConvertToTextSource		= '"' + STRTRAN( tcSourcePath, '.' + tcDestinationExtension, '.' + tcExtension_2 ) + '"'
				lcConvertToTextBase			= '"' + STRTRAN( tcBasePath, '.' + tcDestinationExtension, '.' + tcExtension_2 ) + '"'
				lcConvertToTextDestination	= '"' + STRTRAN( tcDestinationPath, '.' + tcDestinationExtension, '.' + tcExtension_2 ) + '"'
				lcConvertToTextOutput		= '"' + STRTRAN( tcOutputPath, '.' + tcDestinationExtension, '.' + tcExtension_2 ) + '"'

				ADIR( laFileInfo, tcDestinationPath )
				ltTimePreMerge	= EVALUATE( '{^' + DTOC(laFileInfo(1,3)) + ' ' + TIME() + '}' )

				*-- Verifico si existe antes, porque puede que haya ocurrido un error (.ERR)
				IF FILE(lcConvertToTextSource) AND FILE(lcConvertToTextBase) AND FILE(lcConvertToTextDestination)
					lcArguments			= " -s=" + lcConvertToTextSource + " -b=" + lcConvertToTextBase ;
						+ " -d=" + lcConvertToTextDestination + " -r=" + lcConvertToTextOutput && lcConvertToTextDestination
					lcCommand			= '"' + FORCEPATH( 'mergetool.exe', .cPlasticPath ) + '"' + lcArguments
					lnCommandResult		= .RunCommand( lcCommand )

					IF (lnCommandResult == 1)
						ERROR "mergetool devolvió un error"
					ENDIF

					*ADIR( laFileInfo, tcDestinationPath )
					ADIR( laFileInfo, lcConvertToTextOutput )
					ltTimePostMerge	= EVALUATE( '{^' + DTOC(laFileInfo(1,3)) + ' ' + TIME() + '}' )

					*-- Borrar Source
					.DeleteFile( lcConvertToTextSource )
					.DeleteFile( '"' + STRTRAN( tcSourcePath, '.' + tcDestinationExtension, '.' + tcExtension_b ) + '"' )
					IF NOT EMPTY(tcExtension_c)
						.DeleteFile( '"' + STRTRAN( tcSourcePath, '.' + tcDestinationExtension, '.' + tcExtension_c ) + '"' )
					ENDIF

					*-- Borrar Base
					.DeleteFile( lcConvertToTextBase )
					.DeleteFile( '"' + STRTRAN( tcBasePath, '.' + tcDestinationExtension, '.' + tcExtension_b ) + '"' )
					IF NOT EMPTY(tcExtension_c)
						.DeleteFile( '"' + STRTRAN( tcBasePath, '.' + tcDestinationExtension, '.' + tcExtension_c ) + '"' )
					ENDIF

					* Check if the text merge has been succesfully performed
					IF THIS.lDebug
						*MESSAGEBOX( 'Fecha del archivo destino [' + tcDestinationPath + '] = ' + TRANSFORM(ltTimePreMerge) + CR_LF ;
							+ 'Fecha del archivo Resultado del merge [' + lcConvertToTextOutput + '] = ' + TRANSFORM(ltTimePostMerge) + CR_LF ;
							+ '(Ya se hizo el Merge. Ver si el archivo Resultado sigue estando y el Destino sigue con la misma fecha/hora)' ;
							, 0+64+4096 ;
							, 'PUNTO DE CONTROL EN "' + PROGRAM() + '"' ;
							, 600000 )
					ENDIF
					*IF ltTimePreMerge == ltTimePostMerge
					*	.DeleteFile( lcConvertToTextDestination )
					*	ERROR '0'
					*ENDIF

				ELSE	&& Ocurrió un error
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
					ERROR 'No existe alguno de los archivos Texto que dabían generarse'
				ENDIF

			ENDWITH &&	THIS AS CL_SCM_LIB OF 'FOXPRO_PLASTICSCM_DM.PRG'

		CATCH TO loEx
			IF _VFP.STARTMODE = 0 AND THIS.lDebug
				SET STEP ON
			ENDIF
			THROW
		ENDTRY

		RETURN lcConvertToTextOutput && lcConvertToTextDestination
	ENDFUNC


	PROCEDURE ConvertToBinaryProcess
		*--------------------------------------------------------------------------------------------------------------
		* PROCESO DE MERGE
		*--------------------------------------------------------------------------------------------------------------
		* PARÁMETROS:				(!=Obligatorio | ?=Opcional) (@=Pasar por referencia | v=Pasar por valor) (IN/OUT)
		* tcDestinationExtension	(!v IN    ) Extensión de destino
		* tcExtension_b				(!v IN    ) Extensión secundaria (PJT,VCT,SCT,FRT,LBT,MNT,FPT,DCT,...)
		* tcExtension_c				(!v IN    ) Extensión terciaria (CDX,DCX,...)
		* tcExtension_2				(!v IN    ) Extensión Texto (PJ2,VC2,SC2,FR2,LB2,MN2,DB2,DC2,...)
		* tcTextMergeResult			(!v IN    ) Path del archivo MERGE resultante (en el TEMP)
		* tcDestinationPath			(!v IN    ) Path del archivo destino (en el Workspace)
		* tcOutputPath				(!v IN    ) Path del archivo de salida (en el TEMP)
		*--------------------------------------------------------------------------------------------------------------
		LPARAMETERS tcDestinationExtension, tcExtension_b, tcExtension_c, tcExtension_2, tcTextMergeResult, tcDestinationPath, tcOutputPath

		#IF .F.
			LOCAL THIS AS CL_SCM_LIB OF 'FOXPRO_PLASTICSCM_DM.PRG'
		#ENDIF

		TRY
			LOCAL lcDestinationPath_2, lcDestinationPath_b, lcDestinationPath_c, lcCommand, lnCommandResult ;
				, lcBinarytMergeResult, lcBinarytMergeResul_b, lcBinarytMergeResult_c ;
				, loEx as Exception

			STORE '' TO lcDestinationPath_2, lcDestinationPath_b, lcDestinationPath_c, lcCommand, lnCommandResult ;
				, lcBinarytMergeResult, lcBinarytMergeResul_b, lcBinarytMergeResult_c
			lcDestinationPath_2	= '"' + STRTRAN( tcDestinationPath, '.' + tcDestinationExtension, '.' + tcExtension_2 ) + '"'
			IF NOT EMPTY(tcExtension_b)
				lcDestinationPath_b	= '"' + STRTRAN( tcDestinationPath, '.' + tcDestinationExtension, '.' + tcExtension_b ) + '"'
			ENDIF
			IF NOT EMPTY(tcExtension_c)
				lcDestinationPath_c	= '"' + STRTRAN( tcDestinationPath, '.' + tcDestinationExtension, '.' + tcExtension_c ) + '"'
			ENDIF

			WITH THIS AS CL_SCM_LIB OF 'FOXPRO_PLASTICSCM_DM.PRG'
				.writeLog( '---' + PADR( PROGRAM(),77, '-' ) )
				*.ChangeFileAttribute( tcDestinationPath, '-R' )
				*.ChangeFileAttribute( lcDestinationPath_b, '-R' )
				*.ChangeFileAttribute( lcDestinationPath_c, '-R' )
				*.DeleteFile(tcDestinationPath)
				*.DeleteFile(lcDestinationPath_b)
				*.DeleteFile(lcDestinationPath_c)

				*-- Regenera el BIN (PJX,VCX,SCX,etc)
				lcCommand			= '"' + FORCEPATH( 'foxbin2prg.exe', .cEXEPath ) + '"' + tcTextMergeResult
				lnCommandResult		= .RunCommand( lcCommand )

				IF (lnCommandResult == 1)
					ERROR "Foxbin2prg devolvió un error"
				ENDIF

				IF THIS.lDebug
					*MESSAGEBOX( 'FoxBin2prg se le envió el archivo Resultado [' + tcTextMergeResult + ']' + CR_LF ;
						+ '(Ya se regeneró el PJX. Ver si el archivo está en el directorio Resultado)' ;
						, 0+64+4096 ;
						, 'PUNTO DE CONTROL EN "' + PROGRAM() + '"' ;
						, 600000 )
				ENDIF
				
				* Restore file names using the initial format
				*(ver lo de la capitalización de tcDestinationPath con RENAME, para Extensión, ExtB y ExtC)


				* Overwrite the temporal output file to finish the merge operation
				lcBinarytMergeResult	= STRTRAN( tcTextMergeResult, '.' + tcExtension_2, '.' + tcDestinationExtension )
				*lcBinarytMergeResult_2	= STRTRAN( tcTextMergeResult, '.' + tcExtension_2, '.' + tcDestinationExtension )
				IF NOT EMPTY(tcExtension_b)
					lcBinarytMergeResult_b	= STRTRAN( tcTextMergeResult, '.' + tcExtension_2, '.' + tcExtension_b )
				ENDIF
				IF NOT EMPTY(tcExtension_c)
					lcBinarytMergeResult_c	= STRTRAN( tcTextMergeResult, '.' + tcExtension_2, '.' + tcExtension_c )
				ENDIF
				*.DeleteFile( tcOutputPath )
				*.MoveFile( lcBinarytMergeResult, tcOutputPath )

				IF THIS.lDebug
					*MESSAGEBOX( 'Finalmente se moverán los archivos Resultado, así:' + CR_LF ;
						+ 'Copiar [' + lcBinarytMergeResult + '] a [' + tcDestinationPath + ']' + CR_LF ;
						+ 'Mover [' + tcTextMergeResult + '] a [' + lcDestinationPath_2 + ']' + CR_LF ;
						+ 'Mover [' + lcBinarytMergeResult_b + '] a [' + lcDestinationPath_b + ']' + CR_LF ;
						+ 'Mover [' + lcBinarytMergeResult_c + '] a [' + lcDestinationPath_c + ']' + CR_LF ;
						+ '(Comprobarlo luego de dar Enter)' ;
						, 0+64+4096 ;
						, 'PUNTO DE CONTROL EN "' + PROGRAM() + '"' ;
						, 600000 )
				ENDIF

				.CopyFile( lcBinarytMergeResult, tcDestinationPath )	&& PJX,VCX,SCX,etc.
				.MoveFile( tcTextMergeResult, lcDestinationPath_2 )
				IF NOT EMPTY(lcDestinationPath_b)
					.MoveFile( lcBinarytMergeResult_b, lcDestinationPath_b )
				ENDIF
				IF NOT EMPTY(lcDestinationPath_c) AND FILE(lcBinarytMergeResult_c)
					.MoveFile( lcBinarytMergeResult_c, lcDestinationPath_c )
				ENDIF


				IF THIS.lDebug
					*MESSAGEBOX( 'Se borró el archivo Output [' + tcOutputPath + ']' + CR_LF ;
						+ 'y se renombró el archivo Resultado del Merge [' + lcBinarytMergeResult + '] como nuevo Output' + CR_LF ;
						+ '( Ver el nuevo archivo Output [' + tcOutputPath + '] )' ;
						, 0+64+4096 ;
						, 'PUNTO DE CONTROL EN "' + PROGRAM() + '"' ;
						, 600000 )
				ENDIF

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
		* PARÁMETROS:				(!=Obligatorio | ?=Opcional) (@=Pasar por referencia | v=Pasar por valor) (IN/OUT)
		* tcWorkspaceFileName		(!@    OUT) Nombre del archivo del workspace encontrado
		* tcSourcePath				(!v IN    ) Path del archivo origen
		* tcDestinationPath			(!v IN    ) Path del archivo destino
		* tcSourceSymbolic			(!v IN    ) Ruta simbólica del archivo origen con información del changeset, branch o revisión
		* tcDestinationSymbolic		(!v IN    ) Ruta simbólica del archivo destino con información del changeset, branch o revisión
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
		* PARÁMETROS:				(!=Obligatorio | ?=Opcional) (@=Pasar por referencia | v=Pasar por valor) (IN/OUT)
		* tcPrimaryExtension		(!v IN    ) Extensión principal del archivo destino
		* tcExtension_b				(?@    OUT) Extensión secundaria del archivo
		* tcExtension_c				(?@    OUT) Extensión terciaria del archivo
		* tcExtension_2				(?@    OUT) Extensión de la versión Texto
		*--------------------------------------------------------------------------------------------------------------
		LPARAMETERS tcPrimaryExtension, tcExtension_b, tcExtension_c, tcExtension_2
		STORE '' TO tcExtension_b, tcExtension_c, tcExtension_2
		tcPrimaryExtension	= LOWER(tcPrimaryExtension)

		DO CASE
		CASE tcPrimaryExtension = "pjx"
			tcExtension_b	= "pjt"
			tcExtension_2	= "pj2"

		CASE tcPrimaryExtension = "vcx"
			tcExtension_b	= "vct"
			tcExtension_2	= "vc2"

		CASE tcPrimaryExtension = "scx"
			tcExtension_b	= "sct"
			tcExtension_2	= "sc2"

		CASE tcPrimaryExtension = "frx"
			tcExtension_b	= "frt"
			tcExtension_2	= "fr2"

		CASE tcPrimaryExtension = "lbx"
			tcExtension_b	= "lbt"
			tcExtension_2	= "lb2"

		CASE tcPrimaryExtension = "dbf"
			tcExtension_b	= "fpt"
			tcExtension_c	= "cdx"	&& Ver como tratar esto cuando hay, o no, un CDX.
			tcExtension_2	= "db2"

		CASE tcPrimaryExtension = "dbc"
			tcExtension_b	= "dct"
			tcExtension_c	= "dcx"
			tcExtension_2	= "dc2"

		OTHERWISE
			ERROR 'Extensión [' + TRANSFORM(tcPrimaryExtension) + '] no soportada!'

		ENDCASE
	ENDPROC


	PROCEDURE DeleteFile
		*--------------------------------------------------------------------------------------------------------------
		* BORRA EL ARCHIVO INDICADO
		*--------------------------------------------------------------------------------------------------------------
		* PARÁMETROS:				(!=Obligatorio | ?=Opcional) (@=Pasar por referencia | v=Pasar por valor) (IN/OUT)
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
		* PARÁMETROS:				(!=Obligatorio | ?=Opcional) (@=Pasar por referencia | v=Pasar por valor) (IN/OUT)
		* tcOrigFileName			(!v IN    ) Nombre del archivo origen
		* tcDestFileName			(!v IN    ) Nombre del archivo destino
		*--------------------------------------------------------------------------------------------------------------
		LPARAMETERS tcOrigFileName, tcDestFileName
		LOCAL laFiles(1,5), loFSO AS Scripting.FileSystemObject
		loFSO = THIS.oFSO
		THIS.DeleteFile( tcDestFileName )
		THIS.writeLog( 'RENAME ' + tcOrigFileName + ' TO ' + tcDestFileName )
		*RENAME (tcOrigFileName) TO (tcDestFileName)
		tcOrigFileName	= CHRTRAN(tcOrigFileName, '"', '')
		tcDestFileName	= CHRTRAN(tcDestFileName, '"', '' )
		*IF ADIR(laFiles,"c:\DESA\plastic\foxpro_plasticscm_dm.pj2","",1)=1 AND NOT laFiles(1,1)==JUSTFNAME(aa)
		loFSO.MoveFile( tcOrigFileName, tcDestFileName )
		RETURN
	ENDFUNC


	FUNCTION CopyFile
		*--------------------------------------------------------------------------------------------------------------
		* COPYA UN ARCHIVO
		*--------------------------------------------------------------------------------------------------------------
		* PARÁMETROS:				(!=Obligatorio | ?=Opcional) (@=Pasar por referencia | v=Pasar por valor) (IN/OUT)
		* tcOrigFileName			(!v IN    ) Nombre del archivo origen
		* tcDestFileName			(!v IN    ) Nombre del archivo destino
		*--------------------------------------------------------------------------------------------------------------
		LPARAMETERS tcOrigFileName, tcDestFileName
		LOCAL loFSO AS Scripting.FileSystemObject
		loFSO = THIS.oFSO
		THIS.writeLog( 'COPY ' + tcOrigFileName + ' TO ' + tcDestFileName )
		tcOrigFileName	= CHRTRAN(tcOrigFileName, '"', '')
		tcDestFileName	= CHRTRAN(tcDestFileName, '"', '' )
		RETURN loFSO.CopyFile( tcOrigFileName, tcDestFileName, .T. )
	ENDFUNC


	FUNCTION RunCommand
		*--------------------------------------------------------------------------------------------------------------
		* EJECUTAR UN COMANDO
		*--------------------------------------------------------------------------------------------------------------
		* PARÁMETROS:				(!=Obligatorio | ?=Opcional) (@=Pasar por referencia | v=Pasar por valor) (IN/OUT)
		* tcCommand					(!v IN    ) Comando a ejecutar
		* tnWindowType				(!v IN    ) Tipo de ventana (0=Oculta, 1=Normal, etc)
		*--------------------------------------------------------------------------------------------------------------
		LPARAMETERS tcCommand, tnWindowType

		LOCAL lnCommandResult
		tnWindowType		= EVL(tnWindowType,0)
		THIS.writeLog( tcCommand )
		lnCommandResult		= THIS.oShell.RUN( tcCommand, tnWindowType, .T. )
		THIS.writeLog( '	=> retornó ' + TRANSFORM(lnCommandResult) )

		RETURN lnCommandResult
	ENDFUNC


	FUNCTION writeLog
		*--------------------------------------------------------------------------------------------------------------
		* ESCRIBIR LOG
		*--------------------------------------------------------------------------------------------------------------
		* PARÁMETROS:				(!=Obligatorio | ?=Opcional) (@=Pasar por referencia | v=Pasar por valor) (IN/OUT)
		* tcText					(!v IN    ) Texto a loguear
		* tnAppend					(!v IN    ) Indica si se debe agregar al final del log anterior (1) o en línea aparte (0)
		*--------------------------------------------------------------------------------------------------------------
		LPARAMETERS tcText, tnAppend

		#IF .F.
			LOCAL THIS AS CL_SCM_LIB OF 'FOXPRO_PLASTICSCM_DM.PRG'
		#ENDIF

		TRY
			tcText	= EVL(tcText,'')
			IF EVL(tnAppend,0) = 0
				tcText	= CR_LF + tcText
			ENDIF
			THIS.cTextLog	= THIS.cTextLog + tcText
		CATCH
		ENDTRY

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

		DECLARE SHORT SetFileAttributes IN kernel32 STRING tcFileName, INTEGER dwFileAttributes
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
