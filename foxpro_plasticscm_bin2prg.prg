*------------------------------------------------------------------------------
*-- FOXPRO_PLASTICSCM_BIN2PRG.PRG	- Visual FoxPro 9.0 DIFF/MERGE para PlasticSCM
*-- Fernando D. Bozzo				- 23/01/2014
*------------------------------------------------------------------------------
* PARÁMETROS:				(!=Obligatorio | ?=Opcional) (@=Pasar por referencia | v=Pasar por valor) (IN/OUT)
* tcSourcePath				(!v IN    ) Path del archivo origen
*--------------------------------------------------------------------------------------------------------------
LPARAMETERS tcSourcePath

#DEFINE CR_LF	CHR(13) + CHR(10)

TRY
	LOCAL loEx AS EXCEPTION, loTool AS CL_SCM_LIB OF 'FOXPRO_PLASTICSCM_DM.PRG'
	LOCAL lsBuffer, lnAddress, lnBufsize, lnPcount ;
		, lcOperation, lcSourcePath, lcDestinationPath, lcSourceSymbolic, lcDestinationSymbolic ;
		, lcBasePath, lcBaseSymbolic, lcOutputPath

	lnPcount	= PCOUNT()
	loEx		= NULL
	*tcTool		= UPPER( EVL( tcTool, 'DIFF' ) )
	loTool		= CREATEOBJECT('CL_SCM_LIB')
	_SCREEN.ADDPROPERTY( 'ExitCode', 0 )
	loTool.P_MakeBinAndCompile( @loEx, tcSourcePath )

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
	_SCREEN.ADDPROPERTY( 'ExitCode', 1 )
ENDIF

RELEASE loEx, loTool

IF _VFP.STARTMODE <= 1
	RETURN
ENDIF

