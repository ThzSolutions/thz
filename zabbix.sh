#!/bin/bash
# Autor: Levi Barroso Menezes
# Data de criação: 08/03/2019
# Versão: 0.01
# Ubuntu Server 18.04.x LTS x64
# Kernel Linux 4.15.x
# SAMBA-4.7.x
#
#Variável do servidor:
NOME="MON-ZAB001"
#
#Variáveis de Rede
INTERFACE="enp0s3"
IPv4="172.20.0.10"
MASCARAv4="/16"
GATEWAYv4="172.20.0.1"
IPv6=""
MASCARAv6=""
GATEWAYv6=""
DNS0="172.20.0.10"
DNS1="172.20.0.1"
DNS2="8.8.8.8"
DNS3=""
DOMINIO="thz.intra"
FQDN="mon-zab001.thz.intra"
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
		echo -e "[ \033[0;33m Pressione <ENTER> se quiser continuar \033[0m"
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
		echo -e "[ \033[0;33m Pressione <ENTER> se quiser continuar \033[0m"
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
		echo -e "[ \033[0;33m Pressione <ENTER> se quiser continuar \033[0m"
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
		echo -e "[ \033[0;33m Pressione <ENTER> se quiser continuar \033[0m"
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
#Adicionar o repositório zabbix:	
	wget https://repo.zabbix.com/zabbix/4.0/ubuntu/pool/main/z/zabbix-release/zabbix-release_4.0-2+bionic_all.deb
	dpkg -i zabbix-release_4.0-2+bionic_all.deb
	echo -e "[ \033[0;32m OK \033[0m ] Repositório zabbix ..."
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
#Instalar zabbix:	
	apt -y install zabbix-server-pgsql zabbix-frontend-php php-pgsql php-snmp php-ldap zabbix-agent
	echo -e "[ \033[0;32m OK \033[0m ] Zabbix ..."
sleep 1
#
#Criar banco de dados:
	export DEBIAN_FRONTEND="interactive"
	echo -e "\033[1;33m Digite uma senha para o banco de dados \033[0m"
	sudo -u postgres createuser --pwprompt zabbix #precisa por a senha!
	export DEBIAN_FRONTEND="noninteractive"
	sudo -u postgres createdb -O zabbix zabbix
	zcat /usr/share/doc/zabbix-server-pgsql*/create.sql.gz | sudo -u zabbix psql zabbix
	echo -e "[ \033[0;32m OK \033[0m ] Banco de dados ..."
sleep 1
#
#Configurar Servidor:
	printf"	###	Nó de configuração distribuida
			NodeID=0

			###	Acesso
			# ListenPort=10051
			# ListenIP=0.0.0.0
			# SourceIP=

			### LOG
			LogFile=/var/log/zabbix/server.log
			LogFileSize=50
			# DebugLevel=3

			### TEMP
			# PidFile=/tmp/zabbix_server.pid
			# TmpDir=/tmp

			###	BANCO DE DADOS
			DBHost=localhost
			DBName=zabbix
			DBUser=zabbix
			DBPassword=
			# DBSchema=
			# DBSocket=
			# DBPort=

			### HISTORICO
			# HistoryStorageURL=
			# HistoryStorageTypes=uint,dbl,str,log,text
			# HistoryStorageDateIndex=0
			# ExportFileSize=1G
			# HistoryCacheSize=16M
			# HistoryIndexCacheSize=4M

			###	START
			# StartPollers=5
			# StartIPMIPollers=0
			# StartPollersUnreachable=7
			# StartHTTPPollers=1
			# Startpreprocessors=3
			# StartTrappers=5
			# StartPingers=1
			# StartDiscoverers=1
			# StartTimers=1
			# StartEscalators=1
			# StartAlerters=3
			# StartJavaPollers=0
			# StartSNMPTrapper=0
			# StartVMwareCollectors=0
			# StartDBSyncers=4
			# StartProxyPollers=1
			# StatsAllowedIP=

			###JAVA
			# JavaGateway=
			# JavaGatewayPort=10052

			### VMWARE
			# VMwareFrequency=60
			# VMwareCacheSize=8M
			# VMwareTimeout=10

			###	SMTP
			SNMPTrapperFile=/var/log/snmptrap/snmptrap.log
			# EnableSNMPBulkRequests=0

			### HOUSEKEEPINGF
			# HousekeepingFrequency=1
			# MaxHousekeeperDelete=500
			# SenderFrequency=30

			### CACHE
			# CacheSize=8M
			# CacheUpdateFrequency=60
			# TrendCacheSize=4M
			# ValueCacheSize=8M

			###	SCRIPTS
			ExternalScripts=/usr/lib/zabbix/externalscripts
			AlertScriptsPath=/usr/lib/zabbix/alertscripts
			FpingLocation=/usr/bin/fping
			Fping6Location=/usr/bin/fping6
			
			###	PROXY
			# ProxyConfigFrequency=3600
			# ProxyDataFrequency=1

			###	SLL
			# SSLCertLocation=${datadir}/zabbix/ssl/certs
			# SSLKeyLocation=${datadir}/zabbix/ssl/keys
			# SSLCALocation=

			###	TLS
			# TLSCAFile=
			# TLSCRLFile=
			# TLSCertFile=
			# TLSKeyFile=

			###	MODULOS
			# LoadModulePath=${libdir}/modules
			# LoadModule=

			###	OUTROS
			Timeout=4
			# SSHKeyLocation=
			# TrapperTimeout=300
			# UnreachablePeriod=45
			# UnavailableDelay=60
			# UnreachableDelay=15
			# AllowRoot=0
			# User=zabbix

			###	INCLUIR
			# Include=/usr/local/etc/zabbix_server.general.conf
			# Include=/usr/local/etc/zabbix_server.conf.d/
			# Include=/usr/local/etc/zabbix_server.conf.d/*.conf" > /etc/zabbix/zabbix_server.conf
	echo -e "[ \033[0;32m OK \033[0m ] Configuração zabbix ..."
	
