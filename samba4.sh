#!/bin/bash
# Autor: Levi Barroso Menezes
# Data de criação: 08/03/2019
# Versão: 0.01
# Ubuntu Server 18.04.x LTS x64
# Kernel Linux 4.15.x
# SAMBA-4.7.x ( WHOIS-TCP:43 / DNS-TCP,UDP:53 / WINS-TCP,UDP:42 ) 
# KERBEROS () 
# NTP (UDP:123)

##### Variaveis #####

#Variável pra calcular tempo
HORAINICIAL=`date +%T`

#Variavel de validação
USUARIO=`id -u`
UBUNTU=`lsb_release -rs`
KERNEL=`uname -r | cut -d'.' -f1,2`

#Variável de LOG
LOG="/var/log/$(echo $0 | cut -d'/' -f2)"

#Variável do SISTEMA:
HOSTNAME="addc-001"

# Variáveis de configuração do KERBEROS:
REALM="THZ.INTRA"
NETBIOS="THZ"
DOMAIN="thz.intra"
FQDN="addc-001.thz.intra"
IP="172.20.0.10"

# Variáveis de configuração do NTP:
NTP="a.st1.ntp.br"

# Variáveis de configuração do SAMBA4:
ROLE="dc"
DNS="SAMBA_INTERNAL"
USER="administrator"
PASSWORD="P@ssw0rd"
LEVEL="2008_R2"
SITE="THZ.INTRA"
INTERFACE="enp0s3"
FORWARDER="172.20.0.1"

# Variáveis de configuração do DNS:
ARPA="20.172.in-addr.arpa"
ARPAIP="20"

# Exportando o recurso de Noninteractive:
export DEBIAN_FRONTEND="noninteractive"
clear

#Verificar permissões de usuário:
if [ "$USUARIO" == "0" ]
	then
		echo -e "Permissão compatível .........................[ OK ]"
	else
		echo -e "O script deve ser executado como root ........[ ER ]"
		exit 1
fi

#Verificar versão da distribuição:
if [ "$UBUNTU" == "18.04" ]
	then
		echo -e "Versão da distribuição compatível ............[ OK ]"
	else
		echo -e "A distribuição deve ser 18.04 ................[ ER ]"
		exit 1
fi

#Verificar versão do kernel:
if [ "$KERNEL" == "4.15" ]
	then
		echo -e "O Kernel compatível ..........................[ OK ]"
	else
		echo -e "O Kernel deve ser 4.15 ou superior ...........[ ER ]"
		exit 1
fi
sleep 5

#Registrar inicio dos processos:
	echo -e "Início do script $0 em: `date +%d/%m/%Y-"("%H:%M")"`\n" &>> $LOG

#Adicionar o Repositório Universal:	
	add-apt-repository universe &>> $LOG
	echo -e "Repositório universal ............................[ OK ]"
sleep 5

#Adicionar o Repositório Multiversão:	
	add-apt-repository multiverse &>> $LOG
	echo -e "Repositório multiversão ..........................[ OK ]"
sleep 5

#Atualizar lista de repositórios:	
	apt update &>> $LOG
	echo -e "Lista de repositórios ............................[ OK ]"
sleep 5

#Atualizar sistema:	
	apt -y upgrade &>> $LOG
	echo -e "Atualização do sistema ...........................[ OK ]"
sleep 5

#Remover pacotes desnecessários:	
	apt -y autoremove &>> $LOG
	echo -e "Remoção de pacodes desnecessários ................[ OK ]"
sleep 5

#Instalar dependencias:	
	apt -y install ntp ntpdate build-essential libacl1-dev libattr1-dev libblkid-dev libgnutls28-dev libreadline-dev \
	python-dev libpam0g-dev python-dnspython gdb pkg-config libpopt-dev libldap2-dev dnsutils libbsd-dev docbook-xsl acl \
	attr debconf-utils figlet &>> $LOG
	echo -e "Dependências .....................................[ OK ]"
sleep 5

#Instalar e configurar KERBEROS:	
	echo "krb5-config krb5-config/default_realm string $REALM" | debconf-set-selections
	echo "krb5-config krb5-config/kerberos_servers string $FQDN" | debconf-set-selections
	echo "krb5-config krb5-config/admin_server string $FQDN" | debconf-set-selections
	echo "krb5-config krb5-config/add_servers_realm string $REALM" | debconf-set-selections
	echo "krb5-config krb5-config/add_servers boolean true" | debconf-set-selections
	echo "krb5-config krb5-config/read_config boolean true" | debconf-set-selections
	debconf-show krb5-config &>> $LOG
	apt -y install krb5-user krb5-config &>> $LOG
	mv -v /etc/krb5.conf /etc/krb5.conf.bkp &>> $LOG
	cp -v conf/krb5.conf /etc/krb5.conf &>> $LOG
	nano /etc/krb5.conf ########## 
	echo -e "Kerberos .........................................[ OK ]"
sleep 5

