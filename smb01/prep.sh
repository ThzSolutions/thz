#!/bin/bash
#	Autor: Levi Barroso Menezes

source var.conf

if [ "$USER" == "0" ]
	then
		echo -e "[ \033[0;32m OK \033[0m ] Permissão concedida ..."
	else
		echo -e "[ \033[0;31m ER \033[0m ] Premissões negadas (Root) ..."
		echo -e "\033[0;33m Pressione <ENTER> se quiser continuar ou <CTRL> + C para sair.\033[0m"
		read
fi

#	Verificar versão da distribuição:
if [ "$UBUNTU" == "18.04" ]
	then
		echo -e "[ \033[0;32m OK \033[0m ] Distribuição compatível ..."
	else
		echo -e "[ \033[0;31m ER \033[0m ] Distribuição não homologada (Ubuntu 18.04) ..."
		echo -e "\033[0;33m Pressione <ENTER> se quiser continuar ou <CTRL> + C para sair.\033[0m"
		read
fi

#	Verificar versão do kernel:
if [ "$KERNEL" == "4.15" ]
	then
		echo -e "[ \033[0;32m OK \033[0m ] Kernel compatível ..."
	else
		echo -e "[ \033[0;31m ER \033[0m ] Kernel incompativel (Linux 4.15 ou superior) ..."
		echo -e "\033[0;33m Pressione <ENTER> se quiser continuar ou <CTRL> + C para sair.\033[0m"
		read
fi

#	Verificar conexão com a internet:
ping -q -c1 -w1 br.archive.ubuntu.com > /dev/null
#traceroute br.archive.ubuntu.com > /dev/null
if [ $? -eq 0 ]
	then
		echo -e "[ \033[0;32m OK \033[0m ] Internet ..."
	else
		echo -e "[ \033[0;31m ER \033[0m ] Sem conexão com a internet ..."
		echo -e "\033[0;33m Pressione <ENTER> se quiser continuar ou <CTRL> + C para sair.\033[0m"
		read
fi

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