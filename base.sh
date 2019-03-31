#!/bin/bash

#	Autor: Levi Barroso Menezes
#	Data de criação: 08/03/2019
#	Versão: 0.01
#	Ubuntu Server 18.04.x LTS x64
#	Kernel Linux 4.15.x
#	Pré instalação

#	Verificações:
	USER=`id -u`
	UBUNTU=`lsb_release -rs`
	KERNEL=`uname -r | cut -d'.' -f1,2`
	BASELOG="/var/log/base.sh"
	
#	Variáveis do NTP
	SERVIDORNTP0="a.ntp.br"
	SERVIDORNTP1="b.ntp.br"
	SERVIDORNTP2="c.ntp.br"
	ZONA="America/Fortaleza"
	if [ "$USER" == "0" ]
		then
			echo -e "[ \033[0;32m OK \033[0m ] Permissão concedida ..."
		else
			echo -e "[ \033[0;31m ER \033[0m ] Premissões negadas (Root) ..."
			echo -e "\033[0;33m Pressione <ENTER> se quiser continuar ou <CTRL> + C para sair.\033[0m"
			read
	fi
	sleep 1

#	Verificar versão da distribuição:
	if [ "$UBUNTU" == "18.04" ]
		then
			echo -e "[ \033[0;32m OK \033[0m ] Distribuição compatível ..."
		else
			echo -e "[ \033[0;31m ER \033[0m ] Distribuição não homologada (Ubuntu 18.04) ..."
			echo -e "\033[0;33m Pressione <ENTER> se quiser continuar ou <CTRL> + C para sair.\033[0m"
			read
	fi
	sleep 1

#	Verificar versão do kernel:
	if [ "$KERNEL" == "4.15" ]
		then
			echo -e "[ \033[0;32m OK \033[0m ] Kernel compatível ..."
		else
			echo -e "[ \033[0;31m ER \033[0m ] Kernel incompativel (Linux 4.15 ou superior) ..."
			echo -e "\033[0;33m Pressione <ENTER> se quiser continuar ou <CTRL> + C para sair.\033[0m"
			read
	fi
	sleep 1

#	Verificar conexão com a internet:
#	ping -q -c1 -w1 br.archive.ubuntu.com > /dev/null
	traceroute br.archive.ubuntu.com > /dev/null
	if [ $? -eq 0 ]
		then
			echo -e "[ \033[0;32m OK \033[0m ] Internet ..."
		else
			echo -e "[ \033[0;31m ER \033[0m ] Sem conexão com a internet ..."
			echo -e "\033[0;33m Pressione <ENTER> se quiser continuar ou <CTRL> + C para sair.\033[0m"
			read
	fi
	sleep 1

#	Adicionar programas basicos do sistema
	apt -y -q update &>> $BASELOG
	apt -y -q install software-properties-common &>> $BASELOG
	echo -e "[ \033[0;32m OK \033[0m ] Programas basicos do sistema ..."
	sleep 1
	
#	Adicionar o repositório universal:	
	add-apt-repository universe &>> $BASELOG
	echo -e "[ \033[0;32m OK \033[0m ] Repositório universal ..."
	sleep 1

#	Adicionar o repositório multiversão:	
	add-apt-repository multiverse &>> $BASELOG
	echo -e "[ \033[0;32m OK \033[0m ] Repositório multiversão ..."
	sleep 1

#	Atualizar lista de repositórios:	
	apt -y -q update &>> $BASELOG
	echo -e "[ \033[0;32m OK \033[0m ] Atualização de repositórios ..."
	sleep 1

#	Atualizar sistema:	
	apt -y -q upgrade &>> $BASELOG
	echo -e "[ \033[0;32m OK \033[0m ] Atualização do sistema ..."
	sleep 1

#	Remover pacotes desnecessários:	
	apt -y -q autoremove &>> $BASELOG
	echo -e "[ \033[0;32m OK \033[0m ] Remoção de pacodes desnecessários ..."
	sleep 1
	
#	Instalar NTP:
	apt -y -q install ntp ntpdate &>> $BASELOG
	echo -e "[ \033[0;32m OK \033[0m ] NTP ..."

#	Configurar NTP:
	printf "0.0" > /var/lib/ntp/ntp.drift
	chown ntp.ntp /var/lib/ntp/ntp.drift
	mv /etc/ntp.conf /etc/ntp.conf.bkp
	printf "
driftfile /var/lib/ntp/ntp.drift

#	Estatísticas do ntp que permitem verificar o histórico
statsdir /var/log/ntpstats/
statistics loopstats peerstats clockstats
filegen loopstats file loopstats type day enable
filegen peerstats file peerstats type day enable
filegen clockstats file clockstats type day enable

#	Servidores publicos ntp.br
server a.st1.ntp.br iburst
server b.st1.ntp.br iburst
server c.st1.ntp.br iburst
server d.st1.ntp.br iburst
server gps.ntp.br iburst
server @SERVIDORNTP0 iburst
server @SERVIDORNTP1 iburst
server @SERVIDORNTP2 iburst

#	Configurações de restrição de acesso
restrict 127.0.0.1
restrict 127.0.1.1
restrict ::1
restrict default kod notrap nomodify nopeer noquery
restrict -6 default kod notrap nomodify nopeer noquery
#	" > /etc/ntp.conf
	timedatectl set-timezone "$ZONA" &>> $BASELOG
	chown root:ntp /var/lib/samba/ntp_signd/
	ntpdate -dquv $SERVIDORNTP0 &>> $BASELOG
	systemctl restart ntp.service &>> $BASELOG
	hwclock --systohc &>> $BASELOG
	echo -e "[ \033[0;32m OK \033[0m ] Configuração NTP ..."
	sleep 1
exit 1
