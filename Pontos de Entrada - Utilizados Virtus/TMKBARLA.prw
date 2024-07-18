#INCLUDE "TOTVS.CH"

/*/{Protheus.doc} TMKBARLA
    O ponto de entrada é chamado na criação da tela do Atendimento do Call Center,
    com o objetivo de incluir botões de usuário na toolbar lateral.
    @type function
    @author Lorran Ferreira
    @since 14/06/2024
    @param aBotao, array, Botões na toolbar lateral do Call Center
    @param aTitulo, array, Título dos folders
    @return array, Array com os botões da toolbar lateral do Call Center
    @obs 
    A quantidade de botões irá depender da resolução de tela e também das polegadas do monitor utilizado.
    Dependendo da resolução de tela, os últimos botões poderão sair cortados nas janelas dos atendimentos.
    aBotao[n,1]: Nome do Bitmap
    aBotao[n,2]: Nome da função que será executada
    aBotao[n,3]: Mensagem que será exibida quando o mouse passar sobre o botão
/*/
User Function TMKBARLA(aBotao, aTitulo)
    
    // Adiciona botões na toolbar lateral do Call Center da melhorias de atendimento.
    U_RUTIL064(@aBotao)

Return aBotao
