#!/bin/bash
# Autor: Levi Barroso Menezes
# Data de criação: 08/03/2019
# Versão: 0.01
# Ubuntu Server 18.04.x LTS x64
# Kernel Linux 4.15.x
# SAMBA-4.7.x
#
#Variável do servidor:
NOME="srv-dc001"
#
#Variáveis de Rede
INTERFACE="enp0s3"
IP="172.20.0.10"
MASCARA="/16"
GATEWAY="172.20.0.1"
DNS0="172.20.0.10"
DNS1="172.20.0.1"
DNS2="8.8.8.8"
DOMINIO="thz.intra"
#
#Variáveis do NTP
NTPINTRA0="a.st1.ntp.br"
NTPINTRA1="b.st1.ntp.br"
NTPINTRA2="c.st1.ntp.br"
#
#Variáveis do PostgreSQL
USUARIO="supremo"
SENHA="ASD!@#456"
PSENHA="POIUYT"
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
#Instalar postgres
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
#Configurar NTP:
	apt -y -f install ntp ntpdate
	#echo -e "Configurando NTP ..."	
	echo "0.0" > /var/lib/ntp/ntp.drift
	chown -v ntp.ntp /var/lib/ntp/ntp.drift &>> $LOG
	mv -v /etc/ntp.conf /etc/ntp.conf.bkp &>> $LOG
	#
	# Construindo aquivo de configuração do NTP:
	echo "driftfile /var/lib/ntp/ntp.drift" >> /etc/ntp.conf
	echo "#Estatísticas do ntp que permitem verificar o histórico" >> /etc/ntp.conf
	echo "statsdir /var/log/ntpstats/" >> /etc/ntp.conf
	echo "statistics loopstats peerstats clockstats" >> /etc/ntp.conf
	echo "filegen loopstats file loopstats type day enable" >> /etc/ntp.conf
	echo "filegen peerstats file peerstats type day enable" >> /etc/ntp.conf
	echo "filegen clockstats file clockstats type day enable" >> /etc/ntp.conf
	echo " " >> /etc/ntp.conf
	echo "#Servidores publicos ntp.br" >> /etc/ntp.conf
	echo "server a.st1.ntp.br iburst" >> /etc/ntp.conf
	echo "server b.st1.ntp.br iburst" >> /etc/ntp.conf
	echo "server c.st1.ntp.br iburst" >> /etc/ntp.conf
	echo "server d.st1.ntp.br iburst" >> /etc/ntp.conf
	echo "server gps.ntp.br iburst" >> /etc/ntp.conf
	echo "server a.ntp.br iburst" >> /etc/ntp.conf
	echo "server b.ntp.br iburst" >> /etc/ntp.conf
	echo "server c.ntp.br iburst" >> /etc/ntp.conf
	echo " " >> /etc/ntp.conf
	echo "#Servidores internos" >> /etc/ntp.conf
	echo "server @NTPINTRA0 iburst" >> /etc/ntp.conf
	echo "server @NTPINTRA1 iburst" >> /etc/ntp.conf
	echo "server @NTPINTRA2 iburst" >> /etc/ntp.conf
	echo " " >> /etc/ntp.conf
	echo "#Configurações de restrição de acesso" >> /etc/ntp.conf
	echo "restrict 127.0.0.1" >> /etc/ntp.conf
	echo "restrict 127.0.1.1" >> /etc/ntp.conf
	echo "restrict ::1" >> /etc/ntp.conf
	echo "restrict default kod notrap nomodify nopeer noquery" >> /etc/ntp.conf
	echo "restrict -6 default kod notrap nomodify nopeer noquery" >> /etc/ntp.conf
	#
	systemctl stop ntp.service &>> $LOG
	timedatectl set-timezone "America/Fortaleza" &>> $LOG
	ntpdate -dquv $NTP &>> $LOG
	systemctl start ntp.service &>> $LOG
	ntpq -pn &>> $LOG
	hwclock --systohc &>> $LOG
	#echo "Data/Hora de hardware: `hwclock`\n"
	#echo "Data/Hora de software: `date`\n"
	echo -e "[ \033[0;32m OK \033[0m ] NTP ..."
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
	echo "                addresses: [$IP, $ENCAMINHAMENTO]" >> /etc/netplan/01-netcfg.yaml
	echo "                search: [$DOMINIO]" >> /etc/netplan/01-netcfg.yaml
	#
	netplan --debug apply &>> $LOG
	echo -e "[ \033[0;32m OK \033[0m ] Interface de Rede ..."
sleep 1


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
