#!/bin/bash
export DEBIAN_FRONTEND="noninteractive"
.var

#	Configurar interfaces de rede (netplan):
       rm -r /etc/netplan/*
       printf "
       network:
       version: 2
       renderer: networkd
       ethernets:
              $INTERFACE0:
              dhcp4: $DHCP0v4
              dhcp6: $DHCP0v6
              addresses: [$IP0v4$MASCARA0v4]
              gateway4: $GATEWAY0v4
              nameservers:
                     addresses: [$IP0v4, $DNSEX0, $DNSEX1, $DNSEX2, $DNSEX3]
                     search: [$DOMINIO]
       " > /etc/netplan/00-netcfg.yaml
       netplan --debug apply &>> $LOG
       echo -e "[ \033[0;32m OK \033[0m ] Configurações de rede ..."

#	Auterar nome do servidor (hostname):
       printf "$NOME" > /etc/hostname
       echo -e "[ \033[0;32m OK \033[0m ] Nome do servidor ..."

#	Auterar resolução de nome interna (hosts):
       printf "
       #IP versão 4
       $IP0v4			$FQDN	$NOME
       #127.0.1.1		$FQDN	$NOME
       127.0.0.1		localhost.localdomain	localhost

       #IP versão 6
       $IP0v6			$FQDN	$NOME
       fe00::0			ip6-localnet
       ff02::1			ip6-allnodes
       ff02::2			ip6-allrouters
       ff02::3			ip6-allhosts
       ::1				localhost	ip6-localhost	ip6-loopback
       " > /etc/hosts
       echo -e "[ \033[0;32m OK \033[0m ] Resolução de nome interna ..."

#	Auterar resolução de nomes externa (resolv.conf):
       printf "
       nameserver $IP0v4
       nameserver $DNSEX0
       nameserver $DNSEX1
       nameserver $DNSEX2
       nameserver $DNSEX3
       search $DOMINIO
       domain $DOMINIO" > /etc/resolv.conf
       echo -e "[ \033[0;32m OK \033[0m ] Resolução de nome externa ..."

#	Configurar ponte nsswitch:
       mv /etc/nsswitch.conf /etc/nsswitch.conf.bkp
       printf "
       #	Habilitar os recursos de files (arquivos) e winbind (integração) SAMBA+GNU/Linux
       passwd:              files compat systemd winbind
       group:               files compat systemd winbind
       shadow:              files compat systemd winbind
       gshadow:             files
       passwd_compat:	nis
       group_compat:	       nis
       shadow_compat:	nis
       
       #	Configuração de resolução de nomes
       #	Habilitar o recursos de dns depois de files (arquivo hosts)
       hosts:               nis files dns mdns4_minimal [NOTFOUND=return]
       networks:   	       file

       #	Configurações padrão.
       services:   	nis files db [NOTFOUND=return]
       networks:   	nis files db [NOTFOUND=return]
       protocols:  	nis files db [NOTFOUND=return]
       rpc:        	nis files db [NOTFOUND=return]
       ethers:     	nis files db [NOTFOUND=return]
       netmasks:   	nis files db [NOTFOUND=return]
       netgroup:   	nis files db [NOTFOUND=return]
       bootparams: 	nis files db [NOTFOUND=return]
       publickey:  	nis files db [NOTFOUND=return]
       automount:  	files
       aliases:    	nis files [NOTFOUND=return]
       " > /etc/nsswitch.conf
       echo -e "[ \033[0;32m OK \033[0m ] Nsswitch ..."
exit 1