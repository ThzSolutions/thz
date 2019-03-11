#!/bin/bash
# Autor: Levi Barroso Menezes
# Data de criação: 08/03/2019
# Versão: 0.01
# Ubuntu Server 18.04.x LTS x64
# Kernel Linux 4.15.x
# SAMBA-4.7.x
#
#Variável do servidor:
NOME="bkp-001"
DOMINIO="thz.intra"
FQDN="bkp-001.thz.intra"
DISTRO="xUbuntu_18.04/"
USUARIO="supremo"
PASSWORD="ASD!@#456"
PROFILE="webui-admin"
POSTFIX="No configuration"
#
#Variaveis de Rede:
INTERFACE="enp0s3"
IP="172.20.0.20"
MASCARA="/16"
GATEWAY="172.20.0.1"
DNS="172.20.0.10, 8.8.8.8"
DOMINIO="THZ.INTRA"
NTP="172.20.0.1"
ZONATEMPORAL="America/Fortaleza"
#
#variáveis do script:
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
		echo -e "Permissão compatível ...................................[\033[0;32m OK \033[0m]"
		sleep 1
	else
		echo -e "O script deve ser executado como root ..................[\033[0;31m ER \033[0m]"
		exit 1
fi
#
#Verificar versão da distribuição:
if [ "$UBUNTU" == "18.04" ]
	then
		echo -e "Versão da distribuição compatível ......................[\033[0;32m OK \033[0m]"
		sleep 1
	else
		echo -e "A distribuição deve ser 18.04 ..........................[\033[0;31m ER \033[0m]"
		sleep 1
fi
#
#Verificar versão do kernel:
if [ "$KERNEL" == "4.15" ]
	then
		echo -e "O Kernel compatível ....................................[\033[0;32m OK \033[0m]"
		sleep 1
	else
		echo -e "O Kernel deve ser 4.15 ou superior .....................[\033[0;31m ER \033[0m]"
		sleep 1
fi
#
#Verificar Conexão com a internet:
ping -q -c5 google.com > /dev/null
if [ $? -eq 0 ]
	then
		echo -e "Internet ...............................................[\033[0;32m OK \033[0m]"
		sleep 1
	else
		echo -e "Sem conexão com a internet .............................[\033[0;31m ER \033[0m]"
		sleep 1
fi
#
#Adicionar o Repositório Universal:	
	add-apt-repository universe &>> $LOG
	echo -e "Repositório universal ..................................[\033[0;32m OK \033[0m]"
sleep 1
#
#Adicionar o Repositório Multiversão:	
	add-apt-repository multiverse &>> $LOG
	echo -e "Repositório multiversão ................................[\033[0;32m OK \033[0m]"
sleep 1
#
#Adicionar o Repositório BareOS:
	printf "deb http://download.bareos.org/bareos/release/latest/$DISTRO /\n" > /etc/apt/sources.list.d/bareos.list
	wget -q "http://download.bareos.org/bareos/release/latest/$DISTRO/Release.key" -O- | apt-key add - &>> $LOG
	echo -e "Repositório BareOS .....................................[\033[0;32m OK \033[0m]"
sleep 1
#
#Atualizar lista de repositórios:	
	apt update &>> $LOG
	echo -e "Lista de repositórios ..................................[\033[0;32m OK \033[0m]"
sleep 1
#
#Atualizar sistema:	
	apt -y upgrade &>> $LOG
	echo -e "Atualizar do sistema ...................................[\033[0;32m OK \033[0m]"
sleep 1
#
#Remover pacotes desnecessários:	
	apt -y autoremove &>> $LOG
	echo -e "Remoção de pacodes desnecessários ......................[\033[0;32m OK \033[0m]"
sleep 1
#
#Instalar dependencias:	
	apt -y install mariadb-server ntp traceroute apache2 &>> $LOG
	echo -e "Dependências ...........................................[\033[0;32m OK \033[0m]"
sleep 1
#
#Configurar debconf
	echo "bareos-database-common bareos-database-common/dbconfig-install boolean true" | debconf-set-selections
	echo "bareos-database-common bareos-database-common/mysql/app-pass password $PASSWORD" | debconf-set-selections
	echo "bareos-database-common bareos-database-common/app-password-confirm password $PASSWORD" | debconf-set-selections
	echo "postfix postfix/main_mailer_type string $POSTFIX" | debconf-set-selections
	debconf-show bareos-database-common &>> $LOG
	debconf-show postfix &>> $LOG
sleep 1
#
#Instalar BareOS server.
	apt -y install bareos bareos-tools bareos-bconsole &>> $LOG
	echo -e "Instalar BareOS ........................................[\033[0;32m OK \033[0m]"
sleep 1
#
#~Configurar a base de dados MariaDB
	apt -y install bareos-database-mariadb &>> $LOG
	echo -e "Criar base de dados ....................................[\033[0;32m OK \033[0m]"
