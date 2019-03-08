#!/bin/bash
# Autor: Levi Barroso Menezes
# Data de criação: 08/03/2019
# Versão: 0.01
# Ubuntu Server 18.04.x LTS x64
# Kernel Linux 4.15.x
# SAMBA-4.7.x
#
#variáveis do script
HORAINICIAL=`date +%T`
USER=`id -u`
UBUNTU=`lsb_release -rs`
KERNEL=`uname -r | cut -d'.' -f1,2`
LOG="/var/log/$(echo $0 | cut -d'/' -f2)"
#
#Variável do servidor:
NOME="addc-001"
DOMINIO="thz.intra"
FQDN="addc-001.thz.intra"
REINO="THZ.INTRA"
NETBIOS="THZ"
DNS="SAMBA_INTERNAL"
REGRA="dc"
LEVEL="2008_R2"
INTERFACE="enp0s3"
ENCAMINHAMENTO="8.8.8.8"
USUARIO="Supremo"
SENHA="P@ssw0rd"
NTP="a.st1.ntp.br"
IP="172.20.0.10"
MASCARA="/16"
GATEWAY="172.20.0.1"
ARPA="20.172.in-addr.arpa"
ARPAIP="10.0"
#
# Exportando o recurso de Noninteractive:
export DEBIAN_FRONTEND="noninteractive"
#clear
#
#Verificar permissões de usuário:
if [ "$USER" == "0" ]
	then
		echo -e "Permissão compatível .........................[ OK ]"
	else
		echo -e "O script deve ser executado como root ........[ ER ]"
		exit 1
fi
sleep 5
#
#Verificar versão da distribuição:
if [ "$UBUNTU" == "18.04" ]
	then
		echo -e "Versão da distribuição compatível ............[ OK ]"
	else
		echo -e "A distribuição deve ser 18.04 ................[ ER ]"
		exit 1
fi
sleep 5
#
#Verificar versão do kernel:
if [ "$KERNEL" == "4.15" ]
	then
		echo -e "O Kernel compatível ..........................[ OK ]"
	else
		echo -e "O Kernel deve ser 4.15 ou superior ...........[ ER ]"
		exit 1
fi
sleep 5
#
#Verificar Conexão com a internet:
ping -q -c5 google.com > /dev/null
if [ $? -eq 0 ]
	then
		echo -e "Internet .....................................[ OK ]"
	else
		echo -e "Sem conexão com a internet ...................[ ER ]"
		exit 1
fi
sleep 5
#
#Registrar inicio dos processos:
	echo -e "Início do script $0 em: `date +%d/%m/%Y-"("%H:%M")"`\n" &>> $LOG
#
#Adicionar o Repositório Universal:	
	add-apt-repository universe &>> $LOG
	echo -e "Repositório universal ............................[ OK ]"
sleep 5
#
#Adicionar o Repositório Multiversão:	
	add-apt-repository multiverse &>> $LOG
	echo -e "Repositório multiversão ..........................[ OK ]"
sleep 5
#
#Atualizar lista de repositórios:	
	apt update &>> $LOG
	echo -e "Lista de repositórios ............................[ OK ]"
sleep 5
#
#Atualizar sistema:	
	apt -y upgrade &>> $LOG
	echo -e "Atualização do sistema ...........................[ OK ]"
sleep 5
#
#Remover pacotes desnecessários:	
	apt -y autoremove &>> $LOG
	echo -e "Remoção de pacodes desnecessários ................[ OK ]"
sleep 5
#
#Instalar dependencias:	
	apt -y install ntp ntpdate build-essential libacl1-dev libattr1-dev libblkid-dev libgnutls28-dev libreadline-dev \
	python-dev libpam0g-dev python-dnspython gdb pkg-config libpopt-dev libldap2-dev dnsutils libbsd-dev docbook-xsl acl \
	attr debconf-utils figlet cifs-utils traceroute &>> $LOG
	echo -e "Dependências .....................................[ OK ]"
