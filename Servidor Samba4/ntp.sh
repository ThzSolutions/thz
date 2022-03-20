export DEBIAN_FRONTEND="noninteractive"
.var
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
#	" > /etc/ntp.conf
	timedatectl set-timezone "$ZONA" &>> $LOG
	chown root:ntp /var/lib/samba/ntp_signd/
	ntpdate -dquv $SERVIDORNTP0 &>> $LOG
	systemctl restart ntp.service &>> $LOG
	hwclock --systohc &>> $LOG
	echo -e "[ \033[0;32m OK \033[0m ] Configuração NTP ..."
	sleep 1
exit 1