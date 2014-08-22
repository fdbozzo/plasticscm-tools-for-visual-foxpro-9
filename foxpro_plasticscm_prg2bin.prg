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
				, loFB2P AS c_FoxBin2Prg OF FOXBIN2PRG.PRG

			WITH THIS AS CL_SCM_2_LIB OF FOXPRO_PLASTICSCM_PRG2BIN.PRG
				llPreInit	= .l_Initialized
				.Initialize()
				loFB2P		= .o_FoxBin2Prg
				lcExt		= UPPER( JUSTEXT( tcSourcePath ) )
				toEx		= NULL

				*-- FILTRO LAS EXTENSIONES PERMITIDAS (EXCLUYO LOS DBFs Y DBCs)
				*IF INLIST( lcExt, loFB2P.c_VC2, loFB2P.c_SC2, loFB2P.c_FR2, loFB2P.c_LB2, loFB2P.c_MN2 )
				loFB2P.EvaluarConfiguracion( '','','','','','','','', tcSourcePath )
				IF loFB2P.TieneSoporte_Prg2Bin( lcExt ) THEN
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
					lcDontShowErrors	= '0'
					*loFB2P.Ejecutar( tc_InputFile, tcType, tcTextName, tlGenText, tcDontShowErrors, tcDebug, tcDontShowProgress ;
					, toModulo, toEx, tlRelanzarError, tcOriginalFileName, tcRecompile, tcNoTimestamps)
					loFB2P.Ejecutar( tcSourcePath, '', '', '', lcDontShowErrors, lcDebug, lcDontShowProgress ;
						, '', '', .T., '', tcWorkspaceDir, '' )
					llProcessed	= .T.
				ELSE
					.writeLog( '- Salteado por reglas internas (' + tcSourcePath + ')' )
				ENDIF


				*-- CAPITALIZO EL NOMBRE DEL ARCHIVO
				*.normalizarCapitalizacionArchivos( tcSourcePath )


			ENDWITH && THIS AS CL_SCM_LIB OF 'FOXPRO_PLASTICSCM_DM.PRG'

		CATCH TO toEx WHEN toEx.MESSAGE = '0'
			toEx	= NULL

		CATCH TO toEx
			THIS.l_Error		= .T.
			lcMenError	= 'CurDir: ' + SYS(5)+CURDIR() + CR_LF ;
				+ 'Error ' + TRANSFORM(toEx.ERRORNO) + ', ' + toEx.MESSAGE + CR_LF ;
				+ toEx.PROCEDURE + ', line ' + TRANSFORM(toEx.LINENO) + CR_LF ;
				+ toEx.LINECONTENTS + CR_LF ;
				+ toEx.USERVALUE
			THIS.c_TextError	= lcMenError
			THIS.writeLog( lcMenError )
			IF _VFP.STARTMODE = 0
				MESSAGEBOX( lcMenError, 0+16+4096, "ATENCIÓN!!", 60000 )
			ENDIF

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
			LOCAL lcMenError, lnFileCount, lcWorkspaceDir, laFiles(1), I, loException AS EXCEPTION ;
				, loFB2P AS c_FoxBin2Prg OF FOXBIN2PRG.PRG

			WITH THIS AS CL_SCM_LIB OF 'FOXPRO_PLASTICSCM_PRG2BIN.PRG'
				.Initialize()
				lcWorkspaceDir	= .ObtenerWorkspaceDir( tcFileName )
				loFB2P			= .o_FoxBin2Prg
				.ObtenerCambiosPendientes( lcWorkspaceDir, @laFiles, @lnFileCount )
				.writeLog( TTOC(DATETIME()) + '  ---' + PADR( PROGRAM(),77, '-' ) )
				.writeLog( 'Encontrados ' + TRANSFORM(lnFileCount) + ' archivos para filtrar y procesar' )
				.writeLog( 'Se recompilará desde ' + lcWorkspaceDir )

				*MESSAGEBOX( 'Se recompilará desde ' + lcWorkspaceDir + ' ' + TRANSFORM(lnFileCount) + ' archivo(s)', 64+4096, PROGRAM() )
				*EXIT

				loFB2P.cargar_frm_avance()
				loFB2P.o_Frm_Avance.nMAX_VALUE = lnFileCount
				loFB2P.o_Frm_Avance.nVALUE = 0
				loFB2P.o_Frm_Avance.CAPTION	= loFB2P.o_Frm_Avance.CAPTION + ' - Prg>Bin (Press Esc to Cancel) WS:' + lcWorkspaceDir
				loFB2P.o_Frm_Avance.ALWAYSONTOP = .T.
				loFB2P.o_Frm_Avance.SHOW()
				loFB2P.o_Frm_Avance.ALWAYSONTOP = .F.

				FOR I = 1 TO lnFileCount
					loFB2P.o_Frm_Avance.lbl_TAREA.CAPTION = 'Procesando ' + laFiles(I) +  '...'
					loFB2P.o_Frm_Avance.nVALUE = I
					INKEY()
					.P_MakeBinAndCompile( '', laFiles(I), lcWorkspaceDir )

					IF LASTKEY()=27
						.writeLog( 'USER CANCEL REQUEST.' )
						EXIT
					ENDIF

					.FlushLog()
				ENDFOR

				loFB2P.o_Frm_Avance.HIDE()

				IF lnFileCount = 0
					IF loFB2P.c_Language = "ES"
						THIS.c_TextError	= 'Hay 0 Cambios Pendientes para Procesar!' + C_CR + C_CR + '> Cambie a la vista de Cambios Pendientes para usar este script de Cambios Pendientes.'
					ELSE
						THIS.c_TextError	= 'There are 0 pending changes to Process!' + C_CR + C_CR + '> Switch to Pending Changes view to use this Pending Changes script.'
					ENDIF
				ELSE
					IF loFB2P.c_Language = "ES"
						THIS.c_TextError	= 'Se han procesado ' + TRANSFORM(lnFileCount) + ' Cambios Pendientes.'
					ELSE
						THIS.c_TextError	= '' + TRANSFORM(lnFileCount) + ' Pending Changes have been Processed.'
					ENDIF
				ENDIF

				loFB2P.o_Frm_Avance	= NULL
				loFB2P	= NULL
			ENDWITH && THIS

		CATCH TO loException
			THIS.l_Error		= .T.
			lcMenError	= 'Error ' + TRANSFORM(loException.ERRORNO) + ', ' + loException.MESSAGE + CR_LF ;
				+ ', Proced.' + loException.PROCEDURE + ', line ' + TRANSFORM(loException.LINENO) + CR_LF ;
				+ ', content: ' + loException.LINECONTENTS + CR_LF ;
				+ ' - para el archivo "' + tcFileName + '"' + CR_LF ;
				+ loException.USERVALUE
			THIS.c_TextError	= lcMenError
			THIS.writeLog( lcMenError )

		ENDTRY

		RETURN

	ENDPROC


	PROCEDURE ProcesarArchivos
		LPARAMETERS tcFileName

		TRY
			LOCAL lcMenError, lnFileCount, lcWorkspaceDir, laFiles(1), I, loException AS EXCEPTION ;
				, loFB2P AS c_FoxBin2Prg OF FOXBIN2PRG.PRG

			WITH THIS AS CL_SCM_LIB OF 'FOXPRO_PLASTICSCM_DM.PRG'
				.Initialize()
				lcWorkspaceDir	= .ObtenerWorkspaceDir( tcFileName )
				loFB2P			= .o_FoxBin2Prg
				.ObtenerArchivosDelDirectorio( lcWorkspaceDir, @laFiles, @lnFileCount )
				.writeLog( TTOC(DATETIME()) + '  ---' + PADR( PROGRAM(),77, '-' ) )
				.writeLog( 'Encontrados ' + TRANSFORM(lnFileCount) + ' archivos para filtrar y procesar' )
				.writeLog( 'Se recompilará desde ' + lcWorkspaceDir )

				*MESSAGEBOX( 'Se recompilará desde ' + lcWorkspaceDir + ' ' + TRANSFORM(lnFileCount) + ' archivo(s)', 64+4096, PROGRAM() )
				*EXIT

				loFB2P.cargar_frm_avance()
				loFB2P.o_Frm_Avance.nMAX_VALUE = lnFileCount
				loFB2P.o_Frm_Avance.nVALUE = 0
				loFB2P.o_Frm_Avance.CAPTION	= loFB2P.o_Frm_Avance.CAPTION + ' - Prg>Bin (Press Esc to Cancel) WS:' + lcWorkspaceDir
				loFB2P.o_Frm_Avance.ALWAYSONTOP = .T.
				loFB2P.o_Frm_Avance.SHOW()
				loFB2P.o_Frm_Avance.ALWAYSONTOP = .F.

				FOR I = 1 TO lnFileCount
					loFB2P.o_Frm_Avance.lbl_TAREA.CAPTION = 'Procesando ' + laFiles(I) +  '...'
					loFB2P.o_Frm_Avance.nVALUE = I
					INKEY()
					.P_MakeBinAndCompile( '', laFiles(I), lcWorkspaceDir )

					IF LASTKEY()=27
						.writeLog( 'USER CANCEL REQUEST.' )
						EXIT
					ENDIF

					.FlushLog()
				ENDFOR

				loFB2P.o_Frm_Avance.HIDE()
				loFB2P.o_Frm_Avance	= NULL
				loFB2P	= NULL
			ENDWITH && THIS

		CATCH TO loException
			THIS.l_Error		= .T.
			lcMenError	= 'Error ' + TRANSFORM(loException.ERRORNO) + ', ' + loException.MESSAGE + CR_LF ;
				+ ', Proced.' + loException.PROCEDURE + ', line ' + TRANSFORM(loException.LINENO) + CR_LF ;
				+ ', content: ' + loException.LINECONTENTS + CR_LF ;
				+ ' - para el archivo "' + tcFileName + '"' + CR_LF ;
				+ loException.USERVALUE
			THIS.c_TextError	= lcMenError
			THIS.writeLog( lcMenError )

		ENDTRY

		RETURN

	ENDPROC

ENDDEFINE
