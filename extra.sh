#!/bin/bash

#	Autor: Levi Barroso Menezes
#	Data de criação: 08/03/2019
#	Versão: 0.01
#	Ubuntu Server 18.04.x LTS x64
#	Kernel Linux 4.15.x
#	extra

#	Instalar curl:	
	apt -y -q install curl &>> $BASELOG
	echo -e "[ \033[0;32m OK \033[0m ] Curl ..."
	sleep 1

#	Instalar gnupg:	
	apt -y -q install gnupg gnupg1 gnupg2 &>> $BASELOG
	echo -e "[ \033[0;32m OK \033[0m ] Gnupg ..."
	sleep 1

#	Instalar traceroute:	
	apt -y -q install traceroute &>> $BASELOG
	echo -e "[ \033[0;32m OK \033[0m ] Traceroute ..."
	sleep 1
#	Instalar ssh:	
	apt -y -q install ssh &>> $BASELOG
	echo -e "[ \033[0;32m OK \033[0m ] SSH ..."
	sleep 1
	
#	Instalar aptitude:	
	apt -y -q install aptitude &>> $BASELOG
	echo -e "[ \033[0;32m OK \033[0m ] Aptitude ..."
	sleep 1
	
#	Instalar htop:	
	apt -y -q install htop &>> $BASELOG
	echo -e "[ \033[0;32m OK \033[0m ] Htop ..."
	sleep 1
	
#	Instalar git:	
	apt -y -q install git &>> $BASELOG
	echo -e "[ \033[0;32m OK \033[0m ] Git ..."
	sleep 1