sleep 1
#
#Instalar interface WEB BareOS
	apt -y install bareos-webui &>> $LOG
	echo -e "Instalar interface web .................................[\033[0;32m OK \033[0m]"
	systemctl start bareos-dir.service &>> $LOG
	systemctl start bareos-sd.service &>> $LOG
	systemctl start bareos-fd.service &>> $LOG
	systemctl restart apache2.service &>> $LOG
sleep 1
#
#Criar usuários
	echo -e "configure add console name=$USUARIO password=$PASSWORD profile=$PROFILE tlsenable=no" | bconsole &>> $LOG
	echo -e "reload" | bconsole &>> $LOG
	echo -e "Criar usuários .........................................[\033[0;32m OK \033[0m]"
sleep 1
#
#Configurar interfaces de rede:
	mv /etc/netplan/50-cloud-init.yaml /etc/netplan/50-cloud-init.yaml.bkp
	#
	# Construindo aquivo de configuração do NETPLAN:
	echo "network:" >> /etc/netplan/50-cloud-init.yaml
	echo "    ethernets:" >> /etc/netplan/50-cloud-init.yaml
	echo "        $INTERFACE:" >> /etc/netplan/50-cloud-init.yaml
	echo "            dhcp4: false" >> /etc/netplan/50-cloud-init.yaml
	echo "            addresses: [$IP$MASCARA]" >> /etc/netplan/50-cloud-init.yaml
	echo "            gateway4: $GATEWAY" >> /etc/netplan/50-cloud-init.yaml
	echo "            nameservers:" >> /etc/netplan/50-cloud-init.yaml
	echo "                addresses: [$DNS]" >> /etc/netplan/50-cloud-init.yaml
	echo "                search: [$DOMINIO]" >> /etc/netplan/50-cloud-init.yaml
	echo "    version: 2" >> /etc/netplan/50-cloud-init.yaml
	#
	netplan --debug apply &>> $LOG
	echo -e "Interface de Rede ......................................[\033[0;32m OK \033[0m]"
sleep 1
#
#Auterar nome do servidor (HOSTNAME):
	mv -v /etc/hostname /etc/hostname.bkp &>> $LOG
	#
	# Construindo aquivo de configuração do HOSTNAME:
	echo "$NOME" >> /etc/hostname
	echo -e "Nome do servidor (hostname) ............................[\033[0;32m OK \033[0m]"
sleep 1
#
#Configurar NTP:
	#echo -e "Configurando NTP ..."	
	echo "0.0" > /var/lib/ntp/ntp.drift
	chown -v ntp.ntp /var/lib/ntp/ntp.drift &>> $LOG
	mv -v /etc/ntp.conf /etc/ntp.conf.bkp &>> $LOG
	#
	# Construindo aquivo de configuração do NTP:
	echo "driftfile /var/lib/ntp/ntp.drift" >> /etc/ntp.conf
	#
	echo "#Estatísticas do ntp que permitem verificar o histórico" >> /etc/ntp.conf
	echo "statsdir /var/log/ntpstats/" >> /etc/ntp.conf
	echo "statistics loopstats peerstats clockstats" >> /etc/ntp.conf
	echo "filegen loopstats file loopstats type day enable" >> /etc/ntp.conf
	echo "filegen peerstats file peerstats type day enable" >> /etc/ntp.conf
	echo "filegen clockstats file clockstats type day enable" >> /etc/ntp.conf
	echo " " >> /etc/ntp.conf
	#
	echo "#Servidores locais" >> /etc/ntp.conf
	echo "server $NTP iburst" >> /etc/ntp.conf
	echo " " >> /etc/ntp.conf
	#
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
	#
	echo "#Configuraçõess de restrição de acesso" >> /etc/ntp.conf
	echo "restrict 127.0.0.1" >> /etc/ntp.conf
	echo "restrict 127.0.1.1" >> /etc/ntp.conf
	echo "restrict ::1" >> /etc/ntp.conf
	echo "restrict default kod notrap nomodify nopeer noquery" >> /etc/ntp.conf
	echo "restrict -6 default kod notrap nomodify nopeer noquery" >> /etc/ntp.conf
	#
	systemctl stop ntp.service &>> $LOG
	timedatectl set-timezone "$ZONATEMPORAL" &>> $LOG
	ntpdate -dquv $NTP &>> $LOG
	systemctl start ntp.service &>> $LOG
	ntpq -pn &>> $LOG
	hwclock --systohc &>> $LOG
	#echo "Data/Hora de hardware: `hwclock`\n"
	#echo "Data/Hora de software: `date`\n"
	echo -e "NTP ....................................................[\033[0;32m OK \033[0m]"
sleep 1
# update-rc.d mysql defaults 
# mysql_secure_installation
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