sleep 5
#
#Instalar e configurar KERBEROS:
	#echo -e "Configurando KERBEROS ..."
	echo "krb5-config krb5-config/default_realm string $REINO" | debconf-set-selections
	echo "krb5-config krb5-config/kerberos_servers string $FQDN" | debconf-set-selections
	echo "krb5-config krb5-config/admin_server string $FQDN" | debconf-set-selections
	echo "krb5-config krb5-config/add_servers_realm string $REINO" | debconf-set-selections
	echo "krb5-config krb5-config/add_servers boolean true" | debconf-set-selections
	echo "krb5-config krb5-config/read_config boolean true" | debconf-set-selections
	debconf-show krb5-config &>> $LOG
	apt -y install krb5-user krb5-config &>> $LOG
	mv -v /etc/krb5.conf /etc/krb5.conf.bkp &>> $LOG
	#
	# Construindo aquivo de configuração do KERBEROS:
	echo "[libdefaults]" >> /etc/krb5.conf &>> $LOG
	echo "	# Realm padrão" >> /etc/krb5.conf
	echo "	default_realm = $REINO" >> /etc/krb5.conf &>> $LOG
	echo " " >> /etc/krb5.conf
	#
	echo "# Opções utilizadas pela SAMBA4" >> /etc/krb5.conf
	echo "	dns_lookup_realm = false" >> /etc/krb5.conf &>> $LOG
	echo "	dns_lookup_kdc = true" >> /etc/krb5.conf &>> $LOG
	echo " " >> /etc/krb5.conf
	#
	echo "# Confguração padrão do Kerneros" >> /etc/krb5.conf
	echo "	krb4_config = /etc/krb.conf" >> /etc/krb5.conf &>> $LOG
	echo "	krb4_realms = /etc/krb.realms" >> /etc/krb5.conf &>> $LOG
	echo "	kdc_timesync = 1" >> /etc/krb5.conf &>> $LOG
	echo "	ccache_type = 4" >> /etc/krb5.conf &>> $LOG
	echo "	forwardable = true" >> /etc/krb5.conf &>> $LOG
	echo "	proxiable = true" >> /etc/krb5.conf &>> $LOG
	echo "	v4_instance_resolve = false" >> /etc/krb5.conf &>> $LOG
	echo "	v4_name_convert = {" >> /etc/krb5.conf
	echo "		host = {" >> /etc/krb5.conf
	echo "			rcmd = host" >> /etc/krb5.conf &>> $LOG
	echo "			ftp = ftp" >> /etc/krb5.conf &>> $LOG
	echo "		}" >> /etc/krb5.conf
	echo "		plain = {" >> /etc/krb5.conf
	echo "			something = something-else" >> /etc/krb5.conf &>> $LOG
	echo "		}" >> /etc/krb5.conf
	echo "	}" >> /etc/krb5.conf
	echo "	fcc-mit-ticketflags = true" >> /etc/krb5.conf &>> $LOG
	echo " " >> /etc/krb5.conf
	#
	echo "# Reino padrão" >> /etc/krb5.conf
	echo "[realms]" >> /etc/krb5.conf &>> $LOG
	echo "	$REINO = {" >> /etc/krb5.conf
	echo "		# Servidor de geração de KDC" >> /etc/krb5.conf
	echo "		kdc = addc-001.thz.intra" >> /etc/krb5.conf &>> $LOG
	echo "		#" >> /etc/krb5.conf
	echo "		# Servidor de Administração do KDC" >> /etc/krb5.conf
	echo "		admin_server = addc-001.thz.intra" >> /etc/krb5.conf &>> $LOG
	echo "		#" >> /etc/krb5.conf
	echo "		# Domínio padrão" >> /etc/krb5.conf
	echo "		default_domain = thz.intra" >> /etc/krb5.conf &>> $LOG
	echo "	}" >> /etc/krb5.conf
	echo " " >> /etc/krb5.conf
	#
	echo "# Domínio Realm" >> /etc/krb5.conf
	echo "[domain_realm]" >> /etc/krb5.conf &>> $LOG
	echo "	.thz.intra = THZ.INTRA" >> /etc/krb5.conf &>> $LOG
	echo "	thz.intra = THZ.INTRA" >> /etc/krb5.conf &>> $LOG
	echo " " >> /etc/krb5.conf
	#
	echo "# Geração do Tickets" >> /etc/krb5.conf
	echo "[login]" >> /etc/krb5.conf &>> $LOG
	echo "	krb4_convert = true" >> /etc/krb5.conf &>> $LOG
	echo "	krb4_get_tickets = false" >> /etc/krb5.conf &>> $LOG
	echo " " >> /etc/krb5.conf
	#
	echo "# Log dos tickets do Kerberos" >> /etc/krb5.conf
	echo "[logging] " >> /etc/krb5.conf &>> $LOG
	echo "  default = FILE:/var/log/krb5libs.log " >> /etc/krb5.conf &>> $LOG
	echo "  kdc = FILE:/var/krb5/krb5kdc.log " >> /etc/krb5.conf &>> $LOG
	echo "  admin_server = FILE:/var/log/krb5admin.log" >> /etc/krb5.conf &>> $LOG
	echo -e "Kerberos .........................................[ OK ]"
