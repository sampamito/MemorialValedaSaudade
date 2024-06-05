#include "TbiConn.ch"
#include "TbiCode.ch"
#include "protheus.ch"
#INCLUDE "topconn.ch"


#IFNDEF WINDOWS
#DEFINE PSAY SAY
#ENDIF

/*-------------------------------------------------------------------
- Programa: ACOMP003
- Autor: TBC
- Data: 08/09/2020
- Descrição: WF de Aprovação de Pedidos de Compra
-------------------------------------------------------------------*/

User Function ACOMP003( nOpcao, oProcess )

	Local nWf			:= 0
	Private bXMSAPRO 	:= SuperGetMV("MV_XMSAPRO")
	Private cxFilial 	:= ""
	Private cCodLiber	:="000000"
	Private cNivelApr	:=""
	Private lLiberou    := .F.
	Private lJob		:= IsBlind()
	private aMail		:= {}

	default nOpcao		:= 0 

	if valtype(bXMSAPRO) != "L"
		Aviso("Atenção","Parametro MV_XMSAPRO cadastrado errado, verifique se o tipo e valor é LOGICO! O E-mai de WORKFLOW não será enviado!",{"OK"})
		Return
	endif

	If ValType(nOpcao) = "A"
		nOpcao := nOpcao[1]
	Endif

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Declaracao de variaveis utilizadas no programa atraves da funcao    ³
	//³ SetPrvt, que criara somente as variaveis definidas pelo usuario,    ³
	//³ identificando as variaveis publicas do sistema utilizadas no codigo ³
	//³ Incluido pelo assistente de conversao do AP5 IDE                    ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

	SetPrvt("CPAR,NBARRA,N_ITEM,C_MAT,C_DEST,CGRAP")
	SetPrvt("C_NUM,C_MOTIVO,N_TOTPC,CGRAPANT,N_TERMINA,N_DOHTML")
	SetPrvt("CRAIZ,NRET,NHLDHTM,NHLDSCP,CIND,C_PCANT")
	SetPrvt("N_QTDPC,N_FRTPC,A_ITENS,LCABEC,_AREGISTROS,NLIMITE")
	SetPrvt("CAB_NUM,CAB_EMIS,CAB_FORN,CAB_COND,CAB_NOME,_NI")
	SetPrvt("ARRAYCAB,ARRAYITENS,C_ITPED,NPRESUP,CAPROV,AINFO")
	SetPrvt("CMAILAP,CNOMEAP,CORIGEM,CABEC,NHDLVLR,NCOUNT")
	SetPrvt("NRESULT,CHTML,NHDLCONNECT")

	Do Case

		Case nOpcao == 0

			SPCAprovador( SC7->C7_NUM, @aMail )

			oProcess := nil

			for nWf := 1 to len( aMail )

				if aMail[nWf,5] <> "U" .and. oProcess == Nil
					oProcess := TWFProcess():New( OEMTOANSI("PEDCOM"), "Pedido de Compras" )
				elseif aMail[nWf,5] $ "U"
					oProcess := nil
					oProcess := TWFProcess():New( OEMTOANSI("PEDCOM"), "Pedido de Compras" )
				endIf

				SPCIniciar( oProcess,,,nWf )

			next nWf

		Case nOpcao == 1

			SPCRetorno( oProcess )

		Case nOpcao == 2

		SPCTimeOut( oProcess )

	EndCase

	if oProcess # Nil 
		oProcess:Free()
	endIf

RETURN

