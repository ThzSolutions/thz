#!/bin/bash
#	Autor: Levi Barroso Menezes

source var.conf

#	Instalar bind9
apt -y -q install bind9utils &>> $LOG
echo -e "[ \033[0;32m OK \033[0m ] Bind9 ..."

#	Configurar opções do bind9
mv /etc/bind/named.conf.options /etc/bind/named.conf.options.bkp
printf " 
options {
	directory "/var/cache/bind";
	forwarders {
		DNSEX0;
		DNSEX1;
		DNSEX2;
		DNSEX3;
	};
	dnssec-validation auto;
	auth-nxdomain yes;
	empy-zones-enable no;
	listen-on-v6 { any; };
};" > /etc/bind/named.conf.options
echo -e "[ \033[0;32m OK \033[0m ] Configuração de opções do bind9 ..."

#	Configurar locais de zona do bind9
mv /etc/bind/named.conf.local /etc/bind/named.conf.local.bkp
printf "zone $ZONADOMINIO{
		type master;
		file $ZONADIRFILE;
};	
zone $ZONAARPA{
		type master;
		file $ZONAREVFILE;
}; " > /etc/bind/named.conf.local
echo -e "[ \033[0;32m OK \033[0m ] Configuração local do bind9 ..."
	
#	Criar zona direta do dominio
printf ";
$TTL    604800
@       	IN      SOA     $FQDN.				root.$DOMINIO.	 (
							2					; Serial
							604800        		; Refresh
							86400         		; Retry
							2419200         	; Expire
							604800 )       		; Negative Cache TTL
;
@       	IN      NS      $FQDN.
@       	IN      A       $IP0v4
$NOME		IN		A		$IP0v4
@       	IN      AAAA    ::1" > etc/bind/db.thz.intra
echo -e "[ \033[0;32m OK \033[0m ] Zona direta do dominio ..."

#	Criar zona reversa do dominio
printf ";
$TTL    604800
@       	IN      SOA     $FQDN.				root.$DOMINIO.	 (
							1809201402			; Serial
							604800        		; Refresh
							86400         		; Retry
							2419200         	; Expire
							604800 )       		; Negative Cache TTL
;
@       	IN      NS      $NOME.
$ARPAIP    	IN      PTR		$DOMINIO.
$ARPAIP    	IN      PTR		$FQDN." > etc/bind/db.20.172.in-addr.arpa
systemctl restart bind9.service
echo -e "[ \033[0;32m OK \033[0m ] Zona reversa do dominio ..."
	
#	Incluir samba no bind
printf '#	Lista de arquivos incluidos:
include "/etc/bind/named.conf.options";
include "/etc/bind/named.conf.local";
include "/etc/bind/named.conf.default-zones";
include "/usr/share/samba/setup/named.conf.dlz";' > /etc/bind/named.conf
echo -e "[ \033[0;32m OK \033[0m ] Samba4 incluido no bind9 ..."
exit 1