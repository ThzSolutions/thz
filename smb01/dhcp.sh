#!/bin/bash
#	Autor: Levi Barroso Menezes

source var.conf

#	Instalar dhcp:
apt -y -q install isc-dhcp-server &>> $LOG
echo -e "[ \033[0;32m OK \033[0m ] Dhcp ..."
exit 1