/*Faz a Liberação Automática do Pedido*/
//========================================
Static Function SPCRetorno( oProcess )
//========================================

	Local aCodAprov 	:= {}
	Local nQtdAprov  	:= 0
	Local nIni			:= 1
	Local cNumSCR		:= ""
	local lAlcPedCTB  	:= superGetMv("MV_APRPCEC",.F.,.F.) 
	Local lSaldoOk 		:= .F.
	Local x				:= 0 
	Local y				:= 0
	local nCnt := 0
	if lAlcPedCTB
		cTipo := "IP"
	else
		cTipo := "PC"
	endIf

	RastreiaWF(oProcess:fProcessID+'.'+oProcess:fTaskID,oProcess:fProcCode,'10002',,"BI")
	
	cNum		:= alltrim(oProcess:oHtml:RetByName('Pedido'))
	cxFilial	:= oProcess:oHtml:RetByName('FILIAL')
	cResp		:= oProcess:oHtml:RetByName('RBAPROVA')
	cJusti		:= oProcess:oHtml:RetByName('lbmotivo')
	codAprov	:= oProcess:oHtml:RetByName("lb_aprovador")
    

	nQtdAprov := Len(codAprov)/6 // Busca quantidade de aprovadores

	For x := 1 to nQtdAprov
		AADD(aCodAprov,substr(codAprov,nIni,6))
		U_UCLogMsg("INICIO DE RETORNO WF APROVAÇÃO ( WF APROVAÇÃO - SPCRetorno) Data: "+dtoc(ddatabase)+ "Hora: "+time()+" aCodAprov"+CVALTOCHAR(x)+": "+ substr(codAprov,nIni,6))
		nIni := nIni+6
	Next x

	dbSelectArea("SC7")
	SC7->(dbSetOrder(1))
	SC7->(dbgotop())

	if SC7->(dbSeek(cxFilial+cNum))

		cGrupo := SC7->C7_APROV
		cPCLib := SC7->C7_NUM
		cPCUser:= SC7->C7_USER

	else
		U_UCLogMsg("INICIO DE RETORNO WF APROVAÇÃO ( WF APROVAÇÃO - SPCRetorno) Data: "+dtoc(ddatabase)+ "Hora: "+time()+" Não achou SC7 (1) cxFilial+cNum: "+ cxFilial+cNum)
	endif

	If Select("SC7") > 0
		SC7->(dbCloseArea())
	EndIf
	
		if cResp == '1'
		nOpc:=2 //Libera
		else
			nOpc:=3 //Bloqueia
		endif
	
	dbSelectArea("SCR")
	SCR->(dbSetOrder(2))
	SCR->(dbgotop())

	If TamSx3("CR_NUM")[1] > LEN(cNum)
		cNumSCR := cNum+(Space(TamSx3("CR_NUM")[1]-LEN(cNum)))
	Else
		cNumSCR := LEN(cNum)
	EndIf

	For y := 1 to Len(aCodAprov)

		if SCR->(dbSeek(cxFilial+cTipo+cNumSCR+AllTrim(aCodAprov[y]))) .AND. !EMPTY(aCodAprov[y])

			nTotal    	:= SCR->CR_TOTAL
			cAprov    	:= SCR->CR_APROV
			cCodLiber	:=SCR->CR_USER
			cNivelApr	:=SCR->CR_NIVEL
			aSaldo 		:= MaSalAlc(cAprov,dDataBase,.T.)
			nSaldo 		:= aSaldo[1]

			If nSaldo >= SCR->CR_TOTAL
				lSaldoOk := .T.
			Endif

			lLiberou := MaAlcDoc({SCR->CR_NUM,SCR->CR_TIPO,SCR->CR_TOTAL,cAprov,,cGrupo,,,,,cJusti},date(),If(nOpc==2,4,6))

			if lLiberou

				If lSaldoOk

					if SCR->( recLock("SCR",.F.) )
						SCR->CR_WF := "2"
						SCR->( msUnlock() )
					endIf

				Endif

			else

				if SCR->( recLock("SCR",.F.) )
					SCR->CR_WF := "3"
					SCR->( msUnlock() )
				endIf

			endif

			Exit

		else
			U_UCLogMsg("RETORNO WF APROVAÇÃO ( WF APROVAÇÃO - SPCRetorno ) Data: "+dtoc(ddatabase)+ "Hora: "+time()+" Não achou SCR(xxx): "+ cxFilial+cTipo+cNum+aCodAprov[y])
		endif

	Next y

	If lLiberou

		If lSaldoOk

			If Select("SC7") > 0
				SC7->(dbCloseArea())
			EndIf

			dbselectarea("SC7")
			SC7->(dbSetOrder(1))
			SC7->(dbgotop())
			SC7->(dbseek(cxFilial+cNum))

			While !SC7->(Eof())

				if SC7->C7_FILIAL+SC7->C7_NUM  == cxFilial+cNum

					U_UCLogMsg("( WF APROVAÇÃO - SPCRetorno ) Data: "+dtoc(ddatabase)+ "Hora: "+time()+"Filial:" +SC7->C7_FILIAL+" Pedido:"+SC7->C7_NUM+" Valor do SC7->C7_CONAPRO: "+SC7->C7_CONAPRO )
					U_UCLogMsg("( WF APROVAÇÃO - SPCRetorno ) Data: "+dtoc(ddatabase)+ "Hora: "+time()+" Valor do SC7->C7_OBS: "+alltrim(SC7->C7_OBS)+" Valor do SC7->C7_CONAPRO: "+alltrim(SC7->C7_CONAPRO))

					if Reclock("SC7",.F.)
						SC7->C7_CONAPRO := "L"
						SC7->C7_OBS := AllTrim(SC7->C7_OBS)+"/"+cJusti
						SC7->(MsUnlock())
					endif
					
				endif

				SC7->(dbSkip())

			EndDo

			RastreiaWF(oProcess:fProcessID+'.'+oProcess:fTaskID,oProcess:fProcCode,'10005',,"BI")

			//finaliza o processo
			oProcess:Finish()

		Else
			U_UCLogMsg("( WF APROVAÇÃO - SPCRetorno ) O aprovador não possui saldo suficiente: "+cAprov )
		Endif

	Else

		//nOpc=2 finaliza o processo atual e re-inicia um novo
		//nOpc=3 finaliza o processo atual e bloqueia o pedido
		RastreiaWF(oProcess:fProcessID+'.'+oProcess:fTaskID,oProcess:fProcCode,iif(nOpc==2,'10003','10004'),,"BI")
		oProcess:Finish()

		dbSelectArea("SC7")
		if nOpc == 2

			SC7->(dbgotop())
			SC7->(dbSetOrder(1))
			SC7->(dbseek(cxFilial+cNum))

			U_UCLogMsg(" ( WF APROVAÇÃO - SPCRetorno ) Data: "+dtoc(ddatabase)+ "Hora: "+time()+" - Iniciando processo para o proximo nivel de aprovacao" )
			oProcess := TWFProcess():New( OEMTOANSI("PEDCOM"), "Pedido de Compras" )

			U_UCLogMsg(" ( WF APROVAÇÃO - SPCRetorno ) Data: "+dtoc(ddatabase)+ "Hora: "+time()+" - Entrando no SPCIniciar" )
			SPCIniciar( oProcess,, SC7->C7_NUM )

		elseif nOpc == 3 //Pedido rejeitado

			If Select("SC7") > 0
				SC7->(dbCloseArea())
			EndIf

			dbselectarea("SC7")
			SC7->(dbSetOrder(1))
			SC7->(dbgotop())
			SC7->(dbseek(cxFilial+cNum))

			While !SC7->(Eof())

				if SC7->C7_FILIAL+SC7->C7_NUM  == cxFilial+cNum

					U_UCLogMsg("( WF APROVAÇÃO - SPCRetorno ) Data: "+dtoc(ddatabase)+ "Hora: "+time()+"Filial:" +SC7->C7_FILIAL+" Pedido:"+SC7->C7_NUM+" Valor do SC7->C7_CONAPRO: "+SC7->C7_CONAPRO )
					U_UCLogMsg("( WF APROVAÇÃO - SPCRetorno ) Data: "+dtoc(ddatabase)+ "Hora: "+time()+" Valor do SC7->C7_OBS: "+alltrim(SC7->C7_OBS)+" Valor do SC7->C7_CONAPRO: "+alltrim(SC7->C7_CONAPRO))

					if Reclock("SC7",.F.)
						SC7->C7_CONAPRO := "R"
						SC7->C7_OBS := AllTrim(SC7->C7_OBS)+"/"+cJusti
						SC7->(MsUnlock())
					endif

				endif

				SC7->(dbSkip())

			EndDo

		endif

	EndIf

	//cTipo	:= 'PC'
	cDocto 	:= cNum+Space(Len(SCR->CR_NUM)-Len(cNum))
	dbSelectArea("SCR")
	SCR->( dbSetOrder(2) )
	if !SCR->(dbSeek(cxFilial+cTipo+cDocto) )
		U_UCLogMsg("INICIO DE RETORNO WF APROVAÇÃO (WF APROVAÇÃO - SPCRetorno ) Data: "+dtoc(ddatabase)+ "Hora: "+time()+" Não achou SCR (1): "+ xFilial("SCR")+'PC'+cDocto )
	endif

	If nOpc == 2 .and. lSaldoOk
		cMSGAprov := 'APROVADO'
	ElseIf nOpc == 3
		cMSGAprov := 'REPROVADO'
	ElseIf nOpc == 2 .and. !lSaldoOk
		cMSGAprov := 'O APROVADOR NÃO POSSUI SALDO SUFICIENTE'
	Endif

	cAviso:="NOTIFICAÇÃO - Pedido de Compra "+cMSGAprov+" - Pedido No "+cNum

	//Mensagem
	xHTM := '<HTML><BODY>'
	xHTM += '<hr>'
	xHTM += '<p  style="word-spacing: 0; line-height: 100%; margin-top: 0; margin-bottom: 0">'
	xHTM += '<b><font face="Verdana" SIZE=3>'+cAviso+' &nbsp; '+dtoc(date())+'&nbsp;&nbsp;&nbsp;'+time()+'</b></p>'
	xHTM += '<hr>'
	xHTM += '<br>'
	xHTM += '<br>'
	xHTM += 'O pedido em referencia foi '+cMSGAprov+' <BR><BR>'+iif(nOpc<>2,'Motivo: '+cJusti+'<BR><BR>','')+'-Data <b>'  +DTOC(date())+'</b> hora: <b>'+time()+'</b> <BR>-Responsável <b>'+UsrRetName(cCodLiber)+'</b> <br><br>'
	xHTM += '</BODY></HTML>'

	dbSelectArea("SCR")
	SCR->(dbSetOrder(2))
	SCR->(dbgotop())
	SCR->(dbSeek(cxFilial+cTipo+cNum))

	while SCR->(!Eof()) .and. cxFilial == SCR->CR_FILIAL .and. SCR->CR_NUM == cNum

		U_UCLogMsg("( WF APROVAÇÃO - SPCRetorno ) Data: "+dtoc(ddatabase)+ "Hora: "+time()+" while cxFilial=SCR->CR_FILIAL .and. SCR->CR_NUM = cNum" )
		U_UCLogMsg("( WF APROVAÇÃO - SPCRetorno ) Data: "+dtoc(ddatabase)+ "Hora: "+time()+" Valores de cCodLiber: "+alltrim(cCodLiber)+" cNivelApr: "+alltrim(cNivelApr))

		if SCR->CR_USER<>cCodLiber .and. cNivelApr == SCR->CR_NIVEL //Avisa o mesmo nível

			cDestino := UsrRetMail(SCR->CR_USER)

			//Envia email de Aviso
			ExxNVIAREMAIL('','Aviso - '+cAviso+'','Aviso - '+cAviso+'',xHTM,lJob,cDestino)
			U_UCLogMsg("( WF APROVAÇÃO - SPCRetorno ) Data: "+dtoc(ddatabase)+ "Hora: "+time()+" Enviado E-MAIL PARA  "+alltrim(cDestino))
		
		endif

		SCR->(dbskip())

	enddo

	//Avisa o comprador
	if lLiberou .or. nOpc == 3
		//Envia email de Aviso
		ExxNVIAREMAIL('','Aviso - '+cAviso+'','Aviso - '+cAviso+'',xHTM,lJob,UsrRetMail(cPCUser))
		U_UCLogMsg("( WF APROVAÇÃO - SPCRetorno ) Data: "+dtoc(ddatabase)+ "Hora: "+time()+" Avisou o Comprador"+cPCUser)
	endif

