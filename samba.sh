#!/bin/bash

#	Autor: Levi Barroso Menezes
#	Data de criação: 24/03/2019
#	Versão: 0.03
#	Samba4

#	Variável do servidor:
	NOME="smb001"
	DOMINIO="thz.intra"
	ZONA="America/Fortaleza"
	FQDN="$NOME.$DOMINIO"

#	Variáveis de Rede
	INTERFACE="enp0s3"
	DHCPv4="true"
	IPv4="172.20.0.10"
	MASCARAv4="/16"
	GATEWAYv4="172.20.0.1"
	DHCPv6="true"
	IPv6=""
	MASCARAv6=""
	GATEWAYv6=""
	DNS0="172.20.0.10"
	DNS1="4.4.8.8"
	DNS2="8.8.4.4"
	DNS3="8.8.8.8"

#	variáveis do script
	HORAINICIAL=`date +%T`
	LOG="/var/log/$(echo $0 | cut -d'/' -f2)"

#	Variáveis do Samba
	USUARIO="Supremo"
	SENHA="ASD!@#456"
	REINO="THZ.INTRA"
	DNSBE="SAMBA_INTERNAL"
	REGRA="dc"
	LEVEL="2008_R2"
	SMBDOMINIO="thz"
	DNSENCAMINHADO="8.8.8.8"

#	Variaáveis do DNS
	ARPA="20.172.in-addr.arpa"
	ARPAIP="10.0"

#	Exportando o recurso de Noninteractive:
	export DEBIAN_FRONTEND="noninteractive"

#	Registrar inicio dos processos:
	echo -e "Início do script $0 em: `date +%d/%m/%Y-"("%H:%M")"`\n" &>> $LOG

#	Padronização:
	bash base.sh
	
#	Auterar nome do servidor (HOSTNAME):
	printf "$NOME" > /etc/hostname
	printf "
#IP versão 4
127.0.0.1		localhost.localdomain	localhosta
$IPv4			$FQDN	$NOME

#IP versão 6
::1			localhost	ip6-localhost	ip6-loopback
fe00::0		ip6-localnet
ff02::1		ip6-allnodes
ff02::2		ip6-allrouters
ff02::3		ip6-allhosts
$IPv6		$FQDN	$NOME

#	" > /etc/hosts
	echo -e "[ \033[0;32m OK \033[0m ] Nome do servidor ..."
	sleep 1

#	Configurar interfaces de rede:
	mv /etc/netplan/01-netcfg.yaml /etc/netplan/01-netcfg.yaml.bkp
	printf "
network:
    version: 2
    renderer: networkd
    ethernets:
        $INTERFACE:
            dhcp4: $DHCPv4
            dhcp6: $DHCPv6
            addresses: [$IPv4$MASCARAv4, $IPv6$MASCARAv6]
            gateway4: $GATEWAYv4
            nameservers:
                addresses: [$DNS0, $DNS1, $DNS2, $DNS3]
                search: [$DOMINIO]
#	" > /etc/netplan/01-netcfg.yaml
	netplan --debug apply &>> $LOG
	echo -e "[ \033[0;32m OK \033[0m ] Configurações de rede ..."
	sleep 1

#	Instalar Python
	apt -y -q install python-all-dev python-dev python-crypto python-dbg python-dev python-dnspython \
	python3-dnspython python-gpgme python3-gpgme python-markdown python3-markdown \
	python3-dev
	echo -e "[ \033[0;32m OK \033[0m ] Python ..."
	sleep 1

#	Instalar Perl
	apt -y -q install perl perl-modules 
	echo -e "[ \033[0;32m OK \033[0m ] Perl ..."
	sleep 1

#	Instalar Utilitários
	apt -y -q install acl attr autoconf bind9utils bison \
	build-essential	debhelper dnsutils docbook-xml docbook-xsl \
	cifs-utils traceroute winbind ldb-tools unzip \
	flex gdb xsltproc debconf-utils figlet \
	kcc tree
	echo -e "[ \033[0;32m OK \033[0m ] Utilitários ..."
	sleep 1