sleep 5
#
#Configurar NTP:
	#echo -e "Configurando NTP ..."	
	echo "0.0" > /var/lib/ntp/ntp.drift &>> $LOG
	chown -v ntp.ntp /var/lib/ntp/ntp.drift &>> $LOG
	mv -v /etc/ntp.conf /etc/ntp.conf.bkp &>> $LOG
	#
	# Construindo aquivo de configuração do NTP:
	echo "driftfile /var/lib/ntp/ntp.drift" >> /etc/ntp.conf &>> $LOG
	#
	echo "#Estatísticas do ntp que permitem verificar o histórico" >> /etc/ntp.conf
	echo "statsdir /var/log/ntpstats/" >> /etc/ntp.conf &>> $LOG
	echo "statistics loopstats peerstats clockstats" >> /etc/ntp.conf &>> $LOG
	echo "filegen loopstats file loopstats type day enable" >> /etc/ntp.conf &>> $LOG
	echo "filegen peerstats file peerstats type day enable" >> /etc/ntp.conf &>> $LOG
	echo "filegen clockstats file clockstats type day enable" >> /etc/ntp.conf &>> $LOG
	echo " " >> /etc/ntp.conf
	#
	echo "#Servidores publicos ntp.br" >> /etc/ntp.conf
	echo "server a.st1.ntp.br iburst" >> /etc/ntp.conf &>> $LOG
	echo "server b.st1.ntp.br iburst" >> /etc/ntp.conf &>> $LOG
	echo "server c.st1.ntp.br iburst" >> /etc/ntp.conf &>> $LOG
	echo "server d.st1.ntp.br iburst" >> /etc/ntp.conf &>> $LOG
	echo "server gps.ntp.br iburst" >> /etc/ntp.conf &>> $LOG
	echo "server a.ntp.br iburst" >> /etc/ntp.conf &>> $LOG
	echo "server b.ntp.br iburst" >> /etc/ntp.conf &>> $LOG
	echo "server c.ntp.br iburst" >> /etc/ntp.conf &>> $LOG
	echo " " >> /etc/ntp.conf &>> $LOG
	#
	echo "#Configuraçõess de restrição de acesso" >> /etc/ntp.conf
	echo "restrict 127.0.0.1" >> /etc/ntp.conf &>> $LOG
	echo "restrict 127.0.1.1" >> /etc/ntp.conf &>> $LOG
	echo "restrict ::1" >> /etc/ntp.conf &>> $LOG
	echo "restrict default kod notrap nomodify nopeer noquery" >> /etc/ntp.conf &>> $LOG
	echo "restrict -6 default kod notrap nomodify nopeer noquery" >> /etc/ntp.conf &>> $LOG
	#
	systemctl stop ntp.service &>> $LOG
	timedatectl set-timezone "America/Fortaleza" &>> $LOG
	ntpdate -dquv $NTP &>> $LOG
	systemctl start ntp.service &>> $LOG
	ntpq -pn &>> $LOG
	hwclock --systohc &>> $LOG
	echo -e "Data/Hora de hardware: `hwclock`\n"
	echo -e "Data/Hora de software: `date`\n"
	echo -e "NTP ..............................................[ OK ]"