Return

//========================================
STATIC Function SPCIniciar( oProcess, cTipLiber, cNumC7, nPosEmail  )
//========================================

	Local nTotal 		:= 0
	Local _nXF 			:= 0
	Local cAssunto		:= ""
	Local nFrete		:= 0
	Local nVlrIpi		:= 0
	Local nVlrDesc		:= 0
	Local cHTML 		:= AllTrim( "/workflow/")
	Local cHttpServer 	:= "http://" + AllTrim( WFGetMV( "MV_WFWS", "127.0.0.1" ) ) + "/messenger/"
	Local i				:= 0
	Local aEnvios		:= {}

	default cTipLiber 	:= ""
	default cNumC7		:= ""
	default nPosEmail	:= 0

	// verifico se o numero do pedido esta informado
	if !empty(cNumC7)

		dbSelectArea("SC7")

		U_UCLogMsg(" ( WF APROVAÇÃO - SPCIniciar ) Data: "+dtoc(ddatabase)+ "Hora: "+time()+" Pedido informado " + cNumC7 )

		SC7->(dbgotop())
		SC7->(dbSetOrder(1))
		SC7->(dbseek(cxFilial+cNumC7))

	endIf

	//Abre o HTML criado. Repare que o mesmo se encontra abaixo do RootPath
	cAssunto := "Solicitação de Aprovacao de Pedido de Compra - Pedido No "+SC7->C7_NUM
	oProcess:NewTask( "Solicitação", cHTML+"wfw120pv.htm" )
	
	oProcess:cSubject := cAssunto
	oProcess:bReturn := "U_WFW120P( 1 )"

	//  Timeout                                  dia          /        Hora       /  Minuto
	oProcess:bTimeOut := {{"U_WFW120P(2)", SuperGetMv("MV_WFDIAS",.F.,3) , SuperGetMv("MV_WFHORAS",.T.,12)  , 1 }}
	oHTML := oProcess:oHTML

	/*** Preenche os dados do cabecalho ***/
	oHtml:ValByName( "EMISSAO", DToC(SC7->C7_EMISSAO) )
	oHtml:ValByName( "FORNECEDOR", SC7->C7_FORNECE )

	dbSelectArea('SA2')
	SA2->( dbSetOrder(1) )
	SA2->( dbSeek(xFilial('SA2')+SC7->C7_FORNECE+SC7->C7_LOJA) )
	oHtml:ValByName( "lb_nome", Posicione('SA2',1,xFilial('SA2')+SC7->C7_FORNECE+SC7->C7_LOJA,'A2_NOME') )
	oHtml:ValByName( "lb_cond", Posicione('SE4',1,xFilial('SE4')+SC7->C7_COND,'E4_DESCRI') )
	oHtml:ValByName( "lb_comprador", UsrRetName(SC7->C7_USER) )

	dbSelectArea('SC7')
	cxFilial := SC7->C7_FILIAL
	cNum := SC7->C7_NUM

	oHtml:ValByName( "EMPRESA_FILIAL", SM0->M0_NOMECOM )
	oHtml:ValByName( "FILIAL", SC7->C7_FILIAL )
	oHtml:ValByName( "PEDIDO", SC7->C7_NUM )
	oProcess:fDesc := "Pedido de Compras No "+ cNum

	SC7->( dbSetOrder(1) )
	SC7->( dbSeek(cxFilial+cNum) )

	//
	// Inicia-se o processo de identificação da cotação
	//
	U_UCLogMsg(" ( WF APROVAÇÃO - SPCIniciar ) Data: "+dtoc(ddatabase)+ "Hora: "+time()+"Inicia-se o processo de identificação da cotação")
	DbSelectArea("SC8")
	SC8->( DbSetOrder(3) )
	if 	SC8->( DbSeek( cxFilial+SC7->C7_NUMCOT ) )
		oHtml:ValByName( "nCotacao"," - Nr.:"+SC7->C7_NUMCOT+" EM "+dtoc(SC8->C8_EMISSAO) )
		U_UCLogMsg(" ( WF APROVAÇÃO - SPCIniciar ) Data: "+dtoc(ddatabase)+ "Hora: "+time()+" -  Nr.:"+SC7->C7_NUMCOT+" EM "+dtoc(SC8->C8_EMISSAO))
	else
		U_UCLogMsg(" ( WF APROVAÇÃO - SPCIniciar ) Data: "+dtoc(ddatabase)+ "Hora: "+time()+" - Nao encontrou cotacao ou Pedido de compras sem cotacao ")
	endif

	do while !SC8->( Eof() ) .and. (SC7->C7_FILIAL+SC7->C7_NUMCOT) = (SC8->C8_FILIAL+SC8->C8_NUM)

		if SC8->C8_FORNECE == SC7->C7_FORNECE .and. SC8->C8_LOJA == SC7->C7_LOJA

			AAdd( (oHtml:ValByName( "cotacao.item" )),SC8->C8_ITEM )
			AAdd( (oHtml:ValByName( "cotacao.codigo" )),SC8->C8_PRODUTO )
			AAdd( (oHtml:ValByName( "cotacao.descricao" )),Posicione('SB1',1,xFilial('SB1')+SC8->C8_PRODUTO,'B1_DESC') )
			AAdd( (oHtml:ValByName( "cotacao.fornecedor" )),Posicione('SA2',1,xFilial('SA2')+C8_FORNECE,'A2_NREDUZ') )
			AAdd( (oHtml:ValByName( "cotacao.qtde" )),TRANSFORM( SC8->C8_QUANT,'@E 99,999.99' ) )
			AAdd( (oHtml:ValByName( "cotacao.vunit" )),TRANSFORM( SC8->C8_PRECO,'@E 99,999.99' ) )
			AAdd( (oHtml:ValByName( "cotacao.total" )),TRANSFORM( SC8->C8_TOTAL,'@E 99,999.99' ) )
			AAdd( (oHtml:ValByName( "cotacao.entrega" )),dtoc(SC8->C8_DATPRF) )
			AAdd( (oHtml:ValByName( "cotacao.condPag" )),Posicione('SE4',1,xFilial('SE4')+SC8->C8_COND,'E4_DESCRI') )

			++_nXF

		else

			AAdd( (oHtml:ValByName( "cotacao.item" )),SC8->C8_ITEM )
			AAdd( (oHtml:ValByName( "cotacao.codigo" )),SC8->C8_PRODUTO )
			AAdd( (oHtml:ValByName( "cotacao.descricao" )),Posicione('SB1',1,xFilial('SB1')+SC8->C8_PRODUTO,'B1_DESC') )
			AAdd( (oHtml:ValByName( "cotacao.fornecedor" )),Posicione('SA2',1,xFilial('SA2')+C8_FORNECE,'A2_NREDUZ') )
			AAdd( (oHtml:ValByName( "cotacao.qtde" )),TRANSFORM( SC8->C8_QUANT,'@E 99,999.99' ) )
			AAdd( (oHtml:ValByName( "cotacao.vunit" )),TRANSFORM( SC8->C8_PRECO,'@E 99,999.99' ) )
			AAdd( (oHtml:ValByName( "cotacao.total" )),TRANSFORM( SC8->C8_TOTAL,'@E 99,999.99' ) )
			AAdd( (oHtml:ValByName( "cotacao.entrega" )),dtoc(SC8->C8_DATPRF) )
			AAdd( (oHtml:ValByName( "cotacao.condPag" )),Posicione('SE4',1,xFilial('SE4')+SC8->C8_COND,'E4_DESCRI') )

			++_nXF

		endif

		SC8->( DbSkip() )

	enddo

	if _nXF = 0

		oHtml:ValByName( "nCotacao"," - NAO HOUVE COTACAO PARA ESTE PEDIDO DE COMPRA" )
		AAdd( (oHtml:ValByName( "cotacao.item" )), SPACE( LEN(SC8->C8_ITEM) ) )
		AAdd( (oHtml:ValByName( "cotacao.codigo" )), SPACE( LEN(SC8->C8_PRODUTO) ) )
		AAdd( (oHtml:ValByName( "cotacao.descricao" )),SPACE( LEN(SC8->C8_PRODUTO) ) )
		AAdd( (oHtml:ValByName( "cotacao.fornecedor" )), SPACE( LEN(SA2->A2_NREDUZ) ) )
		AAdd( (oHtml:ValByName( "cotacao.qtde" )),TRANSFORM( SC8->C8_QUANT,'@E 99,999.99' ) )
		AAdd( (oHtml:ValByName( "cotacao.vunit" )),TRANSFORM( SC8->C8_PRECO,'@E 99,999.99' ) )
		AAdd( (oHtml:ValByName( "cotacao.total" )),SPACE(9) )
		AAdd( (oHtml:ValByName( "cotacao.entrega" )), space(10) )
		AAdd( (oHtml:ValByName( "cotacao.condPag" )), space( len(SE4->E4_DESCRI) ) )

	endif

	aUltPrc	:= {0,0,0}
	
	dbSelectArea('SC7')
	While !SC7->( Eof() ) .and. SC7->C7_FILIAL+SC7->C7_NUM = cxFilial+cNum

		aUltPrc	:= U_UltPrc(SC7->C7_PRODUTO)

		nTotal		+= SC7->C7_TOTAL
		nFrete		+= SC7->C7_VALFRE
		nVlrIpi 	+= SC7->C7_VALIPI
		nVlrDesc	+= SC7->C7_VLDESC


		AAdd( (oHtml:ValByName( "produto.item" )),SC7->C7_ITEM )
		AAdd( (oHtml:ValByName( "produto.codigo" )),SC7->C7_PRODUTO )

		dbSelectArea('SB1')
		SB1->( dbSetOrder(1) )
		SB1->( dbSeek(xFilial('SB1')+SC7->C7_PRODUTO) )

		dbSelectArea('CTT')
		CTT->( dbSetOrder(1) )
		CTT->( dbSeek(xFilial('CTT')+SC7->C7_CC) )

		dbSelectArea('SC1')
		SC1->(dbSetOrder(1))
		SC1->(dbSeek(xFilial("SC1") + SC7->(C7_NUMSC + C7_ITEMSC)))

		AAdd( (oHtml:ValByName( "produto.descricao" ))	,Posicione('SB1',1,xFilial('SB1')+SC7->C7_PRODUTO,'B1_DESC') )
		AAdd( (oHtml:ValByName( "produto.quant" ))		,TRANSFORM( SC7->C7_QUANT,'@E 99,999.99' ) )
		AAdd( (oHtml:ValByName( "produto.preco" ))		,TRANSFORM( SC7->C7_PRECO,'@E 9,999,999.99' ) )
		AAdd( (oHtml:ValByName( "produto.desconto" ))	,TRANSFORM( SC7->C7_VLDESC,'@E 9,999,999.99' ) )
		AAdd( (oHtml:ValByName( "produto.total" ))		,TRANSFORM( SC7->C7_TOTAL - SC7->C7_VLDESC ,'@E 9,999,999.99' ) )
		AAdd( (oHtml:ValByName( "produto.unid" )) 		,SB1->B1_UM )
		aAdd( (oHtml:ValByName( "produto.cc" )) 		,SC7->C7_CC )
		aAdd( (oHtml:ValByName( "produto.dcc" )) 		,CTT->CTT_DESC01 )
		aAdd( (oHtml:ValByName( "produto.clvl" ))		,SC7->C7_CLVL )
		AAdd( (oHtml:ValByName( "produto.entrega" ))	,dtoc(SC7->C7_DATPRF) )

		if SC1->( FieldPos("C1_XCOMPLE") ) > 0
			AAdd( (oHtml:ValByName( "produto.motivo" )) 	,Alltrim(SC1->C1_XCOMPLE) )
		else
			AAdd( (oHtml:ValByName( "produto.motivo" )) 	,"" )
		endIf

		AAdd( (oHtml:ValByName( "produto.condPag" ))	,Posicione('SE4',1,xFilial('SE4')+SC7->C7_COND,'E4_DESCRI') )

		AAdd( (oHtml:ValByName( "produto.ultimo" )), aUltPrc[1] )
		AAdd( (oHtml:ValByName( "produto.penult" )), aUltPrc[2] )
		AAdd( (oHtml:ValByName( "produto.antepe" )), aUltPrc[3] )

		WFSalvaID('SC7','C7_WFID',oProcess:fProcessID)

		SC7->( dbSkip() )

	Enddo

	oHtml:ValByName( "lbValor" ,TRANSFORM( nTotal,'@E 9,999,999.99' ) )
	oHtml:ValByName( "lbdesconto" ,TRANSFORM( nVlrDesc,'@E 9,999,999.99' ) )
	oHtml:ValByName( "lbFrete" ,TRANSFORM( nFrete,'@E 99,999.99' ) )
	oHtml:ValByName( "lbTotal" ,TRANSFORM( nTotal + nVlrIpi  + nFrete - nVlrDesc,'@E 9,999,999.99' ) )

	oProcess:ClientName( UsrRetName(WFCodUser("BI")) )
	oProcess:UserSiga := WFCodUser("BI")

	SC7->(dbgotop())
	SC7->(dbSetOrder(1))
	SC7->(dbseek(cxFilial+cNum))

	if len(aMail) == 0
		SPCAprovador( SC7->C7_NUM, @aEnvios )
	else 

		aEnvios := {}

		// se a posiciao do email estiver zerada, considero todo o array para envio
		if nPosEmail == 0
			aEnvios := aMail
		else // se a pocicao tiver sido enviada, considero apenas o item do array passado como parametro
			aadd(aEnvios,aMail[nPosEmail])
		endif

	endIf

	oProcess:cTo :=  "pedcom"

	if Len(aEnvios) > 0

		oHtml:ValByName("lb_aprovador", aEnvios[1,6] )

		cMailID := oProcess:Start()
		RastreiaWF(oProcess:fProcessID+'.'+oProcess:fTaskID,oProcess:fProcCode,'10001','Processo do Pedido '+cNum+' iniciado!' )

		for i := 1 to len(aEnvios)

			cAviso:="Solicitação de Aprovacao de Pedido de Compra - Pedido No " + oProcess:oHtml:RetByName('Pedido') + ' da empresa ' + SM0->M0_FILIAL
			cDestino:= aEnvios[i,2]
			cLink:=cHttpServer+"emp" + SM0->M0_CODIGO + "/pedcom/" + cMailID + ".htm"

			//Envia email de Aviso
			xHTM := '<HTML><BODY>'
			xHTM += '<hr>'
			xHTM += '<p  style="word-spacing: 0; line-height: 100%; margin-top: 0; margin-bottom: 0">'
			xHTM += '<b><font face="Verdana" SIZE=3>'+cAviso+' &nbsp; em '+dtoc(date())+'&nbsp;&nbsp;&nbsp;'+time()+'</b></p>'
			xHTM += '<hr>'
			xHTM += '<br>'
			xHTM += '<b><font face="Verdana" SIZE=3> Prezado(a) '+aEnvios[i,1]+'</b></p>'
			xHTM += '<br>'
			xHTM += 'Favor clicar no link abaixo para aprovação/rejeição do pedido em referencia<BR> <br>'
			xHTM += "<a href="+cLink+"?user="+aEnvios[i,3]+" title="+cLink+">Ver Pedido</a> "
			xHTM += '</BODY></HTML>'

			ExxNVIAREMAIL('','Aviso - '+cAviso+'','Aviso - '+cAviso+'',xHTM,lJob,cDestino)

			RastreiaWF(oProcess:fProcessID+'.'+oProcess:fTaskID,oProcess:fProcCode,'10001','Email enviado para  '+aEnvios[i,2]+'!' )

			SCR->( dbGoTo( aEnvios[i,4] ) )

			if SCR->( recLock("SCR",.F.) )
				SCR->CR_WF := "1"
				SCR->( msUnlock() )
			endIf

		next i

	else

		RastreiaWF(oProcess:fProcessID+'.'+oProcess:fTaskID,oProcess:fProcCode,iif(nOpc==2,'10003','10004'),,"BI")
		oProcess:Finish()

	endif

