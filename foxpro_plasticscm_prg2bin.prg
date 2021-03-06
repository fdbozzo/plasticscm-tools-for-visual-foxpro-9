*------------------------------------------------------------------------------
*-- FOXPRO_PLASTICSCM_PRG2BIN.PRG	- Visual FoxPro 9.0 DIFF/MERGE para PlasticSCM
*-- Fernando D. Bozzo				- 23/01/2014
*------------------------------------------------------------------------------
* PARÁMETROS:				(!=Obligatorio | ?=Opcional) (@=Pasar por referencia | v=Pasar por valor) (IN/OUT)
* tcSourcePath				(!v IN    ) Path del archivo origen
*--------------------------------------------------------------------------------------------------------------
LPARAMETERS tcSourcePath

#DEFINE C_CR	CHR(13)
#DEFINE C_LF	CHR(10)
#DEFINE CR_LF	C_CR + C_LF

TRY
	LOCAL loEx AS EXCEPTION, loTool AS CL_SCM_2_LIB OF FOXPRO_PLASTICSCM_PRG2BIN.PRG
	LOCAL lsBuffer, lnAddress, lnBufsize, lnPcount ;
		, lcOperation, lcSourcePath, lcDestinationPath, lcSourceSymbolic, lcDestinationSymbolic ;
		, lcBasePath, lcBaseSymbolic, lcOutputPath

	lnPcount	= PCOUNT()
	loEx		= NULL

	IF NOT 'FOXPRO_PLASTICSCM_DM.' $ SET("Procedure")
		SET PROCEDURE TO (FORCEPATH( 'FOXPRO_PLASTICSCM_DM.EXE', JUSTPATH(SYS(16)) ) )
	ENDIF

	*tcTool		= UPPER( EVL( tcTool, 'DIFF' ) )
	loTool		= CREATEOBJECT('CL_SCM_2_LIB')
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


