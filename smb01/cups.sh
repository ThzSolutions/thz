#!/bin/bash

#	Instalar cups:
apt -y -q install cups cups-driver-gutenprint cups-common cups-core-drivers &>> $LOG
echo -e "[ \033[0;32m OK \033[0m ] Cups ..."
exit 1