Return

//=======================================
STATIC Function SPCTimeOut( oProcess )
//=======================================

	cAviso:="NOTIFICAÇÃO - Aprovação de Pedido de Compra PENDENTE - Pedido No "+oProcess:oHtml:RetByName('Pedido')
	cDestino:=UsrRetMail(WFCodUser("BI"))

	//Envia email de Aviso
	xHTM := '<HTML><BODY>'
	xHTM += '<hr>'
	xHTM += '<p  style="word-spacing: 0; line-height: 100%; margin-top: 0; margin-bottom: 0">'
	xHTM += '<b><font face="Verdana" SIZE=3>'+cAviso+' &nbsp; '+dtoc(date())+'&nbsp;&nbsp;&nbsp;'+time()+'</b></p>'
	xHTM += '<hr>'
	xHTM += '<br>'
	xHTM += '<br>'
	xHTM += 'O pedido em referencia ainda não foi respondido <BR> <br>'
	xHTM += '</BODY></HTML>'

	ExxNVIAREMAIL('','Aviso - '+cAviso+'','Aviso - '+cAviso+'',xHTM,lJob,cDestino)

Return

/*######################################################################
ULTIMOS PREÇOS
######################################################################*/
User Function UltPrc(cCod)

	Local aArea		:= GetArea()
	Local aRet		:= {0,0,0}
	Local cAlias	:= GetNextAlias()

	BeginSql Alias cAlias
		//SELECT DISTINCT D1_FILIAL, D1_COD, D1_DOC, D1_SERIE, D1_DTDIGIT, D1_VUNIT, D1_QUANT, D1_UM
		SELECT DISTINCT D1_FILIAL, D1_COD, D1_DOC, D1_SERIE, D1_DTDIGIT, D1_VUNIT, D1_QUANT, D1_UM
		FROM %TABLE:SD1% SD1
		WHERE  SD1.D_E_L_E_T_ = ' '
		AND SD1.D1_COD = %Exp:cCod%
		AND SD1.D1_TIPO = 'N'
		ORDER BY D1_DTDIGIT DESC
	EndSql

	_aQuery := GetLastQuery()
	
	If (cAlias)->(!EOF())
		_N := 1
		While (cAlias)->(!EOF()) .AND. _N < 4
			//aRet[_N] := "R$ "+alltrim(str((cAlias)->D1_VUNIT))+" - "+alltrim(str((cAlias)->D1_QUANT))+alltrim((cAlias)->D1_UM)
			aRet[_N] := "R$ "+alltrim(str((cAlias)->D1_VUNIT))+" | "+alltrim(str((cAlias)->D1_QUANT))+alltrim((cAlias)->D1_UM)+" | "+SUBSTR((cAlias)->D1_DTDIGIT,7,2)+"/"+SUBSTR((cAlias)->D1_DTDIGIT,5,2)+"/"+SUBSTR((cAlias)->D1_DTDIGIT,1,4)
			_N++
			(cAlias)->(dbSkip())
		EndDo
	EndIf

	RestArea(aArea)

