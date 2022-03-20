#!/bin/bash
export DEBIAN_FRONTEND="noninteractive"
.var

#	Adicionar o repositório universal:	
add-apt-repository universe &>> $LOG
echo -e "[ \033[0;32m OK \033[0m ] Repositório universal ..."

#	Adicionar o repositório multiversão:	
add-apt-repository multiverse &>> $LOG
echo -e "[ \033[0;32m OK \033[0m ] Repositório multiversão ..."

#	Atualizar lista de repositórios:	
apt -y -q update &>> $LOG
echo -e "[ \033[0;32m OK \033[0m ] Atualização de repositórios ..."

#	Atualizar sistema:	
apt -y -q upgrade &>> $LOG
echo -e "[ \033[0;32m OK \033[0m ] Atualização do sistema ..."

#	Remover pacotes desnecessários:	
apt -y -q autoremove &>> $LOG
echo -e "[ \033[0;32m OK \033[0m ] Remoção de pacodes desnecessários ..."
exit 1