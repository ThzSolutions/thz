#!/bin/bash

#	Autor: Levi Barroso Menezes
#	Data de criação: 24/03/2019
#	Versão: 0.03
#	Grafana

#	Variável do servidor:
	NOME="srv-monit002"
	DOMINIO="thz.intra"
	ZONA="America/Fortaleza"
	FQDN="$NOME.$DOMINIO"

#	Variáveis de Rede
	NETPLAN="true"
	INTERFACE="enp0s3"
	DHCPv4="true"
	IPv4="172.20.0.15"
	MASCARAv4="/16"
	GATEWAYv4="172.20.0.1"
	DHCPv6="true"
	IPv6=""
	MASCARAv6=""
	GATEWAYv6=""
	DNS0="172.20.0.10"
	DNS1="4.4.8.8"
	DNS2="8.8.4.4"
	DNS3="8.8.8.8"

#	variáveis do script
	HORAINICIAL=`date +%T`
	LOG="/var/log/$(echo $0 | cut -d'/' -f2)"

#	Exportando o recurso de Noninteractive:
	export DEBIAN_FRONTEND="noninteractive"

#	Registrar inicio dos processos:
	echo -e "Início do script $0 em: `date +%d/%m/%Y-"("%H:%M")"`\n" &>> $LOG

#	Padronização:
	bash base.sh

#	Auterar nome do servidor (HOSTNAME):
	printf "$NOME" > /etc/hostname
	printf "
#IP versão 4
127.0.0.1		localhost.localdomain	localhosta
$IPv4			$FQDN	$NOME

#IP versão 6
::1			localhost	ip6-localhost	ip6-loopback
ff02 :: 1 	ip6-allnodes
ff02 :: 2 	ip6-allrouters
$IPv6		$FQDN	$NOME

#	" > /etc/hosts
	echo -e "[ \033[0;32m OK \033[0m ] Nome do servidor ..."
sleep 1

#	Configurar interfaces de rede:
	mv /etc/netplan/01-netcfg.yaml /etc/netplan/01-netcfg.yaml.bkp
	printf "
network:
    version: 2
    renderer: networkd
    ethernets:
        $INTERFACE:
            dhcp4: $DHCPv4
            dhcp6: $DHCPv6
            addresses: [$IPv4$MASCARAv4, $IPv6$MASCARAv6]
            gateway4: $GATEWAYv4
            nameservers:
                addresses: [$DNS0, $DNS1, $DNS2, $DNS3]
                search: [$DOMINIO]
#	" > /etc/netplan/01-netcfg.yaml
	netplan --debug apply &>> $LOG
	echo -e "[ \033[0;32m OK \033[0m ] Configurações de rede ..."
sleep 1

#	Adicionar repositório grafana
	echo "deb https://packages.grafana.com/oss/deb stable main" > /etc/apt/sources.list.d/grafana.list
	curl -s https://packages.grafana.com/gpg.key | sudo apt-key add - &>> $LOG
	apt -y -q update &>> $LOG
	echo -e "[ \033[0;32m OK \033[0m ] Repositórios do grafana ..."
sleep 1

#	Instalar grafana:
	apt -y -q install grafana apt-transport-https
	echo -e "[ \033[0;32m OK \033[0m ] Grafana ..."
sleep 1

#	Configurar grafana
	update-rc.d grafana-server defaults
	systemctl enable grafana-server.service
	systemctl daemon-reload
	systemctl start grafana-server
	echo -e "[ \033[0;32m OK \033[0m ] Configuração do grafana ..."
sleep 1

#	Configurar banco de dados
#	su postgres -c "dropuser grafana"
	echo -e "\033[0;33m Senha pra o banco de dados grafana \033[0m"
	export DEBIAN_FRONTEND="interactive"
	su postgres -c "createuser -a -d -E -P grafana"
	export DEBIAN_FRONTEND="noninteractive"
#	su postgres -c "dropdb grafana"
	su postgres -c "createdb -O grafana grafana"
	exit
	echo -e "[ \033[0;32m OK \033[0m ] Configuração do bando de dados ..."

#Finalizar
	HORAFINAL=$(date +%T)
	HORAINICIAL01=$(date -u -d "$HORAINICIAL" +"%s")
	HORAFINAL01=$(date -u -d "$HORAFINAL" +"%s")
	TEMPO=$(date -u -d "0 $HORAFINAL01 sec - $HORAINICIAL01 sec" +"%H:%M:%S")
	echo -e "Tempo de execução $0: $TEMPO"
	echo -e "Fim do script $0 em: `date +%d/%m/%Y-"("%H:%M")"`\n" &>> $LOG
	echo -e "Acesso ao banco de dados: $IP:5432"
	echo -e "\033[0;31m Pode ser nescesario reiniciar o servidor !!! \033[0m"
	echo -e "Pressione \033[0;32m <Enter> \033[0m para finalizar o processo."
	read
exit 1