sleep 5
#
#Configurar sistema de arquivos (FSTAB):
	#cp -v /etc/fstab /etc/fstab.bkp &>> $LOG
	#nano /etc/fstab ########## 
	mount -o remount,rw /dev/sda2 &>> $LOG
	echo -e "Sistema de aquivos ...............................[ OK ]"
sleep 5
#
#Auterar nome do servidor (HOSTNAME):
	cp -v /etc/hostname /etc/hostname.bkp &>> $LOG
	echo "$NOME" > /etc/hostname &>> $LOG
	echo -e "Nome do servidor (hostname) ......................[ OK ]"
sleep 5
#
#Configurar resolução de nomes local (HOSTS):
	mv -v /etc/hosts /etc/hosts.bkp &>> $LOG
	#
	# Construindo aquivo de configuração do HOSTS:
	echo "#IPv4" >> /etc/hostname
	echo "$IP		$FQDN		$NOME" >> /etc/hostname &>> $LOG
	echo "127.0.0.1		localhost.localdomain		localhost" >> /etc/hostname &>> $LOG
	echo "" >> /etc/hostname
	#
	echo "#IPv6" >> /etc/hostname
	echo "::1			localhost6.localdomain6		localhost6" >> /etc/hostname &>> $LOG
	echo "::1			localhost ip6-localhost ip6-loopback" >> /etc/hostname &>> $LOG
	echo "fe00::0		ip6-localnet" >> /etc/hostname &>> $LOG
	echo "ff02::1		ip6-allnodes" >> /etc/hostname &>> $LOG
	echo "ff02::2		ip6-allrouters" >> /etc/hostname &>> $LOG
	echo "ff02::3		ip6-allhosts" >> /etc/hostname &>> $LOG
	#
	echo -e "Resolução local de nomes (hosts) .................[ OK ]"
sleep 5
#
#Configurar ponte NS (NSSWITCH):
	mv -v /etc/nsswitch.conf /etc/nsswitch.conf.bkp &>> $LOG
	#
	# Construindo aquivo de configuração do HOSTS:
	echo "# Habilitar os recursos de files (arquivos) e winbind (integração) SAMBA+GNU/Linux" >> /etc/nsswitch.conf
	echo "passwd:         files compat systemd winbind" >> /etc/nsswitch.conf &>> $LOG
	echo "group:          files compat systemd winbind" >> /etc/nsswitch.conf &>> $LOG
	echo "shadow:         files compat systemd winbind" >> /etc/nsswitch.conf &>> $LOG
	echo "gshadow:        files" >> /etc/nsswitch.conf &>> $LOG
	echo "" >> /etc/nsswitch.conf
	#
	echo "# Configuração de resolução de nomes" >> /etc/nsswitch.conf
	echo "# Habilitar o recursos de dns depois de files (arquivo hosts)" >> /etc/nsswitch.conf &>> $LOG
	echo "hosts:          files dns mdns4_minimal [NOTFOUND=return]" >> /etc/nsswitch.conf &>> $LOG
	echo "networks:       files" >> /etc/nsswitch.conf &>> $LOG
	echo "" >> /etc/nsswitch.conf
	#
	echo "#Configurações padrão." >> /etc/nsswitch.conf
	echo "protocols:      db files" >> /etc/nsswitch.conf &>> $LOG
	echo "services:       db files" >> /etc/nsswitch.conf &>> $LOG
	echo "ethers:         db files" >> /etc/nsswitch.conf &>> $LOG
	echo "rpc:            db files" >> /etc/nsswitch.conf &>> $LOG
	echo "netgroup:       nis" >> /etc/nsswitch.conf &>> $LOG
	#
	echo -e "Ponte NS .........................................[ OK ]"
sleep 5
#
#Instalar SAMBA4:
	apt -y install samba samba-common smbclient cifs-utils samba-vfs-modules samba-testsuite samba-dsdb-modules \
	winbind ldb-tools libnss-winbind libpam-winbind unzip kcc tree &>> $LOG
	echo -e "Samba4 ...........................................[ OK ]"