#Configurar NTP:
	mv -v /etc/ntp.conf /etc/ntp.conf.bkp &>> $LOG
	cp -v conf/ntp.drift /var/lib/ntp/ntp.drift &>> $LOG
	chown -v ntp.ntp /var/lib/ntp/ntp.drift &>> $LOG
	cp -v conf/ntp.conf /etc/ntp.conf &>> $LOG
	systemctl stop ntp.service &>> $LOG
	timedatectl set-timezone "America/Fortaleza" &>> $LOG
	nano /etc/ntp.conf ########## 
	ntpdate -dquv $NTP &>> $LOG
	systemctl start ntp.service &>> $LOG
	ntpq -pn &>> $LOG
	hwclock --systohc &>> $LOG
	echo -e "Data/Hora de hardware: `hwclock`\n"
	echo -e "Data/Hora de software: `date`\n"
	echo -e "NTP ..............................................[ OK ]"
sleep 5

#Configurar sistema de arquivos (FSTAB):
	cp -v /etc/fstab /etc/fstab.bkp &>> $LOG
	nano /etc/fstab ########## 
	mount -o remount,rw /dev/sda2 &>> $LOG
	echo -e "Sistema de aquivos ...............................[ OK ]"
sleep 5

#Auterar nome do servidor (HOSTNAME):
	cp -v /etc/hostname /etc/hostname.bkp &>> $LOG
	# $HOSTNAME > /etc/hostname &>> $LOG
	nano /etc/hostname ########## 
	echo -e "Nome do servidor (hostname) ......................[ OK ]"
sleep 5
	
#Configurar resolução de nomes local (HOSTS):
	cp -v /etc/hosts /etc/hosts.bkp &>> $LOG
	$HOSTNAME > /etc/hosts &>> $LOG
	nano /etc/hosts ########## 
	echo -e "Resolução local de nomes (hosts) .................[ OK ]"
sleep 5
	
#Configurar ponte NS (NSSWITCH):
	mv -v /etc/nsswitch.conf /etc/nsswitch.conf.bkp &>> $LOG
	cp -v conf/nsswitch.conf /etc/nsswitch.conf &>> $LOG
	nano /etc/nsswitch.conf ########## 
	echo -e "Ponte NS .........................................[ OK ]"
sleep 5
	
#Instalar SAMBA4:
	apt -y install samba samba-common smbclient cifs-utils samba-vfs-modules samba-testsuite samba-dsdb-modules \
	winbind ldb-tools libnss-winbind libpam-winbind unzip kcc tree &>> $LOG
	echo -e "Samba4 ...........................................[ OK ]"
sleep 5

#Configurar interfaces de rede:
	sleep 3
	nano /etc/netplan/50-cloud-init.yaml ########## 
	netplan --debug apply &>> $LOG
	echo -e "Interface de Rede .................................[ OK ]"
sleep 5
	
#Promovendo Controlador de Domínio do Active Directory:
	systemctl stop samba-ad-dc.service smbd.service nmbd.service &>> $LOG
	mv -v /etc/samba/smb.conf /etc/samba/smb.conf.bkp &>> $LOG
	samba-tool domain provision --realm=$REALM --domain=$NETBIOS --server-role=$ROLE --dns-backend=$DNS --use-rfc2307 \
	--adminpass=$PASSWORD --function-level=$LEVEL --site=$SITE --host-ip=$IP --option="interfaces = lo $INTERFACE" \
	--option="bind interfaces only = yes" --option="allow dns updates = nonsecure and secure" \
	--option="dns forwarder = $FORWARDER" --option="winbind use default domain = yes" --option="winbind enum users = yes" \
	--option="winbind enum groups = yes" --option="winbind refresh tickets = yes" --option="server signing = auto" \
	--option="vfs objects = acl_xattr" --option="map acl inherit = yes" --option="store dos attributes = yes" \
	--option="client use spnego = no" --option="use spnego = no" --option="client use spnego principal = no" &>> $LOG
	samba-tool user setexpiry $USER --noexpiry &>> $LOG
	systemctl disable nmbd.service smbd.service winbind.service &>> $LOG
	systemctl mask nmbd.service smbd.service winbind.service &>> $LOG
	systemctl unmask samba-ad-dc.service &>> $LOG
	systemctl enable samba-ad-dc.service &>> $LOG
	systemctl start samba-ad-dc.service &>> $LOG
	net rpc rights grant 'PTI\Domain Admins' SeDiskOperatorPrivilege -U $USER%$PASSWORD &>> $LOG
	samba-tool dns zonecreate $DOMAIN $ARPA -U $USER --password=$PASSWORD &>> $LOG
	samba-tool dns add $DOMAIN $ARPA $ARPAIP PTR $FQDN -U $USER --password=$PASSWORD &>> $LOG
	samba_dnsupdate --use-file=/var/lib/samba/private/dns.keytab --verbose --all-names &>> $LOG
	echo -e "Controlador de Domínio do Active Directory .........[ OK ]"
sleep 5
	
HORAFINAL=`date +%T`
HORAINICIAL01=$(date -u -d "$HORAINICIAL" +"%s")
HORAFINAL01=$(date -u -d "$HORAFINAL" +"%s")
TEMPO=`date -u -d "0 $HORAFINAL01 sec - $HORAINICIAL01 sec" +"%H:%M:%S"`
echo -e "Tempo de execução do script $0: $TEMPO"
echo -e "Fim do script $0 em: `date +%d/%m/%Y-"("%H:%M")"`\n" &>> $LOG
exit 1