#	Instalar Bibliotecas:	
	apt -y -q install libacl1-dev libaio-dev libarchive-dev libattr1-dev libblkid-dev \
	libparse-yapp-perl libdap2-dev libncurses5-dev libgnutls28-dev libpam-winbind \
	libgpgme-dev libjson-perl libpam0g-dev libnss-winbind libldap2-dev \
	libbsd-dev libjansson-dev libcap-dev libcups2-dev lmdb-utils \
	libpopt-dev libreadline-dev liblmdb-dev nettle-dev pkg-config \
	zlib1g-dev \
	echo -e "[ \033[0;32m OK \033[0m ] Bibliotécas ..."
	sleep 1

#	Instalar e configurar kerberos:
	echo "krb5-config krb5-config/default_realm string $REINO" | debconf-set-selections
	echo "krb5-config krb5-config/kerberos_servers string $FQDN" | debconf-set-selections
	echo "krb5-config krb5-config/admin_server string $FQDN" | debconf-set-selections
	echo "krb5-config krb5-config/add_servers_realm string $REINO" | debconf-set-selections
	echo "krb5-config krb5-config/add_servers boolean true" | debconf-set-selections
	echo "krb5-config krb5-config/read_config boolean true" | debconf-set-selections
	debconf-show krb5-config &>> $LOG
	apt -y -q install krb5-user krb5-config &>> $LOG
	echo -e "[ \033[0;32m OK \033[0m ] Kerberos ..."

#	Configurar kerberos:
	printf "
[libdefaults]
	# Realm padrão
	default_realm = $REINO
 
#	Opções utilizadas pela SAMBA4
	dns_lookup_realm = false
	dns_lookup_kdc = true
 
#	Confguração padrão do Kerneros
	krb4_config = /etc/krb.conf
	krb4_realms = /etc/krb.realms
	kdc_timesync = 1
	ccache_type = 4
	forwardable = true
	proxiable = true
	v4_instance_resolve = false
	v4_name_convert = {
		host = {
			rcmd = host
			ftp = ftp
		}
		plain = {
			something = something-else
		}
	}
	fcc-mit-ticketflags = true
 
#	Reino padrão
[realms]
	$REINO = {
		# Servidor de geração de KDC
		kdc = $FQDN
		#
		# Servidor de Administração do KDC
		admin_server = $FQDN
		#
		# Domínio padrão
		default_domain = $DOMINIO
	}
 
#	Domínio Realm
[domain_realm]
	.$DOMINIO = $REINO
	$DOMINIO = $REINO
 
#	Geração do Tickets
[login]
	krb4_convert = true
	krb4_get_tickets = false
 
#	Log dos tickets do Kerberos
[logging] 
	default = FILE:/var/log/krb5libs.log 
	kdc = FILE:/var/krb5/krb5kdc.log 
	admin_server = FILE:/var/log/krb5admin.log
	" > /etc/krb5.conf
	echo -e "[ \033[0;32m OK \033[0m ] Configuração kerberos ..."
	sleep 1

#	Configurar ponte nsswitch:
	mv -v /etc/nsswitch.conf /etc/nsswitch.conf.bkp &>> $LOG
	printf "
#	Habilitar os recursos de files (arquivos) e winbind (integração) SAMBA+GNU/Linux
passwd:         files compat systemd winbind
group:          files compat systemd winbind
shadow:         files compat systemd winbind
gshadow:        files
passwd_compat:	nis
group_compat:	nis
shadow_compat:	nis


#	Configuração de resolução de nomes
#	Habilitar o recursos de dns depois de files (arquivo hosts)
hosts:          nis [NOTFOUND=return] files dns dns mdns4_minimal [NOTFOUND=return]

#	Configurações padrão.
services:   	nis [NOTFOUND=return] files
networks:   	nis [NOTFOUND=return] files
protocols:  	nis [NOTFOUND=return] files
rpc:        	nis [NOTFOUND=return] files
ethers:     	nis [NOTFOUND=return] files
netmasks:   	nis [NOTFOUND=return] files
netgroup:   	nis
bootparams: 	nis [NOTFOUND=return] files
publickey:  	nis [NOTFOUND=return] files
automount:  	files
aliases:    	nis [NOTFOUND=return] files
	" > /etc/nsswitch.conf
	echo -e "[ \033[0;32m OK \033[0m ] Nsswitch ..."
	sleep 1

