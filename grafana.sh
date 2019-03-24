#!/bin/bash
# Autor: Levi Barroso Menezes
# Data de criação: 08/03/2019
# Versão: 0.01
# Ubuntu Server 18.04.x LTS x64
# Kernel Linux 4.15.x
# SAMBA-4.7.x
#
#Variável do servidor:
NOME="srv-monit002"
DOMINIO="thz.intra"
ZONA="America/Fortaleza"
FQDN="$NOME.$DOMINIO"
#
#Variáveis de Rede
NETPLAN="true"
INTERFACE="enp0s3"
IPv4="172.20.0.15"
MASCARAv4="/16"
GATEWAYv4="172.20.0.1"
IPv6=""
MASCARAv6=""
GATEWAYv6=""
DNS0="172.20.0.10"
DNS1="4.4.8.8"
DNS2="8.8.4.4"
DNS3="8.8.8.8"
LOOP="127.0.0.1"
#
#variáveis do script
HORAINICIAL=`date +%T`
USER=`id -u`
UBUNTU=`lsb_release -rs`
KERNEL=`uname -r | cut -d'.' -f1,2`
LOG="/var/log/$(echo $0 | cut -d'/' -f2)"
#
# Exportando o recurso de Noninteractive:
export DEBIAN_FRONTEND="noninteractive"
#
#Registrar inicio dos processos:
echo -e "Início do script $0 em: `date +%d/%m/%Y-"("%H:%M")"`\n" &>> $LOG
#
#Verificar permissões de usuário:
if [ "$USER" == "0" ]
	then
		echo -e "[ \033[0;32m OK \033[0m ] Permissão concedida ..."
	else
		echo -e "[ \033[0;31m ER \033[0m ] Premissões negadas (Root) ..."
		echo -e "\033[0;33m Pressione <ENTER> se quiser continuar ou <CTRL> + C para sair.\033[0m"
		read
fi
sleep 1
#
#Verificar versão da distribuição:
if [ "$UBUNTU" == "18.04" ]
	then
		echo -e "[ \033[0;32m OK \033[0m ] Distribuição compatível ..."
	else
		echo -e "[ \033[0;31m ER \033[0m ] Distribuição não homologada (Ubuntu 18.04) ..."
		echo -e "\033[0;33m Pressione <ENTER> se quiser continuar ou <CTRL> + C para sair.\033[0m"
		read
fi
sleep 1
#
#Verificar versão do kernel:
if [ "$KERNEL" == "4.15" ]
	then
		echo -e "[ \033[0;32m OK \033[0m ] Kernel compatível ..."
	else
		echo -e "[ \033[0;31m ER \033[0m ] Kernel incompativel (Linux 4.15 ou superior) ..."
		echo -e "\033[0;33m Pressione <ENTER> se quiser continuar ou <CTRL> + C para sair.\033[0m"
		read
fi
sleep 1
#
#Verificar conexão com a internet:
ping -q -c5 google.com > /dev/null
if [ $? -eq 0 ]
	then
		echo -e "[ \033[0;32m OK \033[0m ] Internet ..."
	else
		echo -e "[ \033[0;31m ER \033[0m ] Sem conexão com a internet ..."
		echo -e "\033[0;33m Pressione <ENTER> se quiser continuar ou <CTRL> + C para sair.\033[0m"
		read
fi
sleep 1
#
#Adicionar o repositório universal:	
	add-apt-repository universe &>> $LOG
	echo -e "[ \033[0;32m OK \033[0m ] Repositório universal ..."
sleep 1
#
#Adicionar o repositório multiversão:	
	add-apt-repository multiverse &>> $LOG
	echo -e "[ \033[0;32m OK \033[0m ] Repositório multiversão ..."
sleep 1
#
#Atualizar lista de repositórios:	
	 &>> $LOG
	echo -e "[ \033[0;32m OK \033[0m ] Atualização de repositórios ..."
sleep 1
#
#Atualizar sistema:	
	apt -y upgrade &>> $LOG
	echo -e "[ \033[0;32m OK \033[0m ] Atualização do sistema ..."
sleep 1
#
#Remover pacotes desnecessários:	
	apt -y autoremove &>> $LOG
	echo -e "[ \033[0;32m OK \033[0m ] Remoção de pacodes desnecessários ..."
sleep 1
#
#Instalar curl:	
	apt -y install curl 
	echo -e "[ \033[0;32m OK \033[0m ] Curl ..."
sleep 1
#
#Adicionar repositório grafana
	echo "deb https://packages.grafana.com/oss/deb stable main" > /etc/apt/sources.list.d/grafana.list
	curl -s https://packages.grafana.com/gpg.key | sudo apt-key add - &>> $LOG
	apt update &>> $LOG
	echo -e "[ \033[0;32m OK \033[0m ] Repositórios do grafana..."
sleep 1
#
#Instalar grafana:	
	apt -y install grafana apt-transport-https
	echo -e "[ \033[0;32m OK \033[0m ] Grafana ..."
sleep 1
#
#Configurar grafana
	update-rc.d grafana-server defaults
	systemctl enable grafana-server.service
	systemctl daemon-reload
	systemctl start grafana-server
	systemctl status grafana-server
	echo -e "[ \033[0;32m OK \033[0m ] Configuração do grafana..."
#
#NTP:
	bash ntp.sh
	echo -e "[ \033[0;32m OK \033[0m ] NTP ..."
sleep 1
#
#Auterar nome do servidor (HOSTNAME):
	printf "$NOME" > /etc/hostname
	printf "
#IP versão 4
$LOOP		$NOME	localhost	$FQDN
$IPv4		$NOME	localhost	$FQDN

#IP versão 6
::1			$NOME	localhost	$FQDN
$IPv6		$NOME	localhost	$FQDN
	" > /etc/hosts
	echo -e "[ \033[0;32m OK \033[0m ] Nome do servidor ..."
sleep 1
#
#Configurar interfaces de rede:
if [ "$NETPLAN" == "true" ]
	then
		mv /etc/netplan/01-netcfg.yaml /etc/netplan/01-netcfg.yaml.bkp
		printf "
network:
    version: 2
    renderer: networkd
    ethernets:
        $INTERFACE:
            dhcp4: false
            dhcp6: yes
            addresses: [$IPv4$MASCARAv4, $IPv6$MASCARAv6]
            gateway4: $GATEWAYv4
            nameservers:
                addresses: [$DNS0, $DNS1, $DNS2, $DNS3]
                search: [$DOMINIO]
		" > /etc/netplan/01-netcfg.yaml
		netplan --debug apply &>> $LOG
		echo -e "[ \033[0;32m OK \033[0m ] Configurações de rede ..."
	else
		echo -e "[ \033[0;33m NO \033[0m ] Configurações de rede ..."
fi
sleep 1
#
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

