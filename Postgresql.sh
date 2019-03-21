#!/bin/bash
# Autor: Levi Barroso Menezes
# Data de criação: 21/03/2019
# Versão: 0.01
# Ubuntu Server 18.04.x LTS x64
# Kernel Linux 4.15.x
# POSTGRESQL
#
#Variável do servidor:
NOME="srv-db001"
DOMINIO="thz.intra"
FQDN="srv-db001.thz.intra"
INTERFACE="enp0s3"
IP="172.20.0.20"
MASCARA="/16"
GATEWAY="172.20.0.1"
DNS0="172.20.0.10"
DNS1="172.20.0.1"
DNS2="8.8.8.8"
#
#Variável de serviços:
PSQLUSER="supremo"
PSQLPASSWORD="ASD!@345"
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
#clear
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
fi
sleep 1
#
#Verificar versão da distribuição:
if [ "$UBUNTU" == "18.04" ]
	then
		echo -e "[ \033[0;32m OK \033[0m ] Versão da distribuição compatível ..."
		sleep 1
	else
		echo -e "[ \033[0;31m ER \033[0m ] Distribuição não homologada (Ubuntu 18.04) ..."
fi
sleep 1
#
#Verificar versão do kernel:
if [ "$KERNEL" == "4.15" ]
	then
		echo -e "[ \033[0;32m OK \033[0m ] O Kernel compatível ..."
	else
		echo -e "[ \033[0;31m ER \033[0m ] O Kernel incompativel (Linux 4.15 ou superior) ..."
		exit 1
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
#Adicionar o repositório postgresql
  echo "deb http://apt.postgresql.org/pub/repos/apt/ $(lsb_release -cs)-pgdg main" >> /etc/apt/sources.list.d/pgdg.list
  wget --uiet -o - http://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
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
#Instalar postgresql
  apt -y install postgres postgresql-contrib postgres-client
  echo -e "[ \033[0;32m OK \033[0m ] Postgresql ..."
sleep 1
#
#Configrando postgres
  su postgres -c -psql
  ALTER USER postgres PASSWORD "$PSQLPASSWORD";
  CREATE USER $PSQLUSER SUPERUSER CREATEDB CREATEROLE CREATEUSER INHERIT LOGIN REPLICATION ENCRYPTED PASSWORD "$PSQLPASSWORD";
  \q
  echo -e "[ \033[0;32m OK \033[0m ] Interface de Rede ..."
sleep 1
#
#Configurar interfaces de rede:
	mv /etc/netplan/01-netcfg.yaml /etc/netplan/01-netcfg.yaml.bkp
	#
	# Construindo aquivo de configuração do NETPLAN:
	echo "network:" >> /etc/netplan/01-netcfg.yaml
  echo "    version: 2" >> /etc/netplan/01-netcfg.yaml
  echo "    renderer: networkd" >> /etc/netplan/01-netcfg.yaml
	echo "    ethernets:" >> /etc/netplan/01-netcfg.yaml
	echo "        $INTERFACE:" >> /etc/netplan/01-netcfg.yaml
	echo "            dhcp4: false" >> /etc/netplan/01-netcfg.yaml
	echo "            addresses: [$IP$MASCARA]" >> /etc/netplan/01-netcfg.yaml
	echo "            gateway4: $GATEWAY" >> /etc/netplan/01-netcfg.yaml
	echo "            nameservers:" >> /etc/netplan/01-netcfg.yaml
	echo "                addresses: [$DNS0, $DNS1, $DNS2]" >> /etc/netplan/01-netcfg.yaml
	echo "                search: [$DOMINIO]" >> /etc/netplan/01-netcfg.yaml
	#
	netplan --debug apply &>> $LOG
	echo -e "[ \033[0;32m OK \033[0m ] Interface de Rede ..."
sleep 1
#
#Auterar nome do servidor (HOSTNAME):
	mv -v /etc/hostname /etc/hostname.bkp &>> $LOG
	#
	# Construindo aquivo de configuração do HOSTNAME:
	echo "$NOME" >> /etc/hostname
	#
	echo -e "[ \033[0;32m OK \033[0m ] Nome do servidor ..."
sleep 1
#
HORAFINAL=$(date +%T)
HORAINICIAL01=$(date -u -d "$HORAINICIAL" +"%s")
HORAFINAL01=$(date -u -d "$HORAFINAL" +"%s")
TEMPO=$(date -u -d "0 $HORAFINAL01 sec - $HORAINICIAL01 sec" +"%H:%M:%S")
	echo -e "Tempo de execução $0: $TEMPO"
	echo -e "Fim do script $0 em: `date +%d/%m/%Y-"("%H:%M")"`\n" &>> $LOG
	echo -e "\033[0;31m É nescesario reiniciar o servidor !!! \033[0m"
	echo -e "Pressione \033[0;32m <Enter> \033[0m para finalizar o processo."
read
exit 1