IF _SCREEN.ExitCode = 1
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
		+ [<memberdata name="coperation" display="cOperation"/>] ;
		+ [<memberdata name="copyfile" display="CopyFile"/>] ;
		+ [<memberdata name="ctextlog" display="cTextLog"/>] ;
		+ [<memberdata name="deletefile" display="DeleteFile"/>] ;
		+ [<memberdata name="diffprocess" display="DiffProcess"/>] ;
		+ [<memberdata name="findworkspacefilename" display="FindWorkspaceFileName"/>] ;
		+ [<memberdata name="getsecondaryextensions" display="GetSecondaryExtensions"/>] ;
		+ [<memberdata name="initialize" display="Initialize"/>] ;
		+ [<memberdata name="ldebug" display="lDebug"/>] ;
		+ [<memberdata name="l_initialized" display="l_Initialized"/>] ;
		+ [<memberdata name="movefile" display="MoveFile"/>] ;
		+ [<memberdata name="normalizarcapitalizacionarchivos" display="normalizarCapitalizacionArchivos"/>] ;
		+ [<memberdata name="ofso" display="oFSO"/>] ;
		+ [<memberdata name="oshell" display="oShell"/>] ;
		+ [<memberdata name="o_foxbin2prg" display="o_FoxBin2Prg"/>] ;
		+ [<memberdata name="p_makebinandcompile" display="P_MakeBinAndCompile"/>] ;
		+ [<memberdata name="renamefile" display="RenameFile"/>] ;
		+ [<memberdata name="runcommand" display="RunCommand"/>] ;
		+ [<memberdata name="writelog" display="writeLog"/>] ;
		+ [</VFPData>]


	#IF .F.
		LOCAL THIS AS CL_SCM_LIB OF FOXPRO_PLASTICSCM_DM.PRG
	#ENDIF

	oShell			= NULL
	oFSO			= NULL
	o_FoxBin2Prg	= NULL
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
				SET PROCEDURE TO ( FORCEPATH( "FOXBIN2PRG.EXE", .cEXEPath ) ) ADDITIVE
				.o_FoxBin2Prg = CREATEOBJECT("c_FoxBin2Prg")
				.writeLog( 'sys(16)				=' + TRANSFORM(.cSys16) )
				.writeLog( 'cEXEPath			=' + TRANSFORM(.cEXEPath) )

				loShell			= .oShell
				lcPlasticSCM	= loShell.RegRead('HKEY_CLASSES_ROOT\plastic\shell\open\command\')
				.writeLog( 'lcPlasticSCM		=' + TRANSFORM(lcPlasticSCM) )

				IF EMPTY( lcPlasticSCM )
					.cCM	= '"cm.exe"'
				ELSE
					.cCM	= STRTRAN( STREXTRACT( lcPlasticSCM, '"', '"', 1, 4 ), 'plastic.exe', 'cm.exe' )
					.cPlasticPath		= JUSTPATH(.cCM)
				ENDIF

				.writeLog( REPLICATE('-',80) )

				.l_Initialized	= .T.
			ENDIF
		ENDWITH && THIS AS CL_SCM_LIB OF 'FOXPRO_PLASTICSCM_DM.PRG'
	ENDPROC


	PROCEDURE P_MakeBinAndCompile
		*--------------------------------------------------------------------------------------------------------------
		* REGENERA EL BINARIO Y LO RECOMPILA DESDE EL DIR BASE
		*--------------------------------------------------------------------------------------------------------------
		* PARÁMETROS:				(!=Obligatorio | ?=Opcional) (@=Pasar por referencia | v=Pasar por valor) (IN/OUT)
		* toEx						(?@    OUT) Objeto con información del error
		* tcSourcePath				(v! IN    ) Path del archivo origen
		*--------------------------------------------------------------------------------------------------------------
		LPARAMETERS toEx AS EXCEPTION, tcSourcePath

		TRY
			LOCAL lcMenError, lcTempFile, laWorkspace(1), lcWorkspaceDir, lcExt, lcCmd ;
				, loFSO AS Scripting.FileSystemObject ;
				, loStdIn AS Scripting.TextStream ;
				, loStdOut AS Scripting.TextStream ;
				, loStdErr AS Scripting.TextStream ;
				, loShell AS WScript.SHELL ;
				, loFB2P AS c_FoxBin2Prg OF FOXBIN2PRG.PRG

			WITH THIS AS CL_SCM_LIB OF 'FOXPRO_PLASTICSCM_DM.PRG'
				.writeLog( TTOC(DATETIME()) + '  ---' + PADR( PROGRAM(),77, '-' ) )
				toEx	= NULL

				.Initialize()

				loFSO	= .oFSO
				loShell	= .oShell
				loFB2P	= .o_FoxBin2Prg
				lcExt	= UPPER( JUSTEXT( tcSourcePath ) )
				.writeLog( 'Evaluando archivo [' + tcSourcePath + ']...' )

				IF INLIST( lcExt, 'PJX', 'VCX', 'SCX', 'FRX', 'LBX' )

					*-- OBTENGO EL WORKSPACE DEL ITEM
					*lcTempFile	= '"' + FORCEPATH('cm' + SYS(2015) + '.txt', SYS(2023)) + '"'
					*lcCmd		= GETENV("ComSpec") + " /C " + JUSTFNAME(.cCM) + ' lwk --format={2} > ' + lcTempFile
					*.writeLog( lcCmd )
					
					*loShell.RUN( lcCmd, 0, .T. )

					*FOR X = 1 TO ALINES(laWorkspace, FILETOSTR( lcTempFile ) )
					*	*.writeLog( 'Buscar [' + UPPER(ADDBS(laWorkspace(X))) + '] dentro de [' + ADDBS(UPPER(tcSourcePath)) + ']' )
					*	IF UPPER(ADDBS(laWorkspace(X))) $ ADDBS(UPPER(tcSourcePath)) THEN
					*		lcWorkspaceDir = laWorkspace(X)
					*		.writeLog( '- Encontrado workspace [' + UPPER(ADDBS(laWorkspace(X))) + ']' )
					*		EXIT
					*	ENDIF
					*ENDFOR

					*IF EMPTY(lcWorkspaceDir)
					*	ERROR "No se encontró el Workspace del archivo " + tcSourcePath
					*ENDIF

					*ERASE (lcTempFile)
					*CD (lcWorkspaceDir)

					*-- REGENERO EL BINARIO Y RECOMPILO
					.writeLog( '- Regenerando texto para archivo: ' + tcSourcePath )
					loFB2P.Ejecutar( tcSourcePath, '', '', '', '1', '1', '1', '', '', .T., '', '1' )
				ELSE
					.writeLog( '- Salteado por reglas internas' )
				ENDIF


				*-- CAPITALIZO EL NOMBRE DEL ARCHIVO
				*.normalizarCapitalizacionArchivos( laStdIn(1,2) )
				

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
			IF _VFP.StartMode = 0
				MESSAGEBOX( lcMenError, 0+16+4096, "ATENCIÓN!!", 60000 )
			ENDIF

		FINALLY
			THIS.writeLog( '' )

			STORE NULL TO loFSO, loShell, loFB2P
			RELEASE loFSO, loShell, loFB2P
			RELEASE PROCEDURE ( FORCEPATH( "FOXBIN2PRG.EXE", THIS.cEXEPath ) )

			CD (THIS.cEXEPath)
		ENDTRY

		RETURN
	ENDPROC


	PROCEDURE normalizarCapitalizacionArchivos
		*--------------------------------------------------------------------------------------------------------------
		* NORMALIZA Y RENOMBRA EL ARCHIVO INDICADO
		*--------------------------------------------------------------------------------------------------------------
		* PARÁMETROS:				(!=Obligatorio | ?=Opcional) (@=Pasar por referencia | v=Pasar por valor) (IN/OUT)
		* tcFileName				(!v IN    ) Nombre del archivo a normalizar
		*--------------------------------------------------------------------------------------------------------------
		LPARAMETERS tcFilename

		TRY
			LOCAL lcPath, lcEXE_CAPS, lcOutputFile ;
				, loFSO AS Scripting.FileSystemObject
			lcPath		= JUSTPATH(THIS.cSys16)
			lcEXE_CAPS	= FORCEPATH( 'filename_caps.exe', lcPath )
			loFSO		= THIS.oFSO

			IF FILE(lcEXE_CAPS)
				THIS.writeLog( '* Se ha encontrado el programa de capitalización de nombres [' + lcEXE_CAPS + ']' )
			ELSE
				*-- No existe el programa de capitalización, así que no se capitalizan los nombres.
				THIS.writeLog( '* No se ha encontrado el programa de capitalización de nombres [' + lcEXE_CAPS + ']' )
				EXIT
			ENDIF

			THIS.RenameFile( tcFilename, lcEXE_CAPS, loFSO )
		ENDTRY

		RETURN
	ENDPROC


	PROCEDURE RenameFile
		*--------------------------------------------------------------------------------------------------------------
		* RENOMBRA UN ARCHIVO
		*--------------------------------------------------------------------------------------------------------------
		* PARÁMETROS:				(!=Obligatorio | ?=Opcional) (@=Pasar por referencia | v=Pasar por valor) (IN/OUT)
		* tcFileName				(!v IN    ) Nombre del archivo a renombrar
		* tcEXE_CAPS				(!v IN    ) Nombre del ejecutable de capitalización a usar
		* toFSO						(!v IN    ) Instancia del objeto Scripting.FileSystemObject
		*--------------------------------------------------------------------------------------------------------------
		LPARAMETERS tcFilename, tcEXE_CAPS, toFSO AS Scripting.FileSystemObject

		LOCAL lcLog, laFile(1,5)
		THIS.writeLog( '- Se ha solicitado capitalizar el archivo [' + tcFilename + ']' )
		lcLog	= ''
		DO (tcEXE_CAPS) WITH tcFilename, '', 'F', lcLog, .T.
		IF ADIR( laFile, tcFilename, '', 1 ) > 0 AND laFile(1,1) <> JUSTFNAME(tcFilename)
			toFSO.MoveFile( FORCEPATH( laFile(1,1), JUSTPATH(tcFilename) ), tcFilename )
			THIS.writeLog( '  => Se renombrará a [' + tcFilename + ']' )
		ELSE
			THIS.writeLog( '  => No se renombrará a [' + tcFilename + '] porque ya estaba correcto.' )
		ENDIF
		THIS.writeLog( '  => Se renombrará a [' + tcFilename + ']' )
	ENDPROC


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
		LPARAMETERS  tcFilename, tcAttrib
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
		dwFileAttributes = GetFileAttributes(tcFilename)

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
			=SetFileAttributes(tcFilename, dwFileAttributes)
		ENDIF
	ENDPROC


ENDDEFINE
