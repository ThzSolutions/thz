#!/bin/bash
# Autor: Levi Barroso Menezes
# Data de criação: 08/03/2019
# Versão: 0.01
# Ubuntu Server 18.04.x LTS x64
# Kernel Linux 4.15.x
# SAMBA-4.7.x
#
#Variável do servidor:
NOME="srv-dados001"
#
#Variáveis postgres
USUARIO="supremo"
SENHA="QWE!@#456"
PSENHA="ASD!@#456"
#
#Variáveis de Rede
NETPLAN="true"
INTERFACE="enp0s3"
IPv4="172.20.0.101"
MASCARAv4="/16"
GATEWAYv4="172.20.0.1"
IPv6=""
MASCARAv6=""
GATEWAYv6=""
DNS0="8.8.8.8"
DNS1="4.4.8.8"
DNS2="8.8.4.4"
DNS3="4.4.4.4"
DOMINIO="thz.intra"
FQDN="srv-dados001.thz.intra"
ZONA="America/Fortaleza"
#
#variáveis do script
HORAINICIAL=`date +%T`
USER=`id -u`
UBUNTU=`lsb_release -rs`
KERNEL=`uname -r | cut -d'.' -f1,2`
LOG="/var/log/$(echo $0 | cut -d'/' -f2)"
#
# Exportando o recurso de Noninteractive:
export DEBIAN_FRONTEND="noninteractive"
#
#Registrar inicio dos processos:
echo -e "Início do script $0 em: `date +%d/%m/%Y-"("%H:%M")"`\n" &>> $LOG
#
#Verificar permissões de usuário:
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
		echo -e "[ \033[0;32m OK \033[0m ] Versão da distribuição compatível ..."
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
		echo -e "[ \033[0;32m OK \033[0m ] O Kernel compatível ..."
	else
		echo -e "[ \033[0;31m ER \033[0m ] O Kernel incompativel (Linux 4.15 ou superior) ..."
		echo -e "\033[0;33m Pressione <ENTER> se quiser continuar ou <CTRL> + C para sair.\033[0m"
		read
fi
sleep 1
#
#Verificar conexão com a internet:
ping -q -c5 google.com > /dev/null
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
	add-apt-repository universe &>> $LOG
	echo -e "[ \033[0;32m OK \033[0m ] Repositório universal ..."
sleep 1
#
#Adicionar o repositório multiversão:	
	add-apt-repository multiverse &>> $LOG
	echo -e "[ \033[0;32m OK \033[0m ] Repositório multiversão ..."
sleep 1
#
#Adicionar o repositório postgres:
	echo "deb http://apt.postgresql.org/pub/repos/apt/ $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list
	wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add - &>> $LOG
	echo -e "[ \033[0;32m OK \033[0m ] Repositório postgres ..."
sleep 1
#
#Atualizar lista de repositórios:	
	apt update &>> $LOG
	echo -e "[ \033[0;32m OK \033[0m ] Atualização de repositórios ..."
sleep 1
#
#Atualizar sistema:	
	apt -y upgrade &>> $LOG
	echo -e "[ \033[0;32m OK \033[0m ] Atualização do sistema ..."
sleep 1
#
#Remover pacotes desnecessários:	
	apt -y autoremove &>> $LOG
	echo -e "[ \033[0;32m OK \033[0m ] Remoção de pacodes desnecessários ..."
sleep 1
#
#Instalar postgres:	
	apt -y install postgresql postgresql-client postgresql-contrib
	echo -e "[ \033[0;32m OK \033[0m ] Postgres ..."
sleep 1
#
#Configurar usuários postgres
	su postgres -c psql
	CREATE USER $USUARIO INHERIT CREATEDB CREATEROLE CREATEUSER REPLICATION ENCRYPTED LOGIN PASSWORD '$SENHA';
	ALTER USER postgres PASSWORD '$PSENHA';
	\q
	echo -e "[ \033[0;32m OK \033[0m ] Usuários postgres ..."
sleep 1
#
#NTP:
	bash ntp.sh
	echo -e "[ \033[0;32m OK \033[0m ] NTP ..."
sleep 1
#
#Auterar nome do servidor (HOSTNAME):
	printf "$NOME" > /etc/hostname
	printf "
127.0.0.1		$NOME	localhost	$FQDN
::1				$NOME	localhost	$FQDN
$IP				$NOME	localhost	$FQDN
	" > /etc/hosts
	echo -e "[ \033[0;32m OK \033[0m ] Nome do servidor ..."
sleep 1
#
#Configurar interfaces de rede:
if [ "$NETPLAN" == "true" ]
	then
		mv /etc/netplan/01-netcfg.yaml /etc/netplan/01-netcfg.yaml.bkp
		printf "
network:
	version: 2
	renderer: networkd
	ethernets:
		$INTERFACE:
			dhcp4: false
			dhcp6: yes
			addresses: [$IPv4$MASCARAv4, $IPv6$MASCARAv6]
			gateway4: $GATEWAYv4
			nameservers:
				addresses: [$DNS0, $DNS1, $DNS2, $DNS3]
				search: [$DOMINIO]
		" > /etc/netplan/01-netcfg.yaml
		netplan --debug apply &>> $LOG
		echo -e "[ \033[0;32m OK \033[0m ] Interface de Rede ..."
	else
fi
sleep 1
#
#Finalizar
HORAFINAL=$(date +%T)
HORAINICIAL01=$(date -u -d "$HORAINICIAL" +"%s")
HORAFINAL01=$(date -u -d "$HORAFINAL" +"%s")
TEMPO=$(date -u -d "0 $HORAFINAL01 sec - $HORAINICIAL01 sec" +"%H:%M:%S")
	echo -e "Tempo de execução $0: $TEMPO"
	echo -e "Fim do script $0 em: `date +%d/%m/%Y-"("%H:%M")"`\n" &>> $LOG
	echo -e "Acesso ao banco de dados: $IP:5432"
	echo -e "\033[0;31m Pode ser nescesario reiniciar o servidor !!! \033[0m"
	echo -e "Pressione \033[0;32m <Enter> \033[0m para finalizar o processo."
	read
exit 1