Return aRet

/*
_____________________________________________________________________________
¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦
¦¦+-----------------------------------------------------------------------+¦¦
¦¦¦Programa  ¦ ExxNVIAREMAIL ¦ Autor ¦                    ¦ Data ¦ 29/08/02 ¦¦¦
¦¦+----------+------------------------------------------------------------¦¦¦
¦¦¦Descriçào ¦ Funcao para enviar email                                   ¦¦¦
¦¦+----------+------------------------------------------------------------¦¦¦
¦¦¦ Uso      ¦ Geral                                                      ¦¦¦
¦¦+-----------------------------------------------------------------------+¦¦
¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦
¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
*/
//Funcao....: ExxNVIAREMAIL()
//Parametros: cArquivo: Dir\Nome         (C)
//            cTitulo : Titulo da Tela   (C)
//            cSubject: Titulo do E-Mail (C)
//            cBody   : Corpo do E-Mail  (C)
//            lShedule: Se for Shedulado (L)
//            cTo     : E-Mail destino   (C)
//            cCc     : E-Mail Copia     (C)
//Retorno...: .T./.F.
Static Function ExxNVIAREMAIL(cArquivo,cTitulo,cSubject,cBody,lShedule,cTo,cCC)
	
	LOCAL cServer		:= "" 
	Local cAccount		:= "" 
	Local cPassword		:= ""
	Local lAutentica	:= .F.
	Local cUserAut		:= ""
	Local cPassAut		:= ""
	Local _nSMTPPort 	:= superGetMV("MV_PORSMTP",,"587")//587 
	Local oMail			:= NIL 
	Local oMessage		:= NIL
	Local nErro			:= 0
	DEFAULT cArquivo 	:= ""
	DEFAULT cTitulo  	:= ""
	DEFAULT cSubject 	:= ""
	DEFAULT cBody    	:= ""
	DEFAULT lShedule 	:= .F.
	DEFAULT cTo      	:= ""
	DEFAULT cCc      	:= ""

	IF EMPTY((cServer:=AllTrim(SuperGetmv("MV_RELSERV"))))

		IF !lShedule .OR. bXMSAPRO
			MSGINFO("Nome do Servidor de Envio de E-mail nao definido no 'MV_RELSERV'")
		ELSE
			U_UCLogMsg("Nome do Servidor de Envio de E-mail nao definido no 'MV_RELSERV'")
		ENDIF

		RETURN .F.

	ENDIF

	IF EMPTY((cAccount:=AllTrim(AllTrim(SuperGetmv("MV_RELACNT")))))

		IF !lShedule .OR. bXMSAPRO
			MSGINFO("Conta para acesso ao Servidor de E-mail nao definida no 'MV_RELACNT'")
		ELSE
			U_UCLogMsg("Conta para acesso ao Servidor de E-mail nao definida no 'MV_RELACNT'")
		ENDIF

		RETURN .F.

	ENDIF

	IF lShedule .AND. EMPTY(cTo)

		IF !lShedule .OR. bXMSAPRO
			U_UCLogMsg("E-mail para envio, nao informado.")
		ENDIF

		RETURN .F.

	ENDIF

	IF !lShedule
		cFrom:= SuperGetmv("MV_RELACNT") //UsrRetMail(RetCodUsr()) --- Nao aceita conta diferente da conta de envio como remetente.
		cUser:= UsrRetName(RetCodUsr())
	else
		cFrom:= SuperGetmv("MV_RELACNT")  //AllTrim(SuperGetmv("MV_EMCONTA"))
		cUser:= AllTrim(SuperGetmv("MV_WFMLBOX"))   //"WorkFlow Flach"
	endif

	cCC  := cCC + SPACE(200)
	cTo  := cTo + SPACE(200)
	cSubject:=cSubject+SPACE(100)

	IF EMPTY(cFrom)

		IF !lShedule  .OR. bXMSAPRO
			MsgInfo("E-mail do remetente nao definido no cad. do usuario: "+cUser)
		ELSE
			U_UCLogMsg("E-mail do remetente nao definido no cad. do usuario: "+cUser)
		ENDIF

		RETURN .F.

	ENDIF

	cAttachment:=cArquivo
	cPassword  := AllTrim(SuperGetmv("MV_RELPSW"))
	lAutentica := SuperGetmv("MV_RELAUTH")          	//Determina se o Servidor de Email necessita de Autenticação
	cUserAut   := Alltrim(SuperGetmv("MV_RELAUSR"))		//Usuário para Autenticação no Servidor de Email
	cPassAut   := AllTrim(SuperGetmv("MV_RELPSW"))		//Senha para Autenticação no Servidor de Email

	oMail := TMailManager():New()

	if GetMv("MV_RELSSL",,.F.)
		// Usa SSL na conexao
		oMail:setUseSSL(.T.)
	Endif

	if GetMv("MV_RELTLS",,.F.)
		// Usa SSL na conexao
		oMail:setUseTLS(.T.)
	Endif

	if At(':',cServer)>0
		if _nSMTPPort == 0
			_nSMTPPort:=Val(Substr(cServer,At(':',cServer)+1))
		endif
		cServer:=Substr(cServer,1,At(':',cServer)-1)
	endif

	oMail:Init( '', cServer , cAccount, cPassword, 0, _nSMTPPort )
	oMail:SetSmtpTimeOut( 120 )
	U_UCLogMsg( 'Conectando do SMTP' )
	nErro := oMail:SmtpConnect()

	If nErro <> 0

		IF !lShedule .AND. bXMSAPRO
			MsgInfo("ERROR:" + oMail:GetErrorString( nErro ))
		Else
			U_UCLogMsg( "ERROR:" + oMail:GetErrorString( nErro ) )
		EndIf

		oMail:SMTPDisconnect()

		return .F.

	Endif

	If lAutentica

		nErro := oMail:SmtpAuth( cUserAut ,cPassAut )

		If nErro <> 0

			IF !lShedule .AND. bXMSAPRO
				MsgInfo("ERROR:" + oMail:GetErrorString( nErro ))
			Else
				U_UCLogMsg( "ERROR:" + oMail:GetErrorString( nErro ) )
			EndIf

			oMail:SMTPDisconnect()
			return .F.

		Endif

	EndIf

	oMessage := TMailMessage():New()
	oMessage:Clear()
	oMessage:cFrom                  := cFrom
	oMessage:cTo                    := cTo
	oMessage:cCc                    := cCC
	oMessage:cSubject               := cSubject
	oMessage:cBody                  := cBody

	nErro := oMessage:Send( oMail )

	if nErro <> 0

		IF !lShedule .AND. bXMSAPRO
			MsgInfo("ERROR:" + oMail:GetErrorString( nErro ))
		Else
			U_UCLogMsg( "ERROR:" + oMail:GetErrorString( nErro ) )
		EndIf

		return .F.

	Else

		IF !lShedule .AND. bXMSAPRO
			MsgInfo("E-mail de Aprovação enviado com sucesso para: "+ALLTRIM(cTo))
		ELSE
			U_UCLogMsg("E-mail de Aprovação enviado com sucesso para: "+ALLTRIM(cTo))
		ENDIF

	Endif

	U_UCLogMsg( 'Desconectando do SMTP' )
	oMail:SMTPDisconnect()

