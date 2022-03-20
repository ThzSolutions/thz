#!/bin/bash

#	Autor: Levi Barroso Menezes
#	Data de criação: 20/03/2022
#	Versão: 0.12
#	Samba4

export DEBIAN_FRONTEND="noninteractive"

#	Script:
	USER='id -u' 
	UBUNTU='lsb_release -rs' 
	KERNEL='uname -r | corte -d'.' -f1,2' 
	BASELOG="/var/log/base.sh"
	HORAINICIAL='data +%T' 
	LOG="/var/log/addc.sh.log"	

#	Servidor: 
	NOME='addc-00' 
	DOMINIO="thz.intra"
	FQDN="$NOME.$DOMINIO"

#	Rede:
	INTERFACE0="enp0s3"
	DHCP0v4="false" 
	IP0v4="172.20.0.10"
	RÍMEL0v4="/16" 
	GATEWAY0v4="172.20.0.1"
	DHCP0v6="true" 
	DNSEX0="8.8.8.8"
	DNSEX1="4.4.8.8"
	DNSEX2="208.67.222.222"
	DNSEX3="208.67.222.220"
	
#	NTP:
	SERVIDORNTP0=$GATEWAY0v4
	SERVIDORNTP1="a.ntp.br"
	SERVIDORNTP2="b.ntp.br"
	ZONA="América/Fortaleza" 
	
#	Samba:
	USUARIO="Supremo"
	SENHA="P@ssword"
	REINO="THZ.INTRA" 
	DNSBE="SAMBA_INTERNAL"
	REGRA="dc"
	LEVEL="2008_R2"
	SMBDOMINIO="THZ"
	DNSENCAMINHADO="8.8.8.8"

#	DNS:
	ARPA="20.172.in-addr.arpa"
	ARPAIP="4.0"
	ZONANOME='smb01' 
	ZONADOMINIO='thz.intra'
	ZONAFQDN='"$NOME.$DOMINIO"'
	ZONADIRFILE='"/etc/bind/db.thz.intra"'
	ZONAREVFILE='"/etc/bind/db.20.172.in-addr.arpa"'
	ZONAARPA='"20.172.in-addr.arpa"'

if [ "$USER" == "0" ]
	then
		echo -e "[ \033[0;32m OK \033[0m ] Permissão concedida ..."
	else
		echo -e "[ \033[0;31m ER \033[0m ] Premissões negadas ($USER) ..."
		echo -e "\033[0;33m Pressione <ENTER> se quiser continuar ou <CTRL> + C para sair.\033[0m"
		read
fi

#	Verificar versão da distribuição:
if [ "$UBUNTU" == "18.04" ]
	then
		echo -e "[ \033[0;32m OK \033[0m ] Distribuição compatível ..."
	else
		echo -e "[ \033[0;31m ER \033[0m ] Distribuição não homologada ($UBUNTU) ..."
		echo -e "\033[0;33m Pressione <ENTER> se quiser continuar ou <CTRL> + C para sair.\033[0m"
		read
fi

#	Verificar versão do kernel:
if [ "$KERNEL" == "4.15" ]
	then
		echo -e "[ \033[0;32m OK \033[0m ] Kernel homologado ..."
	else
		echo -e "[ \033[0;31m ER \033[0m ] Kernel não homologado ($KERNEL) ..."
		echo -e "\033[0;33m Pressione <ENTER> se quiser continuar ou <CTRL> + C para sair.\033[0m"
		read
fi

#	Verificar conexão com a internet:
       ping -q -c1 -w1 br.archive.ubuntu.com > /dev/null
       if [ $? == 0 ]
	       then
       		echo -e "[ \033[0;32m OK \033[0m ] Internet ..."
       	else
		       echo -e "[ \033[0;31m ER \033[0m ] Sem conexão com a internet ..."
		       echo -e "\033[0;33m Pressione <ENTER> se quiser continuar ou <CTRL> + C para sair.\033[0m"
		       read
       fi