#
#Configurar apache:
	printf"# Define /zabbix alias, this is the default
			<IfModule mod_alias.c>
				Alias /zabbix /usr/share/zabbix
			</IfModule>

			<Directory '/usr/share/zabbix'>
				Options FollowSymLinks
				AllowOverride None
				Order allow,deny
				Allow from all

				<IfModule mod_php5.c>
					php_value max_execution_time 300
					php_value memory_limit 128M
					php_value post_max_size 16M
					php_value upload_max_filesize 2M
					php_value max_input_time 300
					php_value max_input_vars 10000
					php_value always_populate_raw_post_data -1
					php_value date.timezone America/Fortaleza
				</IfModule>
				<IfModule mod_php7.c>
					php_value max_execution_time 300
					php_value memory_limit 128M
					php_value post_max_size 16M
					php_value upload_max_filesize 2M
					php_value max_input_time 300
					php_value max_input_vars 10000
					php_value always_populate_raw_post_data -1
					php_value date.timezone $ZONA
				</IfModule>
			</Directory>

			<Directory '/usr/share/zabbix/conf'>
				Order deny,allow
				Deny from all
				<files *.php>
					Order deny,allow
					Deny from all
				</files>
			</Directory>

			<Directory '/usr/share/zabbix/app'>
				Order deny,allow
				Deny from all
				<files *.php>
					Order deny,allow
					Deny from all
				</files>
			</Directory>

			<Directory '/usr/share/zabbix/include'>
				Order deny,allow
				Deny from all
				<files *.php>
					Order deny,allow
					Deny from all
				</files>
			</Directory>

			<Directory '/usr/share/zabbix/local'>
				Order deny,allow
				Deny from all
				<files *.php>
					Order deny,allow
					Deny from all
					Order deny,allow
					Deny from all
				</files>
			</Directory>" > /etc/zabbix/apache.conf
	echo -e "[ \033[0;32m OK \033[0m ] Configuração PHP ..."
#
#
#Instalando idioma PT-BR UTF-8:
	locale-gen pt_BR.UTF-8
	echo -e "[ \033[0;32m OK \033[0m ] Idioma PT-BR.UTF8 ..."
sleep 1
#
#Carregar configuralções do zabbix:
	systemctl restart zabbix-server zabbix-agent apache2
	systemctl enable zabbix-server zabbix-agent apache2
	echo -e "[ \033[0;32m OK \033[0m ] Serviços zabbix ..."
#
#NTP:
	bash ntp.sh
	echo -e "[ \033[0;32m OK \033[0m ] NTP ..."
sleep 1
#
#Auterar nome do servidor (HOSTNAME):
	printf "$NOME" > /etc/hostname
	echo -e "[ \033[0;32m OK \033[0m ] Nome do servidor ..."
sleep 1
#
#Configurar interfaces de rede:
	mv /etc/netplan/01-netcfg.yaml /etc/netplan/01-netcfg.yaml.bkp
	printf "network:
			    version: 2
			    renderer: networkd
			    ethernets:
			        $INTERFACE:
			            dhcp4: false
			            dhcp6: yes
			            addresses: [$IPv4$MASCARAv4, $IPv6$MASCARAv6]
			            gateway4: $GATEWAYv4
			            nameservers:
			                addresses: [$DNS0, $DNS1, $DNS2]
			                search: [$DOMINIO]" > /etc/netplan/01-netcfg.yaml
	netplan --debug apply &>> $LOG
	echo -e "[ \033[0;32m OK \033[0m ] Interface de Rede ..."
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