RETURN .T.

//======================================================
Static Function SPCAprovador( cDocument, aMail )
//======================================================

	local nContCR		:= ""
	local cNivel 		:= ""
	local cAprovador	:= ""
	local cTipoPed		:= ""
	local lAlcPedCTB  	:= superGetMv("MV_APRPCEC",.F.,.F.) 
	local lMVUsaTst		:= superGetMV("ES_WFCTST",.f.,.f.)
	local cMVMailTst	:= superGetMv("ES_WFCMAIL",.f.,"")

	default cDocument 	:= ""
	default aMail		:= {}

	dbSelectArea("SCR")
	SCR->(dbgotop())
	SCR->(dbSetOrder(1))

	if lAlcPedCTB
		cTipoPed := "IP"
	else
		cTipoPed := "PC"
	endIf

	if SCR->(dbSeek(xFilial("SCR")+cTipoPed+cDocument))

		nContCR := 0
		while SCR->(!Eof()) .and. xFilial("SCR") == alltrim(SCR->CR_FILIAL) .and. SCR->CR_TIPO == cTipoPed .and. Alltrim(SCR->CR_NUM) == alltrim(cDocument)

			If empty(allTrim(SCR->CR_WF)) .and. SCR->CR_NIVEL # cNivel .and. nContCR > 0
				SCR->(dbskip())
				loop
			elseIf empty(allTrim(SCR->CR_WF)) .and. SCR->CR_NIVEL # cNivel .and. nContCR == 0
				nContCR++
				cNivel := SCR->CR_NIVEL
			elseIf empty(allTrim(SCR->CR_WF)) .and. SCR->CR_NIVEL # cNivel .and. empty(alltrim(cNivel))
				nContCR++
				cNivel := SCR->CR_NIVEL
			endIf

			// vou enviar apenas de um nivel
			if cNivel == SCR->CR_NIVEL

				SAL->( dbSetOrder(4) )
				SAL->( dbSeek(xFilial("SAL")+SCR->CR_GRUPO+SCR->CR_USER) )

				if !empty(UsrRetMail(SCR->CR_USER))
					If Empty(cAprovador)
						cAprovador := SCR->CR_USER
					Else
						cAprovador := cAprovador+SCR->CR_USER
					EndIf

					if lMVUsaTst .and. !empty(cMVMailTst)
						aadd(aMail,{UsrRetName(SCR->CR_USER),cMVMailTst,SCR->CR_USER,SCR->(Recno()),SAL->AL_TPLIBER,cAprovador})
					else
						aadd(aMail,{UsrRetName(SCR->CR_USER),UsrRetMail(SCR->CR_USER),SCR->CR_USER,SCR->(Recno()),SAL->AL_TPLIBER,cAprovador})
					endIf

				else
					Aviso("Aviso","Email não cadastrado para o usuário >> "+UsrRetName(SCR->CR_USER),{"Ok"},1)
				endif

			endIf

			//nContCR++
			SCR->(dbskip())

		enddo

	else
		U_UCLogMsg(" ( WF APROVAÇÃO - SPCAprovador ) Data: "+dtoc(ddatabase)+ "Hora: "+time()+" - Este pedido não existe SCR (Aprovadores)")
	endif

	U_UCLogMsg(" ( WF APROVAÇÃO - SPCAprovador ) Data: "+dtoc(ddatabase)+ "Hora: "+time()+" -> Dados do aMail : " + cValToChar(len(aMail)) )

return
