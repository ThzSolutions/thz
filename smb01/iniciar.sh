#!/bin/bash
#	Autor: Levi Barroso Menezes
#	Data de criação: 31/03/2019
#	Versão: 0.11

source var.conf

bash prep.sh
bash srv.sh
bash ntp.sh
bash bind.sh
bash krb.sh
bash smb.sh
bash dhcp.sh
bash cups.sh
exit 1