sleep 5
#
#Configurar interfaces de rede:
	sleep 3
	mv /etc/netplan/50-cloud-init.yaml /etc/netplan/50-cloud-init.yaml.bkp
	#
	# Construindo aquivo de configuração do NETPLAN:
	echo "network:" >> /etc/netplan/50-cloud-init.yaml
	echo "    ethernets:" >> /etc/netplan/50-cloud-init.yaml
	echo "        $INTERFACE:" >> /etc/netplan/50-cloud-init.yaml
	echo "            dhcp: false" >> /etc/netplan/50-cloud-init.yaml
	echo "            addresses: [$IP$MASCARA]" >> /etc/netplan/50-cloud-init.yaml
	echo "            gateway4: $GATEWAY" >> /etc/netplan/50-cloud-init.yaml
	echo "            nameservers:" >> /etc/netplan/50-cloud-init.yaml
	echo "                addresses: [$IP, $ENCAMINHAMENTO]" >> /etc/netplan/50-cloud-init.yaml
	echo "                search: [$DOMINIO]" >> /etc/netplan/50-cloud-init.yaml
	echo "    version: 2" >> /etc/netplan/50-cloud-init.yaml
	#
	netplan --debug apply &>> $LOG
	echo -e "Interface de Rede .................................[ OK ]"
sleep 5
#
#Promovendo Controlador de Domínio do Active Directory:
	systemctl stop samba-ad-dc.service smbd.service nmbd.service &>> $LOG
	mv -v /etc/samba/smb.conf /etc/samba/smb.conf.bkp &>> $LOG
	samba-tool domain provision --realm=$REINO --domain=$NETBIOS --server-role=$REGRA --dns-backend=$DNS --use-rfc2307 \
	--adminpass=$SENHA --function-level=$LEVEL --site=$REINO --host-ip=$IP --option="interfaces = lo $INTERFACE" \
	--option="bind interfaces only = yes" --option="allow dns updates = nonsecure and secure" \
	--option="dns forwarder = $ENCAMINHAMENTO" --option="winbind use default domain = yes" --option="winbind enum users = yes" \
	--option="winbind enum groups = yes" --option="winbind refresh tickets = yes" --option="server signing = auto" \
	--option="vfs objects = acl_xattr" --option="map acl inherit = yes" --option="store dos attributes = yes" \
	--option="client use spnego = no" --option="use spnego = no" --option="client use spnego principal = no" &>> $LOG
	samba-tool user setexpiry $USUARIO --noexpiry &>> $LOG
	systemctl disable nmbd.service smbd.service winbind.service &>> $LOG
	systemctl mask nmbd.service smbd.service winbind.service &>> $LOG
	systemctl unmask samba-ad-dc.service &>> $LOG
	systemctl enable samba-ad-dc.service &>> $LOG
	systemctl start samba-ad-dc.service &>> $LOG
	net rpc rights grant 'THZ\Domain Admins' SeDiskOperatorPrivilege -U $USUARIO%$SENHA &>> $LOG
	samba-tool dns zonecreate $DOMINIO $ARPA -U $USUARIO --password=$SENHA &>> $LOG
	samba-tool dns add $DOMINIO $ARPA $ARPAIP PTR $FQDN -U $USUARIO --password=$SENHA &>> $LOG
	samba_dnsupdate --use-file=/var/lib/samba/private/dns.keytab --verbose --all-names &>> $LOG
	echo -e "Controlador de Domínio do Active Directory .........[ OK ]"
sleep 5
#
#Variáveis do script 2	
HORAFINAL=`date +%T`
HORAINICIAL01=$(date -u -d "$HORAINICIAL" +"%s")
HORAFINAL01=$(date -u -d "$HORAFINAL" +"%s")
TEMPO=`date -u -d "0 $HORAFINAL01 sec - $HORAINICIAL01 sec" +"%H:%M:%S"`
#
echo -e "Tempo de execução $0: $TEMPO"
echo -e "Fim do script $0 em: `date +%d/%m/%Y-"("%H:%M")"`\n" &>> $LOG
read
exit 1
