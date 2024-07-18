#include "rwmake.ch"
#include "topconn.ch

/*/{Protheus.doc} MATA030
Ponto de Entrada em MVC do cadastro de Cliente
@author Totvs S.A.
@since 16/10/2019
@version 1.0
@OBS Para utilizar os pontos de entrada da rotina MATA030 no padrão MVC, altere para .T. o parâmetro MV_MVCSA1.

O ID do modelo da dados da rotina MATA030 é CRMA980, assim sendo, a assinatura da função de usuário deve ser User Function CRMA980().

/*/
User Function CRMA980()
	Local aParam 		:= PARAMIXB
	Local xRet 			:= .T.
	Local oObj 			:= ""
	Local cIdPonto 		:= ""
	Local cIdModel 		:= ""
	Local nOperation 	:= 0

	If aParam <> NIL
		oObj 		:= aParam[1]
		cIdPonto 	:= aParam[2]
		cIdModel 	:= aParam[3]
		nOperation := oObj:GetOperation()

		//Após a gravação total do modelo e dentro da transação.
		If cIdPonto =="MODELCOMMITTTS"

			xRet	:=	Nil

			//Inclusão da Item Contábil
			sfSetCTD(oObj)

			//alteracao do registro
			If nOperation == 3

				// se esta na rotina de agendamento
				If FWIsInCallStack("U_RUTIL49B")

					If U92->U92_TIPO $ "3|8" // cessionario ou responsavel financeiro

						BEGIN TRANSACTION

							If U92->(Reclock("U92", .F.))
								U92->U92_CLINOV := SA1->A1_COD
								U92->U92_LOJNOV := SA1->A1_LOJA
								U92->U92_NMCLIN	:= SA1->A1_NOME
								U92->(MsUnlock())
							Else
								lContinua := .F.
								U92->(DisarmTransaction())
								BREAK
							EndIf

						END TRANSACTION

					EndIf

				EndIf

			Elseif nOperation == 4

				If lCemiterio

					//altero os dados do contrato do cliente
					If ExistBlock("RCPGE007")
						U_RCPGE007(SA1->A1_COD,SA1->A1_LOJA)
					EndIf

				elseif lFuneraria

					//altero os dados do contrato do cliente
					If ExistBlock("RFUNE034")
						U_RFUNE034(SA1->A1_COD,SA1->A1_LOJA)
					EndIf

				Endif

				if lRecorrencia
					// função que verifica os contratos do cliente, para envio à vindi
					FWMsgRun(,{|oSay| U_UVIND10(SA1->A1_COD,SA1->A1_LOJA)},'Aguarde...','Verificando Contratos vinculados ao cliente...')
				endif

			endif

		ElseIf cIdPonto == "MODELPOS" // na validação na confirmação do cadastro

			if nOperation == 5

				//funcao para nao permitir excluir clientes com contratos vinculados
				if ExistBlock("RUTILE63")
					xRet := U_RUTILE63()
				endif

			endif

		elseif cIdPonto == 'MODELCOMMITNTTS' //Após a gravação dos dados

			// Inclusão de registro
			If nOperation == 3

				// Incluir/alterar os contatos do cliente(SU5)
				If ExistBlock("RUTILE61")
					If !IsBlind()
						FWMsgRun(,{|oSay| U_RUTILE61() },'Aguarde...','Registrando contatos do cliente...')
					Else
						U_RUTILE61()
					EndIf
				EndIf

			Elseif nOperation == 4

				// Incluir/alterar os contatos do cliente(SU5)
				If ExistBlock("RUTILE61")
					If !IsBlind()
						FWMsgRun(,{|oSay| U_RUTILE61() },'Aguarde...','Atualizando contatos do cliente...')
					Else
						U_RUTILE61()
					EndIf
				EndIf

			EndIf

		endif

	EndIf

EndIf
Return(xRet)

//==================================================================================================
Static Function sfSetCTD(mvModel)
	Local liRec		:=	.F.
	Local oModelSA1 := mvModel:GetModel( 'SA1MASTER' )
	Local aAreaSA1	:= SA1->(GetArea())
	Local aAreaCTD	:= CTD->(GetArea())

	If mvModel:GetOperation() == 3 .Or. mvModel:GetOperation() == 4

		DbSelectArea("CTD")
		CTD->(DbSetOrder(1))

		If !(CTD->(DbSeek(xFilial("CTD")+"C"+oModelSA1:GetValue('A1_COD')+oModelSA1:GetValue('A1_LOJA'))))

			liRec	:=	RecLock("CTD",.T.)
			CTD->CTD_FILIAL := xFilial("CTD")
			CTD->CTD_ITEM	:= "C"+oModelSA1:GetValue('A1_COD')+oModelSA1:GetValue('A1_LOJA')
			CTD->CTD_CLASSE := "2"
			CTD->CTD_NORMAL := "2"
			CTD->CTD_DESC01 := oModelSA1:GetValue('A1_NOME')
			CTD->CTD_BLOQ	:= "2"
			CTD->CTD_DTEXIS := CTOD("01/01/1980")
			CTD->CTD_ITLP 	:= "C"+oModelSA1:GetValue('A1_COD')+oModelSA1:GetValue('A1_LOJA')
			CTD->(MsUnLock())

			If liRec .And. SA1->(FieldPos('A1_XITEMCC')) > 0

				DbSelectArea("SA1")
				SA1->(DbSetOrder(1))
				If SA1->(DBSeek(xFilial("SA1")+oModelSA1:GetValue('A1_COD')+oModelSA1:GetValue('A1_LOJA')))

					RecLock("SA1",.F.)
					SA1->A1_XITEMCC := "C"+oModelSA1:GetValue('A1_COD')+oModelSA1:GetValue('A1_LOJA')
					SA1->(MsUnLock())

				EndIf
			EndIf


		EndIF
	EndIf

	RestArea(aAreaSA1)
	RestArea(aAreaCTD)

Return ()

