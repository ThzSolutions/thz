#!/bin/bash
. var

#	Instalar winbind
apt -y -q install winbind libnss-winbind libpam-winbind &>> $LOG
echo -e "[ \033[0;32m OK \033[0m ] Winbind ..."

#	Instalar recursos usados pelo samba:
apt -y -q install acl attr quota cifs-utils dnsutils &>> $LOG
echo -e "[ \033[0;32m OK \033[0m ] Recursos usados pelo samba ..."

#	Instalar samba4:
apt -y -q install samba smbclient samba-testsuite &>> $LOG
echo -e "[ \033[0;32m OK \033[0m ] Samba4 ..."

#	Provisionar controlador de domínio do active directory:
systemctl stop samba-ad-dc.service smbd.service nmbd.service &>> $LOG
mv /etc/samba/smb.conf /etc/samba/smb.conf.old
samba-tool domain provision --realm=$REINO --domain=$SMBDOMINIO --server-role=$REGRA --dns-backend=$DNSBE --option="dns forwarder = $DNSENCAMINHADO" --adminpass=$SENHA --function-level=$LEVEL --site=$REINO --host-ip=$IP --use-rfc2307 --use-ntvfs --option="server signing = auto" --option="client use spnego = no" --option="use spnego = no" --option="client use spnego principal = no" &>> $LOG
echo -e "[ \033[0;32m OK \033[0m ] Provisionamento do controlador de domínio ..."
	
#	Configurar SAMBA4:
mv /etc/samba/smb.conf /etc/samba/smb.bkp
printf "# Global parameters
[global]
        allow dns updates = nonsecure and secure
        bind interfaces only = Yes
        dns forwarder = $DNSENCAMINHADO
        interfaces = lo $INTERFACE0 $INTERFACE1
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
#		logon home = \\%L\%U\.profiles
#		logon path = \\%L\profiles\%U
#		hosts allow = 192.168.1. EXCEPT 192.168.1.20

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
		path = /arquivos/arquivos
		available = yes
		writable = no

[publico]
		comment = Pasta Pública
		path = /arquivos/samba_publico
		available = yes
		browseable = yes
		writable = yes" > smb.conf
systemctl unmask samba-ad-dc.service &>> $LOG
systemctl enable samba-ad-dc.service smbd.service nmbd.service &>> $LOG
systemctl restart samba-ad-dc.service smbd.service nmbd.service &>> $LOG
systemctl disable nmbd.service smbd.service winbind.service &>> $LOG
#systemctl mask nmbd.service smbd.service winbind.service &>> $LOG

#	Criar zonas insternas do SAMBA

if [ $DNSBE == "SAMBA_INTERNAL" ]	
	then
		samba-tool dns zonecreate $FQDN $ARPA -U Administrator --password=$SENHA &>> $LOG
		samba-tool dns add $DOMINIO $ARPA $ARPAIP PTR $FQDN -U Administrator --password=$SENHA &>> $LOG
		#samba_dnsupdate --use-file=/var/lib/samba/private/dns.keytab --all-names &>> $LOG
		#samba-tool dbcheck --cross-ncs --fix --yes
	else
fi
echo -e "[ \033[0;32m OK \033[0m ] Configuração do Controlador de Domínio ..."
	
#	Criar usuário no dominio:
samba-tool user create $USUARIO $SENHA --login-shell=/bin/sh --uid-number="10000" --gid-number="10000" --nis-domain=$DOMINIO --unix-home=//smb01/profiles/$USUARIO
samba-tool group addmembers administrators "$USUARIO"
samba-tool user setexpiry $USUARIO --noexpiry &>> $LOG
net rpc rights grant '$SMBDOMINIO\Domain Admins' SeDiskOperatorPrivilege -U $USUARIO%$SENHA &>> $LOG
echo -e "[ \033[0;32m OK \033[0m ] Usuário no Domínio ..."

exit 1