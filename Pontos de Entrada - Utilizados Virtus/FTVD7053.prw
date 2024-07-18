#INCLUDE "TOTVS.CH"

/*/{Protheus.doc} FTVD7053
    Ponto de Entrada executado na seleção da opção no Venda direta, 
    Onde permite acrescentar mais opções de botões no menu da tela.
    @type function
    @author Lorran Ferreira
    @since 28/05/2024
    @return array, Retorna o array com as novas rotinas do menu. 
/*/
User Function FTVD7053()

    Local aArray  as array

    aArray := {}

    /*
    Parâmetros do array aRotina: 
    1. Nome a aparecer no cabeçalho 
    2. Nome da Rotina associada 
    3. Reservado 
    4. Tipo de Transação a ser efetuada: 
        4.1 - Pesquisa e Posiciona em um Banco de Dados 
        4.2 - Simplesmente Mostra os Campos 
        4.3 - Inclui registros no Bancos de Dados 
        4.4 - Altera o registro corrente 
        4.5 - Remove o registro corrente do Banco de Dados 
    5. Nível de acesso 
    6. Habilita Menu Funcional 
    */
	aAdd( aArray, { "Reimpressão do Recibo de Venda", "U_RUTILR18(.T.)" , 0, 1, , .F. } )    

Return aArray
