#INCLUDE "TOTVS.CH"

 /*/{Protheus.doc} TK271BOK
    Esse ponto de entrada é chamado no botão "OK" da barra de ferramentas da tela de atendimento do Call Center
    , antes da função de gravação.
    @type  Function
    @author Lorran Ferreira
    @since 19/06/2024
/*/
User Function TK271BOK()

    Local aArea := FwGetArea()
    Local lRet := .T.

    // Validação da Renegociação financeira Virtus.
    U_RUTIL062()

    FwRestArea(aArea)

Return(lRet)
