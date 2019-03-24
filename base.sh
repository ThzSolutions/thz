#!/bin/bash
# Autor: Levi Barroso Menezes
# Data de criação: 08/03/2019
# Versão: 0.01
# Ubuntu Server 18.04.x LTS x64
# Kernel Linux 4.15.x
# Pré instalação
#
#Verificar permissões de usuário:
USER=`id -u`
UBUNTU=`lsb_release -rs`
KERNEL=`uname -r | cut -d'.' -f1,2`
BASELOG="/var/log/base.sh"
if [ "$USER" == "0" ]
	then
		echo -e "[ \033[0;32m OK \033[0m ] Permissão concedida ..."
	else
		echo -e "[ \033[0;31m ER \033[0m ] Premissões negadas (Root) ..."
		echo -e "\033[0;33m Pressione <ENTER> se quiser continuar ou <CTRL> + C para sair.\033[0m"
		read
fi
sleep 1
#
#Verificar versão da distribuição:
if [ "$UBUNTU" == "18.04" ]
	then
		echo -e "[ \033[0;32m OK \033[0m ] Distribuição compatível ..."
	else
		echo -e "[ \033[0;31m ER \033[0m ] Distribuição não homologada (Ubuntu 18.04) ..."
		echo -e "\033[0;33m Pressione <ENTER> se quiser continuar ou <CTRL> + C para sair.\033[0m"
		read
fi
sleep 1
#
#Verificar versão do kernel:
if [ "$KERNEL" == "4.15" ]
	then
		echo -e "[ \033[0;32m OK \033[0m ] Kernel compatível ..."
	else
		echo -e "[ \033[0;31m ER \033[0m ] Kernel incompativel (Linux 4.15 ou superior) ..."
		echo -e "\033[0;33m Pressione <ENTER> se quiser continuar ou <CTRL> + C para sair.\033[0m"
		read
fi
sleep 1
#
#Verificar conexão com a internet:
ping -q -c2 -w1 google.com > /dev/null
if [ $? -eq 0 ]
	then
		echo -e "[ \033[0;32m OK \033[0m ] Internet ..."
	else
		echo -e "[ \033[0;31m ER \033[0m ] Sem conexão com a internet ..."
		echo -e "\033[0;33m Pressione <ENTER> se quiser continuar ou <CTRL> + C para sair.\033[0m"
		read
fi
sleep 1
#
#Adicionar o repositório universal:	
	add-apt-repository universe &>> $BASELOG
	echo -e "[ \033[0;32m OK \033[0m ] Repositório universal ..."
sleep 1
#
#Adicionar o repositório multiversão:	
	add-apt-repository multiverse &>> $BASELOG
	echo -e "[ \033[0;32m OK \033[0m ] Repositório multiversão ..."
sleep 1
#
#Atualizar lista de repositórios:	
	apt -y -q update &>> $BASELOG
	echo -e "[ \033[0;32m OK \033[0m ] Atualização de repositórios ..."
sleep 1
#
#Atualizar sistema:	
	apt -y -q upgrade &>> $BASELOG
	echo -e "[ \033[0;32m OK \033[0m ] Atualização do sistema ..."
sleep 1
#
#Remover pacotes desnecessários:	
	apt -y -q autoremove &>> $BASELOG
	echo -e "[ \033[0;32m OK \033[0m ] Remoção de pacodes desnecessários ..."
sleep 1
#
#Instalar curl:	
	apt -y -q install curl &>> $BASELOG
	echo -e "[ \033[0;32m OK \033[0m ] Curl ..."
sleep 1
#
#Instalar gnupg:	
	apt -y -q install gnupg gnupg1 gnupg2 &>> $BASELOG
	echo -e "[ \033[0;32m OK \033[0m ] Gnupg ..."
sleep 1
#
#Instalar traceroute:	
	apt -y -q install traceroute &>> $BASELOG
	echo -e "[ \033[0;32m OK \033[0m ] Traceroute ..."
sleep 1
#
#Instalar ssh:	
	apt -y -q install ssh &>> $BASELOG
	echo -e "[ \033[0;32m OK \033[0m ] SSH ..."
sleep 1
#
#Instalar htop:	
	apt -y -q install htop &>> $BASELOG
	echo -e "[ \033[0;32m OK \033[0m ] Htop ..."
sleep 1
exit 1
