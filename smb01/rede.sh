#!/bin/bash
. var

#	Configurar interfaces de rede (netplan):
mv /etc/netplan/01-netcfg.yaml /etc/netplan/01-netcfg.yaml.bkp
printf "network:
    version: 2
    renderer: networkd
    ethernets:
        $INTERFACE0:
            dhcp4: $DHCP0v4
            dhcp6: $DHCP0v6
            addresses: [$IP0v4$MASCARA0v4]
            gateway4: $GATEWAY0v4
            nameservers:
                addresses: [$IP0v4, $DNSEX0, $DNSEX1]
                search: [$DOMINIO]
        $INTERFACE1:
            dhcp4: $DHCP1v4
            dhcp6: $DHCP1v6
            addresses: [$IP1v4$MASCARA1v4]
            gateway4: $GATEWAY1v4
            nameservers:
                addresses: [$IP1v4, $DNSEX0, $DNSEX1]
                search: [$DOMINIO]" > /etc/netplan/01-netcfg.yaml
netplan --debug apply &>> $LOG
echo -e "[ \033[0;32m OK \033[0m ] Configurações de rede ..."

#	Auterar nome do servidor (hostname):
printf "$NOME" > /etc/hostname
echo -e "[ \033[0;32m OK \033[0m ] Nome do servidor ..."

#	Auterar resolução de nome interna (hosts):
printf "#IP versão 4
$IP0v4			$FQDN	$NOME
#127.0.1.1		$FQDN	$NOME
127.0.0.1		localhost.localdomain	localhost

#IP versão 6
$IP0v6			$FQDN	$NOME
fe00::0			ip6-localnet
ff02::1			ip6-allnodes
ff02::2			ip6-allrouters
ff02::3			ip6-allhosts
::1				localhost	ip6-localhost	ip6-loopback" > /etc/hosts
echo -e "[ \033[0;32m OK \033[0m ] Resolução de nome interna ..."

#	Auterar resolução de nomes externa (resolv.conf):
printf "nameserver $IP0v4
nameserver $DNSEX0
search $DOMINIO
domain $DOMINIO" > /etc/resolv.conf
echo -e "[ \033[0;32m OK \033[0m ] Resolução de nome externa ..."

#	Configurar ponte nsswitch:
mv /etc/nsswitch.conf /etc/nsswitch.conf.bkp
printf "#	Configuração de acesso a informações de usuários, grupos e senhas.
passwd:         compat systemd winbind
group:          compat systemd winbind
shadow:         compat
gshadow:        files

#	Configuração de resolução de nomes
hosts:          file dns mdns4_minimal [NOTFOUND=return]
networks:   	file

#	Outros
services:   	db files nis [NOTFOUND=return]
protocols:  	db files nis [NOTFOUND=return]
rpc:        	db files nis [NOTFOUND=return]
ethers:     	db files nis [NOTFOUND=return]
netgroup:		nis" > /etc/nsswitch.conf
echo -e "[ \033[0;32m OK \033[0m ] Nsswitch ..."



