#!/bin/bash
. variaveis

#	Instalar e configurar kerberos:
mv /etc/krb5.conf /etc/krb5.conf.bkp
debconf-show krb5-config &>> $LOG
apt -y -q install krb5-user krb5-kdc krb5-config debconf-utils &>> $LOG
echo "krb5-config krb5-config/default_realm string $REINO" | debconf-set-selections
echo "krb5-config krb5-config/kerberos_servers string $FQDN" | debconf-set-selections
echo "krb5-config krb5-config/admin_server string $FQDN" | debconf-set-selections
echo "krb5-config krb5-config/add_servers_realm string $REINO" | debconf-set-selections
echo "krb5-config krb5-config/add_servers boolean true" | debconf-set-selections
echo "krb5-config krb5-config/read_config boolean true" | debconf-set-selections
echo -e "[ \033[0;32m OK \033[0m ] Kerberos ..."
	
#	Configurar kerberos:
printf "[libdefaults]
# 	Realm padrão
	default_realm = $REINO
 
#	Opções utilizadas pela SAMBA4
	dns_lookup_realm = false
	dns_lookup_kdc = true
 
#	Confguração padrão do Kerneros
	krb4_config = /etc/krb.conf
	krb4_realms = /etc/krb.realms
	kdc_timesync = 1
	ccache_type = 4
	forwardable = true
	proxiable = true
	v4_instance_resolve = false
	v4_name_convert = {
		host = {
			rcmd = host
			ftp = ftp
		}
		plain = {
			something = something-else
		}
	}
	fcc-mit-ticketflags = true
 
#	Reino padrão
[realms]
	$REINO = {
		# Servidor de geração de KDC
		kdc = $FQDN
		# Servidor de Administração do KDC
		admin_server = $FQDN
		# Domínio padrão
		default_domain = $DOMINIO
	}
 
#	Domínio Realm
[domain_realm]
	.$DOMINIO = $REINO
	$DOMINIO = $REINO
 
#	Geração do Tickets
[login]
	krb4_convert = true
	krb4_get_tickets = false
 
#	Log dos tickets do Kerberos
[logging] 
	default = FILE:/var/log/krb5libs.log 
	kdc = FILE:/var/krb5/krb5kdc.log 
	admin_server = FILE:/var/log/krb5admin.log" > /etc/krb5.conf
echo -e "[ \033[0;32m OK \033[0m ] Configuração kerberos ..."
exit 1