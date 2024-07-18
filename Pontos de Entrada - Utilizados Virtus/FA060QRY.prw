#include "totvs.ch"

/*/{Protheus.doc} FA060QRY
Inclui condição SQL
O ponto de entrada FA060QRY permite a inclusão de uma condição adicional na consulta SQL (Query) de seleção dos títulos a receber, para posterior marcação em tela.
A condição adicionada deve seguir a sintaxe SQL e irá interferir na seleção dos títulos a receber que serão exibidos em tela.
Para maiores informações, consulte: FA060Qry Inclui condição SQL
@type function
@version 1.0
@author g.sampaio
@since 11/10/2023
@return character, retorna query
/*/
User Function FA060QRY()

	Local cMod          := ""
	Local cRetQuery     := ""
	Local lCemiterio    := SuperGetMV("MV_XCEMI", .F., .F.)
	Local lFuneraria    := SuperGetMV("MV_XFUNE", .F., .F.)
	Local lFilBordSus	:= SuperGetMV("MV_XFBCSUS", .F., .F.) // Filtra contratos suspensos no bordero

	If lFilBordSus .And. (lCemiterio .Or. lFuneraria)

		// modulo do contrato
		cMod := U_RetModul()

		If cMod == "CEM"
			cRetQuery := " NOT EXISTS "
			cRetQuery += " ( "
			cRetQuery += "  SELECT U00.U00_CODIGO AS CONTRATO FROM " + RetSQLName("U00") + " U00 "
			cRetQuery += "  WHERE U00.D_E_L_E_T_ = ' ' "
			cRetQuery += "  AND U00.U00_FILIAL = '" + xFilial("U00") + "' "
			cRetQuery += "  AND U00.U00_CODIGO = SE1.E1_XCONTRA "
			cRetQuery += "  AND U00.U00_STATUS IN ('C','S','F') "
			cRetQuery += " ) "
		ElseIf cMod == "FUN"
			cRetQuery := " NOT EXISTS "
			cRetQuery += " ( "
			cRetQuery += "  SELECT UF2.UF2_CODIGO AS CONTRATO FROM " + RetSQLName("UF2") + " UF2 "
			cRetQuery += "  WHERE UF2.D_E_L_E_T_ = ' ' "
			cRetQuery += "  AND UF2.UF2_FILIAL = '" + xFilial("UF2") + "' "
			cRetQuery += "  AND UF2.UF2_CODIGO = SE1.E1_XCTRFUN "
			cRetQuery += "  AND UF2.UF2_STATUS IN ('C','S','F') "
			cRetQuery += " ) "
		EndIf

	Else
		cRetQuery := " E1_NUM <> '' "
	EndIf

Return(cRetQuery)
