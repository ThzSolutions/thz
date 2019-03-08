#!/bin/bash
# Autor: Levi Barroso Menezes
# Data de criação: 08/03/2019
# Versão: 0.01
# Ubuntu Server 18.04.x LTS x64
# Kernel Linux 4.15.x
# SAMBA-4.7.x
#
#variáveis do script
HORAINICIAL=`date +%T`
USER=`id -u`
UBUNTU=`lsb_release -rs`
KERNEL=`uname -r | cut -d'.' -f1,2`
LOG="/var/log/$(echo $0 | cut -d'/' -f2)"
#
#Variável do servidor:
NOME="addc-001"
DOMINIO="thz.intra"
FQDN="addc-001.thz.intra"
REINO="THZ.INTRA"
NETBIOS="THZ"
DNS="SAMBA_INTERNAL"
REGRA="dc"
LEVEL="2008_R2"
INTERFACE="enp0s3"
ENCAMINHAMENTO="8.8.8.8"
USUARIO="Supremo"
SENHA="P@ssw0rd"
NTP="a.st1.ntp.br"
IP="172.20.0.10"
MASCARA="/16"
GATEWAY="172.20.0.1"
ARPA="20.172.in-addr.arpa"
ARPAIP="10.0"
#
# Exportando o recurso de Noninteractive:
export DEBIAN_FRONTEND="noninteractive"
#clear
#
#Verificar permissões de usuário:
if [ "$USER" == "0" ]
	then
		echo -e "Permissão compatível .........................[ OK ]"
		sleep 1
	else
		echo -e "O script deve ser executado como root ........[ ER ]"
		exit 1
fi
sleep 5
#
#Verificar versão da distribuição:
if [ "$UBUNTU" == "18.04" ]
	then
		echo -e "Versão da distribuição compatível ............[ OK ]"
		sleep 3
	else
		echo -e "A distribuição deve ser 18.04 ................[ ER ]"
		exit 1
fi
#
#Verificar versão do kernel:
if [ "$KERNEL" == "4.15" ]
	then
		echo -e "O Kernel compatível ..........................[ OK ]"
		sleep 3
	else
		echo -e "O Kernel deve ser 4.15 ou superior ...........[ ER ]"
		exit 1
fi
#
#Verificar Conexão com a internet:
ping -q -c5 google.com > /dev/null
if [ $? -eq 0 ]
	then
		echo -e "Internet .....................................[ OK ]"
		sleep 3
	else
		echo -e "Sem conexão com a internet ...................[ ER ]"
		exit 1
fi
#
#Registrar inicio dos processos:
	echo -e "Início do script $0 em: `date +%d/%m/%Y-"("%H:%M")"`\n" &>> $LOG
#
#Adicionar o Repositório Universal:	
	add-apt-repository universe &>> $LOG
	echo -e "Repositório universal ............................[ OK ]"
sleep 5
#
#Adicionar o Repositório Multiversão:	
	add-apt-repository multiverse &>> $LOG
	echo -e "Repositório multiversão ..........................[ OK ]"
sleep 5
#
#Atualizar lista de repositórios:	
	apt update &>> $LOG
	echo -e "Lista de repositórios ............................[ OK ]"
sleep 5
#
#Atualizar sistema:	
	apt -y upgrade &>> $LOG
	echo -e "Atualização do sistema ...........................[ OK ]"
sleep 5
#
#Remover pacotes desnecessários:	
	apt -y autoremove &>> $LOG
	echo -e "Remoção de pacodes desnecessários ................[ OK ]"
sleep 5
#
#Instalar dependencias:	
	apt -y install ntp ntpdate build-essential libacl1-dev libattr1-dev libblkid-dev libgnutls28-dev libreadline-dev \
	python-dev libpam0g-dev python-dnspython gdb pkg-config libpopt-dev libldap2-dev dnsutils libbsd-dev docbook-xsl acl \
	attr debconf-utils figlet cifs-utils traceroute &>> $LOG
	echo -e "Dependências .....................................[ OK ]"
sleep 5
#
