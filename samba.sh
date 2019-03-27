#!/bin/bash

#	Autor: Levi Barroso Menezes
#	Data de criação: 26/03/2019
#	Versão: 0.08
#	Samba
	
#	Variável do servidor:
	NOME="smb01"
	DOMINIO="thz.intra"
	ZONA="America/Fortaleza"
	FQDN="$NOME.$DOMINIO"

#	Variáveis de Rede
	INTERFACE0="enp0s3"
	DHCP0v4="false"
	IP0v4="172.20.0.10"
	MASCARA0v4="/16"
	GATEWAY0v4="172.20.0.1"
	DHCP0v6="true"
	INTERFACE1="enp0s8"
	DHCP1v4="false"
	IP1v4="10.0.0.17"
	MASCARA1v4="/8"
	GATEWAY1v4="10.10.0.1"
	DHCP1v6="true"
	DNSEX0="8.8.8.8"
	DNSEX1="4.4.8.8"

#	variáveis do script
	HORAINICIAL=`date +%T`
	LOG="/var/log/$(echo $0 | cut -d'/' -f2)"

#	Variáveis do Samba
	USUARIO="Supremo"
	SENHA="P@ssword"
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

#	Configurar interfaces de rede:
	mv /etc/netplan/01-netcfg.yaml /etc/netplan/01-netcfg.yaml.bkp &>> $LOG
	printf "
network:
    version: 2
    renderer: networkd
    ethernets:
        $INTERFACE0:
            dhcp4: $DHCP0v4
            dhcp6: $DHCP0v6
            addresses: [$IP0v4$MASCARA0v4]
            gateway4: $GATEWAY0v4
            nameservers:
                addresses: [$IP0v4, $DNSEX0, $DNSEX1]
                search: [$DOMINIO]
        $INTERFACE1:
            dhcp4: $DHCP1v4
            dhcp6: $DHCP1v6
            addresses: [$IP1v4$MASCARA1v4]
            gateway4: $GATEWAY1v4
            nameservers:
                addresses: [$IP1v4, $DNSEX0, $DNSEX1]
                search: [$DOMINIO]
#	" > /etc/netplan/01-netcfg.yaml
	netplan --debug apply &>> $LOG
	echo -e "[ \033[0;32m OK \033[0m ] Configurações de rede ..."
	sleep 1

#	Auterar nome do servidor (hostname):
	rm /etc/hostname
	printf "$NOME" > /etc/hostname
	echo -e "[ \033[0;32m OK \033[0m ] Nome do servidor ..."
	sleep 1
	
#	Auterar resolução de nome interna (hosts):
	rm /etc/hosts
	printf "
#IP versão 4
127.0.0.1		localhost.localdomain	localhosta
127.0.0.1		$FQDN	$NOME
$IP0v4			$FQDN	$NOME

#IP versão 6
::1				localhost	ip6-localhost	ip6-loopback
fe00::0			ip6-localnet
ff02::1			ip6-allnodes
ff02::2			ip6-allrouters
ff02::3			ip6-allhosts
$IP0v6			$FQDN	$NOME

#	" > /etc/hosts
	echo -e "[ \033[0;32m OK \033[0m ] Resolução de nome interna ..."
	sleep 1
	
#	Auterar resolução de nomes externa (resolv.conf):
	rm /etc/resolv.conf
	printf "
nameserver 127.0.0.53
nameserver $IP0v4
nameserver $DNSEX0
nameserver $DNSEX1
search thz.intra
#	" > /etc/resolv.conf
	echo -e "[ \033[0;32m OK \033[0m ] Resolução de nome externa ..."
	sleep 1

#	Padronização:
	bash base.sh

#	Instalar python
	apt -y -q install python-all-dev python-crypto python-dbg python-dev python-dnspython python3-dnspython python-gpg e python3-gpg python-markdown python3-markdown python3-dev &>> $LOG
	echo -e "[ \033[0;32m OK \033[0m ] Python ..."
	sleep 1

#	Instalar perl
	apt -y -q install perl perl-modules pkg-config libparse-yapp-perl libjson-perl &>> $LOG
	echo -e "[ \033[0;32m OK \033[0m ] Perl ..."
	sleep 1

#	Instalar recursos usados pelo samba
	apt -y -q install acl attr autoconf bind9utils bison build-essential debhelper dnsutils docbook-xml docbook-xsl flex gdb xsltproc lmdb-utils libjansson-dev &>> $LOG
	echo -e "[ \033[0;32m OK \033[0m ] Recursos usados pelo samba ..."
	sleep 1

#	Instalar bibliotecas:	
	apt -y -q install libsystemd-dev libacl1-dev libaio-dev libarchive-dev libattr1-dev libcap-dev libcups2-dev libgnutls28-dev libgpgme-dev zlib1g-dev liblmdb-dev libldap2-dev libncurses5-dev libpam0g-dev libpopt-dev libreadline-dev nettle-dev libblkid-dev libbsd-dev &>> $LOG
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
	sleep 1

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
	apt -y -q install samba samba-common smbclient samba-vfs-modules samba-testsuite samba-dsdb-modules &>> $LOG
	echo -e "[ \033[0;32m OK \033[0m ] Samba4 ..."
	sleep 1

#	Provisionar controlador de domínio do active directory:
	systemctl stop samba-ad-dc.service smbd.service nmbd.service &>> $LOG
	mv -v /etc/samba/smb.conf /etc/samba/smb.conf.bkp &>> $LOG
	samba-tool domain provision --realm=$REINO --domain=$SMBDOMINIO --server-role=$REGRA --option="dns forwarder = $DNSEX0" --dns-backend=$DNSBE --use-rfc2307 --adminpass=$SENHA --function-level=$LEVEL --site=$REINO --host-ip=$IP --option="interfaces = lo $INTERFACE" --option="bind interfaces only = yes" --option="allow dns updates = nonsecure and secure" --option="winbind use default domain = yes" --option="winbind enum users = yes" --option="winbind enum groups = yes" --option="winbind refresh tickets = yes" --option="server signing = auto" --option="vfs objects = acl_xattr" --option="map acl inherit = yes" --option="store dos attributes = yes" --option="client use spnego = no" --option="use spnego = no" --option="client use spnego principal = no" &>> $LOG
	echo -e "[ \033[0;32m OK \033[0m ] Provisionamento do controlador de domínio ..."
	
#	Configurar SAMBA4:
	systemctl unmask samba-ad-dc.service &>> $LOG
	systemctl enable samba-ad-dc.service smbd.service nmbd.service &>> $LOG
	systemctl restart samba-ad-dc.service smbd.service nmbd.service &>> $LOG
	systemctl disable nmbd.service smbd.service winbind.service &>> $LOG
	systemctl mask nmbd.service smbd.service winbind.service &>> $LOG
	net rpc rights grant '$SMBDOMINIO\Domain Admins' SeDiskOperatorPrivilege -U $USUARIO%$SENHA &>> $LOG
	samba-tool user setexpiry $USUARIO --noexpiry &>> $LOG
	samba-tool dns zonecreate $DOMINIO $ARPA -U $USUARIO --password=$SENHA &>> $LOG
	samba-tool dns add $DOMINIO $ARPA $ARPAIP PTR $FQDN -U $USUARIO --password=$SENHA &>> $LOG
	samba_dnsupdate --use-file=/var/lib/samba/private/dns.keytab --verbose --all-names &>> $LOG
	echo -e "[ \033[0;32m OK \033[0m ] Configuração do Controlador de Domínio ..."
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
