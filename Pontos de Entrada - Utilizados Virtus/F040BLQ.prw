#Include 'Protheus.ch'
#INCLUDE "topconn.ch"
#INCLUDE "TbiConn.ch"

/*
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
�������������������������������������������������������������������������ͻ��
���Programa  � F040BLQ � Autor � Wellington Gon�alves � Data � 23/08/2016 ���
�������������������������������������������������������������������������͹��
���Desc.     � Ponto de entrada para validar a exclus�o do t�tulo		  ���
��		     � a receber												  ���
�������������������������������������������������������������������������͹��
���Uso       � Cemit�rio e Funer�ria                                      ���
�������������������������������������������������������������������������ͼ��
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
*/

User Function F040BLQ()

Local aArea			:= GetArea()
Local aAreaSE1		:= SE1->(GetArea())
Local aAreaU60		:= U60->(GetArea())
Local lRet 			:= .T.
Local lFuneraria	:= SuperGetMV("MV_XFUNE",,.F.)
Local lCemiterio	:= SuperGetMV("MV_XCEMI",,.F.)
Local cCodModulo	:= IIF(lFuneraria, "F", "C")
Local cTipo			:= ""

if !IsBlind() // n�o ser� validado em rotinas automaticas

	if !ALTERA .AND. !INCLUI // se a opera��o for exclus�o
	
		if lFuneraria // verifico se este t�tulo � de um contrato da funer�ria
		
			// t�tulo de cancelamento de contrato pode excluir manualmente
			cTipo := SuperGetMv("MV_XCANFUN",.F.,"CAN")
		
			if AllTrim(SE1->E1_TIPO) <> AllTrim(cTipo) .AND. !Empty(SE1->E1_XCTRFUN)
				lRet := .F.
				MsgAlert("N�o � poss�vel realizar esta opera��o para este t�tulo a receber, pois est� vinculado ao contrato da Funer�ria " + AllTrim(SE1->E1_XCTRFUN) + ".")
			endif
		
		endif
		
		if lRet .AND. lCemiterio // verifico se este t�tulo � de um contrato do cemit�rio
		
			if !Empty(SE1->E1_XCONTRA)
				lRet := .F.
				MsgAlert("N�o � poss�vel realizar esta opera��o para este t�tulo a receber, pois est� vinculado ao contrato do Cemit�rio " + AllTrim(SE1->E1_XCONTRA) + ".")
			endif
		
		endif 
	
	endif

	If ALTERA

		// Metodo de pagamento da vindi
		U60->(DbSetOrder(2)) // U60_FILIAL + U60_FORPG
		If U60->(DbSeek(xFilial("U60") + SE1->E1_XFORPG))
			// Metodo Ativo
			If U60->U60_STATUS == "A"
				//-- Verifica se existe pendencias de processamentos VINDI --//
				lRet := U_PENDVIND(SE1->E1_NUM, cCodModulo)
			EndIf
		EndIf

	EndIf

endif

RestArea(aAreaU60)
RestArea(aAreaSE1)
RestArea(aArea)

Return(lRet)
