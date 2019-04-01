#!/bin/bash
#	Autor: Levi Barroso Menezes
#	Data de criação: 01/04/2019
#	Versão: 0.01
#	Ubuntu Server 18.04.x LTS x64
#	Kernel Linux 4.15.x

export DEBIAN_FRONTEND="noninteractive"

. variaveis		# variaveis de construção
. prep.sh		# verifica permições, atualiza e prepara repositorios
. rede.sh		# configura a rede 
. extra.sh		# instala programas de uso padrão
. ntp.sh		# instala e configura o NTP
. bind.sh		# instala e configura o BIND9 (DNS)
. krb.sh		# instala e configura o KERBERUS
. samba.sh		# instala e configura o SAMBA4 (AD-DC)
. dhcp.sh		# instala e configura o ISC-DHCP
. cups.sh		# instala e configura o CUPS (IMPRESSORAS)

#	Finalizar
HORAFINAL=$(date +%T)
HORAINICIAL01=$(date -u -d "$HORAINICIAL" +"%s")
HORAFINAL01=$(date -u -d "$HORAFINAL" +"%s")
TEMPO=$(date -u -d "0 $HORAFINAL01 sec - $HORAINICIAL01 sec" +"%H:%M:%S")
echo -e "Tempo de execução $0: $TEMPO"
echo -e "Fim do script $0 em: `date +%d/%m/%Y-"("%H:%M")"`\n" &>> $LOG
echo -e "Acesso ao banco de dados: $IP:5432"
echo -e "\033[0;31m Pode ser nescesario reiniciar o servidor !!! \033[0m" &>> $LOG
echo -e "Pressione \033[0;32m <Enter> \033[0m para reiniciar ou \033[0;33m <CTRL> + C \033[0m para finalizar o processo."
read
reboot 0
exit 1