*DEFINE CLASS CL_SCM_2_LIB AS CL_SCM_LIB OF 'FOXPRO_PLASTICSCM_DM.PRG'	&& For Debugging
DEFINE CLASS CL_SCM_2_LIB AS CL_SCM_LIB OF 'FOXPRO_PLASTICSCM_DM.EXE'
	_MEMBERDATA	= [<VFPData>] ;
		+ [<memberdata name="p_makebinandcompile" display="P_MakeBinAndCompile"/>] ;
		+ [<memberdata name="procesararchivospendientes" display="ProcesarArchivosPendientes"/>] ;
		+ [</VFPData>]


	#IF .F.
		LOCAL THIS AS CL_SCM_2_LIB OF 'FOXPRO_PLASTICSCM_PRG2BIN.PRG'
	#ENDIF

	cOperation		= 'REGEN'


	PROCEDURE P_MakeBinAndCompile
		*--------------------------------------------------------------------------------------------------------------
		* REGENERA EL BINARIO Y LO RECOMPILA DESDE EL DIR BASE
		*--------------------------------------------------------------------------------------------------------------
		* PARÁMETROS:				(!=Obligatorio | ?=Opcional) (@=Pasar por referencia | v=Pasar por valor) (IN/OUT)
		* toEx						(?@    OUT) Objeto con información del error
		* tcSourcePath				(v! IN    ) Path del archivo origen
		* tcWorkspaceDir			(v? IN    ) Path del workspace
		*--------------------------------------------------------------------------------------------------------------
		LPARAMETERS toEx AS EXCEPTION, tcSourcePath, tcWorkspaceDir

		TRY
			LOCAL lcMenError, lcTempFile, lcExt, lcCmd, llPreInit, lcDebug, lcDontShowProgress, lcDontShowErrors ;
				, llProcessed ;
				, loFB2P AS c_FoxBin2Prg OF 'FOXBIN2PRG.PRG'

			WITH THIS AS CL_SCM_2_LIB OF FOXPRO_PLASTICSCM_PRG2BIN.PRG
				llPreInit	= .l_Initialized
				.Initialize()
				loFB2P		= .o_FoxBin2Prg
				lcExt		= UPPER( JUSTEXT( tcSourcePath ) )
				toEx		= NULL

				loFB2P.evaluateConfiguration( '','','','','','','','', tcSourcePath )

				DO CASE
				CASE NOT loFB2P.hasSupport_Prg2Bin( lcExt )
					.writeLog( '- Salteado por no tener soporte para conversión (' + tcSourcePath + ')' )

				CASE loFB2P.wasProcessed( tcSourcePath )
					.writeLog( '- Salteado por haber sido procesado anteriormente (' + tcSourcePath + ')' )

				OTHERWISE
					IF NOT llPreInit
						.writeLog( TTOC(DATETIME()) + '  ---' + PADR( PROGRAM(),77, '-' ) )
					ENDIF

					*-- OBTENGO EL WORKSPACE DEL ITEM
					IF EMPTY(tcWorkspaceDir)
						tcWorkspaceDir	= .ObtenerWorkspaceDir(tcSourcePath)
					ENDIF

					*-- REGENERO EL BINARIO Y RECOMPILO
					.writeLog( '- Regenerando binario para archivo [' + tcSourcePath + ']...' )
					lcDebug				= ''
					lcDontShowProgress	= '1'
					lcDontShowErrors	= '1'
					*loFB2P.execute( tc_InputFile, tcType, tcTextName, tlGenText, tcDontShowErrors, tcDebug, tcDontShowProgress ;
					, toModulo, toEx, tlRelanzarError, tcOriginalFileName, tcRecompile, tcNoTimestamps)
					loFB2P.execute( tcSourcePath, 'PRG2BIN', '', '', lcDontShowErrors, lcDebug, lcDontShowProgress ;
						, '', '', .T., '', tcWorkspaceDir, '' )
					llProcessed	= .T.
				ENDCASE

			ENDWITH && THIS AS CL_SCM_LIB OF 'FOXPRO_PLASTICSCM_DM.PRG'

		CATCH TO toEx WHEN toEx.MESSAGE = '0'
			toEx	= NULL

		CATCH TO toEx WHEN toEx.ErrorNo = 1799	&& Conversion Cancelled

		CATCH TO toEx WHEN INLIST(toEx.ErrorNo, 1098, 2071)	&& Errores controlados

		CATCH TO toEx WHEN loFB2P.l_Error	&& Demás errores reportados por FoxBin2Prg

		CATCH TO toEx
			THROW

		FINALLY
			STORE NULL TO loFB2P

			*IF NOT llPreInit
			*	RELEASE PROCEDURE ( FORCEPATH( "FOXBIN2PRG.EXE", THIS.cEXEPath ) )
			*ENDIF

			*CD (THIS.cEXEPath)
		ENDTRY

		RETURN llProcessed
	ENDPROC


	PROCEDURE ProcesarArchivosPendientes
		LPARAMETERS tcFileName

		TRY
			LOCAL lcMenError, lnFileCount, lcWorkspaceDir, laFiles(1), I, lnProcesados, llUserCanceled ;
				, loLang as CL_LANG OF 'FOXBIN2PRG.PRG' ;
				, loException AS EXCEPTION ;
				, loFB2P AS c_FoxBin2Prg OF 'FOXBIN2PRG.PRG'

			WITH THIS AS CL_SCM_LIB OF 'FOXPRO_PLASTICSCM_PRG2BIN.PRG'
				STORE 0 TO lnProcesados, I
				.Initialize()
				loLang			= _SCREEN.o_FoxBin2Prg_Lang
				lcWorkspaceDir	= .ObtenerWorkspaceDir( tcFileName )
				loFB2P			= .o_FoxBin2Prg
				.ObtenerCambiosPendientes( lcWorkspaceDir, @laFiles, @lnFileCount )
				.writeLog()
				.writeLog( TTOC(DATETIME()) + '  ---' + PADR( PROGRAM(),77, '-' ) )
				.writeLog( 'Encontrados ' + TRANSFORM(lnFileCount) + ' archivos para filtrar y procesar' )
				.writeLog( 'Se recompilará desde ' + lcWorkspaceDir )

				loFB2P.loadProgressbarForm()
				loFB2P.o_Frm_Avance.CAPTION	= STRTRAN(loFB2P.o_Frm_Avance.CAPTION,'FoxBin2Prg','Prg>Bin') + ' - WKS [' + lcWorkspaceDir + ']'
				loFB2P.o_Frm_Avance.ALWAYSONTOP = .T.
				*loFB2P.o_Frm_Avance.ALWAYSONTOP = .F.

				FOR I = 1 TO lnFileCount
					loFB2P.o_Frm_Avance.updateProgressbar( 'Procesando ' + laFiles(I) +  '...', I, lnFileCount, 0 )

					IF .P_MakeBinAndCompile( @loException, laFiles(I), lcWorkspaceDir )
						lnProcesados	= lnProcesados + 1
					ENDIF

					IF VARTYPE(loException) = "O" AND loException.ErrorNo = 1799 THEN	&& Conversion Cancelled
						llUserCanceled	= .T.
						EXIT
					ENDIF

					.FlushLog()
				ENDFOR

				*loFB2P.o_Frm_Avance.HIDE()

				IF lnProcesados = 0
					IF loFB2P.c_Language = "ES"
						THIS.c_TextError	= 'Hay 0 Cambios Pendientes para Procesar!'
					ELSE
						THIS.c_TextError	= 'There are 0 pending changes to Process!'
					ENDIF
				ELSE
					IF loFB2P.c_Language = "ES"
						THIS.c_TextError	= 'Se han procesado ' + TRANSFORM(lnProcesados) + ' Cambios Pendientes.'
					ELSE
						THIS.c_TextError	= '' + TRANSFORM(lnProcesados) + ' Pending Changes have been Processed.'
					ENDIF
				ENDIF

			ENDWITH && THIS

		CATCH TO loException
			THIS.l_Error		= .T.
			lcMenError	= 'Error ' + TRANSFORM(loException.ERRORNO) + ', ' + loException.MESSAGE + CR_LF ;
				+ ', Proced.' + loException.PROCEDURE + ', line ' + TRANSFORM(loException.LINENO) + CR_LF ;
				+ ', content: ' + loException.LINECONTENTS + CR_LF ;
				+ ' - para el archivo "' + IIF(I=0,tcFileName,laFiles(I)) + '"' + CR_LF ;
				+ loException.USERVALUE
			THIS.c_TextError	= lcMenError
			THIS.writeLog( lcMenError )

		FINALLY
			IF VARTYPE(loFB2P) = "O" AND NOT ISNULL(loFB2P) THEN
				loFB2P.unloadProgressbarForm(.T.)
				loFB2P	= NULL
			ENDIF

		ENDTRY

		RETURN

	ENDPROC


	PROCEDURE ProcesarArchivos
		LPARAMETERS tcFileName

		TRY
			LOCAL lcMenError, lnFileCount, lcWorkspaceDir, laFiles(1), I, lnProcesados, llUserCanceled ;
				, loLang as CL_LANG OF 'FOXBIN2PRG.PRG' ;
				, loException AS EXCEPTION ;
				, loFB2P AS c_FoxBin2Prg OF 'FOXBIN2PRG.PRG'

			WITH THIS AS CL_SCM_LIB OF 'FOXPRO_PLASTICSCM_DM.PRG'
				STORE 0 TO lnProcesados, I
				.Initialize()
				loLang			= _SCREEN.o_FoxBin2Prg_Lang
				lcWorkspaceDir	= .ObtenerWorkspaceDir( tcFileName )
				loFB2P			= .o_FoxBin2Prg
				.ObtenerArchivosDelDirectorio( lcWorkspaceDir, @laFiles, @lnFileCount )
				.writeLog()
				.writeLog( TTOC(DATETIME()) + '  ---' + PADR( PROGRAM(),77, '-' ) )
				.writeLog( 'Encontrados ' + TRANSFORM(lnFileCount) + ' archivos para filtrar y procesar' )
				.writeLog( 'Se recompilará desde ' + lcWorkspaceDir )

				loFB2P.loadProgressbarForm()
				loFB2P.o_Frm_Avance.CAPTION	= STRTRAN(loFB2P.o_Frm_Avance.CAPTION,'FoxBin2Prg','Prg>Bin') + ' - WKS [' + lcWorkspaceDir + ']'
				loFB2P.o_Frm_Avance.ALWAYSONTOP = .T.
				*loFB2P.o_Frm_Avance.ALWAYSONTOP = .F.

				FOR I = 1 TO lnFileCount
					loFB2P.o_Frm_Avance.updateProgressbar( 'Procesando ' + laFiles(I) +  '...', I, lnFileCount, 0 )

					IF .P_MakeBinAndCompile( @loException, laFiles(I), lcWorkspaceDir )
						lnProcesados	= lnProcesados + 1
					ENDIF

					IF VARTYPE(loException) = "O" AND loException.ErrorNo = 1799 THEN	&& Conversion Cancelled
						llUserCanceled	= .T.
						EXIT
					ENDIF

					.FlushLog()
				ENDFOR

			ENDWITH && THIS

		CATCH TO loException
			THIS.l_Error		= .T.
			lcMenError	= 'Error ' + TRANSFORM(loException.ERRORNO) + ', ' + loException.MESSAGE + CR_LF ;
				+ ', Proced.' + loException.PROCEDURE + ', line ' + TRANSFORM(loException.LINENO) + CR_LF ;
				+ ', content: ' + loException.LINECONTENTS + CR_LF ;
				+ ' - para el archivo "' + IIF(I=0,tcFileName,laFiles(I)) + '"' + CR_LF ;
				+ loException.USERVALUE
			THIS.c_TextError	= lcMenError
			THIS.writeLog( lcMenError )

		FINALLY
			IF VARTYPE(loFB2P) = "O" AND NOT ISNULL(loFB2P) THEN
				loFB2P.unloadProgressbarForm(.T.)
				loFB2P	= NULL
			ENDIF

		ENDTRY

		RETURN

	ENDPROC

ENDDEFINE
