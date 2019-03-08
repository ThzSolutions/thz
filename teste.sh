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
#
#Verificar versão da distribuição:
if [ "$UBUNTU" == "18.04" ]
	then
		echo -e "Versão da distribuição compatível ............[ OK ]"
		sleep 1
	else
		echo -e "A distribuição deve ser 18.04 ................[ ER ]"
		exit 1
fi
#
#Verificar versão do kernel:
if [ "$KERNEL" == "4.15" ]
	then
		echo -e "O Kernel compatível ..........................[ OK ]"
		sleep 1
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
		sleep 1
	else
		echo -e "Sem conexão com a internet ...................[ ER ]"
		sleep 1
fi
#
#Registrar inicio dos processos:
	echo -e "Início do script $0 em: `date +%d/%m/%Y-"("%H:%M")"`\n" &>> $LOG
#
#Adicionar o Repositório Universal:	
	add-apt-repository universe &>> $LOG
	echo -e "Repositório universal ............................[ OK ]"
sleep 1
#
#Adicionar o Repositório Multiversão:	
	add-apt-repository multiverse &>> $LOG
	echo -e "Repositório multiversão ..........................[ OK ]"
sleep 1
#
#Atualizar lista de repositórios:	
	apt update &>> $LOG
	echo -e "Lista de repositórios ............................[ OK ]"
sleep 1
#
#Atualizar sistema:	
	apt -y upgrade &>> $LOG
	echo -e "Atualização do sistema ...........................[ OK ]"
sleep 1
#
#Remover pacotes desnecessários:	
	apt -y autoremove &>> $LOG
	echo -e "Remoção de pacodes desnecessários ................[ OK ]"
sleep 1
#
#Instalar dependencias:	
	apt -y install ntp ntpdate build-essential libacl1-dev libattr1-dev libblkid-dev libgnutls28-dev libreadline-dev \
	python-dev libpam0g-dev python-dnspython gdb pkg-config libpopt-dev libldap2-dev dnsutils libbsd-dev docbook-xsl acl \
	attr debconf-utils figlet cifs-utils traceroute &>> $LOG
	echo -e "Dependências .....................................[ OK ]"
sleep 1
#
#Instalar e configurar KERBEROS:
	#echo -e "Configurando KERBEROS ..."
	echo "krb5-config krb5-config/default_realm string $REINO" | debconf-set-selections
	echo "krb5-config krb5-config/kerberos_servers string $FQDN" | debconf-set-selections
	echo "krb5-config krb5-config/admin_server string $FQDN" | debconf-set-selections
	echo "krb5-config krb5-config/add_servers_realm string $REINO" | debconf-set-selections
	echo "krb5-config krb5-config/add_servers boolean true" | debconf-set-selections
	echo "krb5-config krb5-config/read_config boolean true" | debconf-set-selections
	debconf-show krb5-config &>> $LOG
	apt -y install krb5-user krb5-config &>> $LOG
	mv -v /etc/krb5.conf /etc/krb5.conf.bkp &>> $LOG
	#
	# Construindo aquivo de configuração do KERBEROS:
	echo "[libdefaults]" >> /etc/krb5.conf &>> $LOG
	echo "	# Realm padrão" >> /etc/krb5.conf
	echo "	default_realm = $REINO" >> /etc/krb5.conf &>> $LOG
	echo " " >> /etc/krb5.conf
	#
	echo "# Opções utilizadas pela SAMBA4" >> /etc/krb5.conf
	echo "	dns_lookup_realm = false" >> /etc/krb5.conf &>> $LOG
	echo "	dns_lookup_kdc = true" >> /etc/krb5.conf &>> $LOG
	echo " " >> /etc/krb5.conf
	#
	echo "# Confguração padrão do Kerneros" >> /etc/krb5.conf
	echo "	krb4_config = /etc/krb.conf" >> /etc/krb5.conf &>> $LOG
	echo "	krb4_realms = /etc/krb.realms" >> /etc/krb5.conf &>> $LOG
	echo "	kdc_timesync = 1" >> /etc/krb5.conf &>> $LOG
	echo "	ccache_type = 4" >> /etc/krb5.conf &>> $LOG
	echo "	forwardable = true" >> /etc/krb5.conf &>> $LOG
	echo "	proxiable = true" >> /etc/krb5.conf &>> $LOG
	echo "	v4_instance_resolve = false" >> /etc/krb5.conf &>> $LOG
	echo "	v4_name_convert = {" >> /etc/krb5.conf
	echo "		host = {" >> /etc/krb5.conf
	echo "			rcmd = host" >> /etc/krb5.conf &>> $LOG
	echo "			ftp = ftp" >> /etc/krb5.conf &>> $LOG
	echo "		}" >> /etc/krb5.conf
	echo "		plain = {" >> /etc/krb5.conf
	echo "			something = something-else" >> /etc/krb5.conf &>> $LOG
	echo "		}" >> /etc/krb5.conf
	echo "	}" >> /etc/krb5.conf
	echo "	fcc-mit-ticketflags = true" >> /etc/krb5.conf &>> $LOG
	echo " " >> /etc/krb5.conf
	#
	echo "# Reino padrão" >> /etc/krb5.conf
	echo "[realms]" >> /etc/krb5.conf &>> $LOG
	echo "	$REINO = {" >> /etc/krb5.conf
	echo "		# Servidor de geração de KDC" >> /etc/krb5.conf
	echo "		kdc = addc-001.thz.intra" >> /etc/krb5.conf &>> $LOG
	echo "		#" >> /etc/krb5.conf
	echo "		# Servidor de Administração do KDC" >> /etc/krb5.conf
	echo "		admin_server = addc-001.thz.intra" >> /etc/krb5.conf &>> $LOG
	echo "		#" >> /etc/krb5.conf
	echo "		# Domínio padrão" >> /etc/krb5.conf
	echo "		default_domain = thz.intra" >> /etc/krb5.conf &>> $LOG
	echo "	}" >> /etc/krb5.conf
	echo " " >> /etc/krb5.conf
	#
	echo "# Domínio Realm" >> /etc/krb5.conf
	echo "[domain_realm]" >> /etc/krb5.conf &>> $LOG
	echo "	.thz.intra = THZ.INTRA" >> /etc/krb5.conf &>> $LOG
	echo "	thz.intra = THZ.INTRA" >> /etc/krb5.conf &>> $LOG
	echo " " >> /etc/krb5.conf
	#
	echo "# Geração do Tickets" >> /etc/krb5.conf
	echo "[login]" >> /etc/krb5.conf &>> $LOG
	echo "	krb4_convert = true" >> /etc/krb5.conf &>> $LOG
	echo "	krb4_get_tickets = false" >> /etc/krb5.conf &>> $LOG
	echo " " >> /etc/krb5.conf
	#
	echo "# Log dos tickets do Kerberos" >> /etc/krb5.conf
	echo "[logging] " >> /etc/krb5.conf &>> $LOG
	echo "  default = FILE:/var/log/krb5libs.log " >> /etc/krb5.conf &>> $LOG
	echo "  kdc = FILE:/var/krb5/krb5kdc.log " >> /etc/krb5.conf &>> $LOG
	echo "  admin_server = FILE:/var/log/krb5admin.log" >> /etc/krb5.conf &>> $LOG
	echo -e "Kerberos .........................................[ OK ]"
sleep 1