#	Configurar interfaces de rede (netplan):
       rm -r /etc/netplan/*
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
                     addresses: [$IP0v4, $DNSEX0, $DNSEX1, $DNSEX2, $DNSEX3]
                     search: [$DOMINIO]
       " > /etc/netplan/00-netcfg.yaml
       netplan --debug apply &>> $LOG
       echo -e "[ \033[0;32m OK \033[0m ] Configurações de rede ..."

#	Auterar nome do servidor (hostname):
       printf "$NOME" > /etc/hostname
       echo -e "[ \033[0;32m OK \033[0m ] Nome do servidor ..."

#	Auterar resolução de nome interna (hosts):
       printf "
       #IP versão 4
       $IP0v4			$FQDN	$NOME
       #127.0.1.1		$FQDN	$NOME
       127.0.0.1		localhost.localdomain	localhost

       #IP versão 6
       $IP0v6			$FQDN	$NOME
       fe00::0			ip6-localnet
       ff02::1			ip6-allnodes
       ff02::2			ip6-allrouters
       ff02::3			ip6-allhosts
       ::1				localhost	ip6-localhost	ip6-loopback
       " > /etc/hosts
       echo -e "[ \033[0;32m OK \033[0m ] Resolução de nome interna ..."

#	Auterar resolução de nomes externa (resolv.conf):
       printf "
       nameserver $IP0v4
       nameserver $DNSEX0
       nameserver $DNSEX1
       nameserver $DNSEX2
       nameserver $DNSEX3
       search $DOMINIO
       domain $DOMINIO" > /etc/resolv.conf
       echo -e "[ \033[0;32m OK \033[0m ] Resolução de nome externa ..."

#	Configurar ponte nsswitch:
       mv /etc/nsswitch.conf /etc/nsswitch.conf.bkp
       printf "
       #	Habilitar os recursos de files (arquivos) e winbind (integração) SAMBA+GNU/Linux
       passwd:              files compat systemd winbind
       group:               files compat systemd winbind
       shadow:              files compat systemd winbind
       gshadow:             files
       passwd_compat:	nis
       group_compat:	       nis
       shadow_compat:	nis
       
       #	Configuração de resolução de nomes
       #	Habilitar o recursos de dns depois de files (arquivo hosts)
       hosts:               nis files dns mdns4_minimal [NOTFOUND=return]
       networks:   	       file

       #	Configurações padrão.
       services:   	nis files db [NOTFOUND=return]
       networks:   	nis files db [NOTFOUND=return]
       protocols:  	nis files db [NOTFOUND=return]
       rpc:        	nis files db [NOTFOUND=return]
       ethers:     	nis files db [NOTFOUND=return]
       netmasks:   	nis files db [NOTFOUND=return]
       netgroup:   	nis files db [NOTFOUND=return]
       bootparams: 	nis files db [NOTFOUND=return]
       publickey:  	nis files db [NOTFOUND=return]
       automount:  	files
       aliases:    	nis files [NOTFOUND=return]
       " > /etc/nsswitch.conf
       echo -e "[ \033[0;32m OK \033[0m ] Nsswitch ..."

#	Adicionar o repositório universal:	
       add-apt-repository universe &>> $LOG
       echo -e "[ \033[0;32m OK \033[0m ] Repositório universal ..."

#	Adicionar o repositório multiversão:	
       add-apt-repository multiverse &>> $LOG
       echo -e "[ \033[0;32m OK \033[0m ] Repositório multiversão ..."

#	Atualizar lista de repositórios:	
       apt -y -q update &>> $LOG
       echo -e "[ \033[0;32m OK \033[0m ] Atualização de repositórios ..."

#	Atualizar sistema:	
       apt -y -q upgrade &>> $LOG
       echo -e "[ \033[0;32m OK \033[0m ] Atualização do sistema ..."

#	Remover pacotes desnecessários:	
       apt -y -q autoremove &>> $LOG
       echo -e "[ \033[0;32m OK \033[0m ] Remoção de pacodes desnecessários ..."

#	Adicionar programas basicos do sistema
	apt -y -q install software-properties-common &>> $LOG
	echo -e "[ \033[0;32m OK \033[0m ] Programas basicos do sistema ..."
	sleep 1

#	Instalar curl:	
	apt -y -q install curl &>> $LOG
	echo -e "[ \033[0;32m OK \033[0m ] Curl ..."
	sleep 1

#	Instalar gnupg:	
	apt -y -q install gnupg gnupg1 gnupg2 &>> $LOG
	echo -e "[ \033[0;32m OK \033[0m ] Gnupg ..."
	sleep 1

#	Instalar traceroute:	
	apt -y -q install traceroute &>> $LOG
	echo -e "[ \033[0;32m OK \033[0m ] Traceroute ..."
	sleep 1
#	Instalar ssh:	
	apt -y -q install ssh &>> $LOG
	echo -e "[ \033[0;32m OK \033[0m ] SSH ..."
	sleep 1
	
#	Instalar htop:	
	apt -y -q install htop &>> $LOG
	echo -e "[ \033[0;32m OK \033[0m ] Htop ..."
	sleep 1

#	Instalar get:	
	apt -y -q install get &>> $LOG
	echo -e "[ \033[0;32m OK \033[0m ] Get ..."
	sleep 1
	
#	Instalar git:	
	apt -y -q install git &>> $LOG
	echo -e "[ \033[0;32m OK \033[0m ] Git ..."
	sleep 1
	
#	Instalar unzip:	
	apt -y -q unzip &>> $LOG
	echo -e "[ \033[0;32m OK \033[0m ] Unzip ..."
	sleep 1

#	Remover pacotes desnecessários:	
	apt -y -q autoremove &>> $LOG
	echo -e "[ \033[0;32m OK \033[0m ] Remoção de pacodes desnecessários ..."
	sleep 1

#	Instalar NTP:
	apt -y -q install ntp ntpdate &>> $LOG
	echo -e "[ \033[0;32m OK \033[0m ] NTP ..."
       sleep 1

#	Configurar NTP:
	printf "0.0" > /var/lib/ntp/ntp.drift
	chown ntp.ntp /var/lib/ntp/ntp.drift
	mv /etc/ntp.conf /etc/ntp.conf.bkp
	printf "
       driftfile /var/lib/ntp/ntp.drift

       #	Estatísticas do ntp que permitem verificar o histórico
       statsdir /var/log/ntpstats/
       statistics loopstats peerstats clockstats
       filegen loopstats file loopstats type day enable
       filegen peerstats file peerstats type day enable
       filegen clockstats file clockstats type day enable

       #	Servidores publicos ntp.br
       server a.st1.ntp.br iburst
       server b.st1.ntp.br iburst
       server c.st1.ntp.br iburst
       server d.st1.ntp.br iburst
       server gps.ntp.br iburst
       server @SERVIDORNTP0 iburst
       server @SERVIDORNTP1 iburst
       server @SERVIDORNTP2 iburst

       #	Configurações de restrição de acesso
       restrict 127.0.0.1
       restrict 127.0.1.1
       restrict ::1
       restrict default kod notrap nomodify nopeer noquery
       restrict -6 default kod notrap nomodify nopeer noquery
       " > /etc/ntp.conf
	timedatectl set-timezone "$ZONA" &>> $LOG
	chown root:ntp /var/lib/samba/ntp_signd/
	ntpdate -dquv $SERVIDORNTP0 &>> $LOG
	systemctl restart ntp.service &>> $LOG
	hwclock --systohc &>> $LOG
	echo -e "[ \033[0;32m OK \033[0m ] Configuração NTP ..."
	sleep 1

#	Instalar recursos usados pelo samba
	apt -y -q install acl attr autoconf debconf-utils figlet bison build-essential debhelper dnsutils docbook-xml docbook-xsl flex gdb xsltproc lmdb-utils pkg-config ldb-tools unzip kcc tree &>> $LOG
	echo -e "[ \033[0;32m OK \033[0m ] Recursos usados pelo samba ..."
	sleep 1

#	Instalar python
	apt -y -q install python-all-dev python-gpgme python-crypto python-m2crypto python-dbg python-dev python-dnspython python3-dnspython python-gpg e python3-gpg python-markdown python3-markdown python3-dev &>> $LOG
	echo -e "[ \033[0;32m OK \033[0m ] Python ..."
	sleep 1

#	Instalar perl
	apt -y -q install perl perl-modules libparse-yapp-perl libjson-perl &>> $LOG
	echo -e "[ \033[0;32m OK \033[0m ] Perl ..."
	sleep 1

#	Instalar bibliotecas:	
	apt -y -q install libsystemd-dev libacl1-dev libaio-dev libarchive-dev libattr1-dev libcap-dev libcups2-dev libgnutls28-dev libgpgme-dev zlib1g-dev liblmdb-dev libjansson-dev libldap2-dev libncurses5-dev libpam0g-dev libpopt-dev libreadline-dev nettle-dev libblkid-dev libbsd-dev libjansson-dev &>> $LOG
	echo -e "[ \033[0;32m OK \033[0m ] Bibliotécas ..."
	sleep 1

#	Instalar winbind
	apt -y -q install winbind libnss-winbind libpam-winbind &>> $LOG
	echo -e "[ \033[0;32m OK \033[0m ] Winbind ..."
	sleep 1

#	Instalar e configurar kerberos:
       apt -y -q install krb5-user krb5-kdc krb5-config &>> $LOG
       echo "krb5-config krb5-config/default_realm string $REINO" | debconf-set-selections
       echo "krb5-config krb5-config/kerberos_servers string $FQDN" | debconf-set-selections
       echo "krb5-config krb5-config/admin_server string $FQDN" | debconf-set-selections
       echo "krb5-config krb5-config/add_servers_realm string $REINO" | debconf-set-selections
       echo "krb5-config krb5-config/add_servers boolean true" | debconf-set-selections
       echo "krb5-config krb5-config/read_config boolean true" | debconf-set-selections
       debconf-show krb5-config &>> $LOG
       echo -e "[ \033[0;32m OK \033[0m ] Kerberos ..."
       sleep 1

#	Configurar kerberos:
       mv /etc/krb5.conf /etc/krb5.conf.bkp
       printf "
       [libdefaults]
       # 	Realm padrão
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
	fcc-mit       -ticketflags = true
       
              #	Reino padrão
       [realms]
       	$REINO = {
		       # Servidor de geração de KDC
		       kdc = $FQDN
		       # Servidor de Administração do KDC
		       admin_server = $FQDN
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
       	kdc = FILE:/var/log/krb5kdc.log 
       	admin_server = FILE:/var/log/krb5admin.log" > /etc/krb5.conf
       echo -e "[ \033[0;32m OK \033[0m ] Configuração kerberos ..."
       sleep 1

#	Instalar samba4:
	apt -y -q install samba samba-common smbclient samba-vfs-modules samba-testsuite samba-dsdb-modules &>> $LOG
	echo -e "[ \033[0;32m OK \033[0m ] Samba4 ..."
	sleep 1

#	Provisionar controlador de domínio do addc:
	systemctl stop samba-ad-dc.service smbd.service nmbd.service winbind.service &>> $LOG
	mv /etc/samba/smb.conf /etc/samba/smb.conf.old
	samba-tool domain provision --realm=$REINO --domain=$SMBDOMINIO --server-role=$REGRA --dns-backend=$DNSBE --option="dns forwarder = $DNSENCAMINHADO" --adminpass=$SENHA --function-level=$LEVEL --site=$REINO --host-ip=$IP0v4 --use-rfc2307 --option="server signing = auto" --option="client use spnego = no" --option="use spnego = no" --option="client use spnego principal = no" &>> $LOG
       echo -e "[ \033[0;32m OK \033[0m ] Provisionamento do controlador de domínio ..."
       sleep 1

#	Configurar samba4:
	mv /etc/samba/smb.conf /etc/samba/smb.bkp
	printf "
       # Global parameters
       [global]
              allow dns updates = nonsecure and secure
              bind interfaces only = Yes
              dns forwarder = $DNSENCAMINHADO
              interfaces = lo $INTERFACE0
              netbios name = $NOME
              realm = $REINO
              server role = active directory domain controller
              server signing = if_required
              winbind enum groups = Yes
              winbind enum users = Yes
              winbind refresh tickets = Yes
              winbind use default domain = Yes
              workgroup = $SMBDOMINIO
              idmap_ldb:use rfc2307 = yes
              map acl inherit = Yes
              store dos attributes = Yes
              vfs objects = acl_xattr
       [netlogon]
              path = /var/lib/samba/sysvol/thz.intra/scripts
              read only = No
       [sysvol]
              path = /var/lib/samba/sysvol
              read only = No
       [profiles]
		       path = /var/profiles
		       writeable = Yes
		       browseable = No
		       create mask = 0600
		       directory mask = 0700
       [impressoras]
		       comment = Todas as Impressoras
		       path = /var/spool/samba
		       guest ok = yes
		       public = yes
       		printable = yes
		       browseable = yes
		       use client driver = yes
       [arquivos]
		       path = /home/arquivos
		       available = yes
		       writable = no
       [publico]
		       path = /home/samba_publico
		       available = yes
		       browseable = yes
		       writable = yes
	" > /etc/samba/smb.conf
       systemctl unmask samba-ad-dc.service &>> $LOG
       systemctl enable samba-ad-dc.service &>> $LOG
       systemctl restart samba-ad-dc.service &>> $LOG
       systemctl status samba-ad-dc.service &>> $LOG
       systemctl disable nmbd.service smbd.service winbind.service &>> $LOG

#	Criar zonas insternas do samba
       if [ $DNSBE == "SAMBA_INTERNAL" ]	
       	then
		       samba-tool dns zonecreate $FQDN $ARPA -U Administrator --password=$SENHA &>> $LOG
		       samba-tool dns add $DOMINIO $ARPA $ARPAIP PTR $FQDN -U Administrator --password=$SENHA &>> $LOG
		       #samba_dnsupdate --use-file=/var/lib/samba/private/dns.keytab --all-names &>> $LOG
		       #samba-tool dbcheck --cross-ncs --fix --yes
	       else
       fi
       echo -e "[ \033[0;32m OK \033[0m ] Configuração zonas internas do samba ..."
	
#	Criar usuário no dominio:
       samba-tool user create $USUARIO $SENHA --login-shell=/bin/sh --uid-number="10000" --gid-number="10000" --nis-domain=$DOMINIO --unix-home=//smb01/profiles/$USUARIO
       samba-tool group addmembers administrators "$USUARIO"
       samba-tool user setexpiry $USUARIO --noexpiry &>> $LOG
       net rpc rights grant '$SMBDOMINIO\Domain Admins' SeDiskOperatorPrivilege -U $USUARIO%$SENHA &>> $LOG
       echo -e "[ \033[0;32m OK \033[0m ] Usuário no Domínio ..."