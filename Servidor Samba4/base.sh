#!/bin/bash

#	Autor: Levi Barroso Menezes
#	Data de criação: 08/03/2019
#	Versão: 0.01
#	Ubuntu Server 18.04.x LTS x64
#	Kernel Linux 4.15.x
#	Pré instalação

export DEBIAN_FRONTEND="noninteractive"
.var

#	Adicionar programas basicos do sistema
	apt -y -q install software-properties-common &>> $LOG
	echo -e "[ \033[0;32m OK \033[0m ] Programas basicos do sistema ..."
	sleep 1

#	Instalar curl:	
	apt -y -q install curl &>> $LOG
	echo -e "[ \033[0;32m OK \033[0m ] Curl ..."
	sleep 1

#	Instalar gnupg:	
	apt -y -q install gnupg gnupg1 gnupg2 &>> $LOG
	echo -e "[ \033[0;32m OK \033[0m ] Gnupg ..."
	sleep 1

#	Instalar traceroute:	
	apt -y -q install traceroute &>> $LOG
	echo -e "[ \033[0;32m OK \033[0m ] Traceroute ..."
	sleep 1
#	Instalar ssh:	
	apt -y -q install ssh &>> $LOG
	echo -e "[ \033[0;32m OK \033[0m ] SSH ..."
	sleep 1
	
#	Instalar htop:	
	apt -y -q install htop &>> $LOG
	echo -e "[ \033[0;32m OK \033[0m ] Htop ..."
	sleep 1

#	Instalar get:	
	apt -y -q install get &>> $LOG
	echo -e "[ \033[0;32m OK \033[0m ] Get ..."
	sleep 1
	
#	Instalar git:	
	apt -y -q install git &>> $LOG
	echo -e "[ \033[0;32m OK \033[0m ] Git ..."
	sleep 1
	
#	Instalar unzip:	
	apt -y -q unzip &>> $LOG
	echo -e "[ \033[0;32m OK \033[0m ] Unzip ..."
	sleep 1

#	Remover pacotes desnecessários:	
	apt -y -q autoremove &>> $LOG
	echo -e "[ \033[0;32m OK \033[0m ] Remoção de pacodes desnecessários ..."
	sleep 1
exit 1