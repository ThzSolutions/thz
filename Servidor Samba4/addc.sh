export DEBIAN_FRONTEND="noninteractive"
.var

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

exit 1