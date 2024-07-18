#INCLUDE "TOTVS.CH"

/*/{Protheus.doc} TMKCFIM
    Esse ponto de entrada é chamado após a gravação do atendimento na rotina do Telecobrança,
    com o objetivo de executar comandos diversos após essa gravação.
    @type  Function
    @author Lorran Ferreira
    @since 21/06/2024
    @see  https://tdn.totvs.com/pages/releaseview.action?pageId=6787779
/*/
User Function TMKCFIM()

    // Executa a liquidação da negociação financeira.
    U_RUTIL063()
    
Return 