#	Instalar SAMBA4:
	apt -y install samba samba-common smbclient samba-vfs-modules samba-testsuite samba-dsdb-modules &>> $LOG
	echo -e "[ \033[0;32m OK \033[0m ] Samba4 ..."
	sleep 1

#	Provisionar controlador de domínio do active directory:
	systemctl stop samba-ad-dc.service smbd.service nmbd.service &>> $LOG
	mv -v /etc/samba/smb.conf /etc/samba/smb.conf.bkp &>> $LOG
	samba-tool domain provision \
	--realm=$REINO \
	--domain=$SMBDOMINIO \
	--server-role=$REGRA \
	--option="dns forwarder = $DNSENCAMINHADO"
	--dns-backend=$DNSBE \
	--use-rfc2307 \
	--adminpass=$SENHA \
	--function-level=$LEVEL \
	--site=$REINO \
#	--host-ip=$IP \
#	--option="interfaces = lo $INTERFACE" \
#	--option="bind interfaces only = yes" 
#	--option="allow dns updates = nonsecure and secure" \
#	--option="winbind use default domain = yes" \
#	--option="winbind enum users = yes" \
#	--option="winbind enum groups = yes" \
#	--option="winbind refresh tickets = yes" \
#	--option="server signing = auto" \
#	--option="vfs objects = acl_xattr" \
#	--option="map acl inherit = yes" \
#	--option="store dos attributes = yes" \
#	--option="client use spnego = no" \
#	--option="use spnego = no" \
#	--option="client use spnego principal = no" &>> $LOG
	echo -e "[ \033[0;32m OK \033[0m ] Provisionamento do controlador de domínio do active directory ..."
	
#	Configurar SAMBA4:
	systemctl enable samba-ad-dc.service &>> $LOG
	systemctl restart samba-ad-dc.service &>> $
#	systemctl disable nmbd.service smbd.service winbind.service &>> $LOG
#	systemctl mask nmbd.service smbd.service winbind.service &>> $LOG
#	systemctl unmask samba-ad-dc.service &>> $LOG
	net rpc rights grant '$SMBDOMINIO\Domain Admins' SeDiskOperatorPrivilege -U Administrator%$SENHA &>> $LOG
	samba-tool user setexpiry Administrator --noexpiry &>> $LOG
	samba-tool dns zonecreate $DOMINIO $ARPA -U Administrator --password=$SENHA &>> $LOG
	samba-tool dns add $DOMINIO $ARPA $ARPAIP PTR $FQDN -U Administrator --password=$SENHA &>> $LOG
	samba_dnsupdate --use-file=/var/lib/samba/private/dns.keytab --verbose --all-names &>> $LOG
	echo -e "[ \033[0;32m OK \033[0m ] Provisionamento do Controlador de Domínio ..."
	sleep 1

#	Finalizar
	HORAFINAL=$(date +%T)
	HORAINICIAL01=$(date -u -d "$HORAINICIAL" +"%s")
	HORAFINAL01=$(date -u -d "$HORAFINAL" +"%s")
	TEMPO=$(date -u -d "0 $HORAFINAL01 sec - $HORAINICIAL01 sec" +"%H:%M:%S")
	echo -e "Tempo de execução $0: $TEMPO"
	echo -e "Fim do script $0 em: `date +%d/%m/%Y-"("%H:%M")"`\n" &>> $LOG
	echo -e "Acesso ao banco de dados: $IP:5432"
	echo -e "\033[0;31m Pode ser nescesario reiniciar o servidor !!! \033[0m"
	echo -e "Pressione \033[0;32m <Enter> \033[0m para reiniciar ou \033[0;33m <CTRL> + C \033[0m para finalizar o processo."
	read
	reboot 0
exit 1
