#include 'protheus.ch'
#include 'parmtype.ch'

/*/{Protheus.doc} FA040FIN
Ponto de entrada localizado após a inclusão do
título a receber	
@type function
@version 1.0
@author Wellington Gonçalves
@since 12/02/2019
/*/
User Function FA040FIN()

	// chamo a funcao para registro do titulo na recorrencia
	If ExistBlock("UVIND21")
		U_UVIND21(SE1->(Recno()))
	EndIf

Return(Nil)
