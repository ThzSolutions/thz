#!/bin/bash
# Autor: Levi Barroso Menezes
# Data de criação: 08/03/2019
# Versão: 0.01
# Ubuntu Server 18.04.x LTS x64
# Kernel Linux 4.15.x
#
#Variáveis do NTP
ZONA="America/Fortaleza"
#
# Exportando o recurso de Noninteractive:
# export DEBIAN_FRONTEND="noninteractive"
#
#Configurar NTP:
	apt -y install ntp ntpdate
	#echo -e "Configurando NTP ..."	
	printf "0.0" > /var/lib/ntp/ntp.drift
	chown -v ntp.ntp /var/lib/ntp/ntp.drift &>> $LOG
	mv -v /etc/ntp.conf /etc/ntp.conf.bkp &>> $LOG
	#
	# Construindo aquivo de configuração do NTP:
	printf "
driftfile /var/lib/ntp/ntp.drift

#Estatísticas do ntp que permitem verificar o histórico
statsdir /var/log/ntpstats/
statistics loopstats peerstats clockstats
filegen loopstats file loopstats type day enable
filegen peerstats file peerstats type day enable
filegen clockstats file clockstats type day enable

#Servidores publicos ntp.br
server a.st1.ntp.br iburst
server b.st1.ntp.br iburst
server c.st1.ntp.br iburst
server d.st1.ntp.br iburst
server gps.ntp.br iburst
server a.ntp.br iburst
server b.ntp.br iburst
server c.ntp.br iburst
			
#Configurações de restrição de acesso
restrict 127.0.0.1
restrict 127.0.1.1
restrict ::1
restrict default kod notrap nomodify nopeer noquery
restrict -6 default kod notrap nomodify nopeer noquery
	" > /etc/ntp.conf
	systemctl stop ntp.service
	timedatectl set-timezone "$ZONA"
	ntpdate -dquv $NTP
	update-rc.d ntp.service defaults
	systemctl enable ntp.service
	systemctl start ntp.service
	ntpq -pn
	hwclock --systohc
	#echo "Data/Hora de hardware: `hwclock`\n"
	#echo "Data/Hora de software: `date`\n"
sleep 1
exit 1
