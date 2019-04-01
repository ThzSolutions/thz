#!/bin/bash
. variaveis

#	Instalar dhcp:
apt -y -q install isc-dhcp-server &>> $LOG
echo -e "[ \033[0;32m OK \033[0m ] Dhcp ..."
exit 1
