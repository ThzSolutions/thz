#!/bin/bash
#	Autor: Levi Barroso Menezes

source var.conf
	
#	Instalar winbind
apt -y -q install winbind libnss-winbind libpam-winbind &>> $LOG
echo -e "[ \033[0;32m OK \033[0m ] Winbind ..."

#	Instalar recursos usados pelo samba:
apt -y -q install acl attr quota cifs-utils dnsutils &>> $LOG
echo -e "[ \033[0;32m OK \033[0m ] Recursos usados pelo samba ..."

#	Instalar SAMBA4:
apt -y -q install samba smbclient samba-testsuite &>> $LOG
echo -e "[ \033[0;32m OK \033[0m ] Samba4 ..."
exit 1