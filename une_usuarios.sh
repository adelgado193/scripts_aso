 #!/bin/bash

# Configuración de las variables de entorno
DOMINIO="infomur.es" # Nombre del dominio LDAP
LDAP_BASE_DN="dc=infomur,dc=es" # Distinguished Name del dominio
LDAP_URI="ldap://192.168.2.254" # Dirección del servidor LDAP
ADMIN_DN="cn=admin,dc=infomur,dc=es" # DN del administrador del dominio
ADMIN_PASSWORD="Admin1" # Contraseña del admin del dominio LDAP

# Comprobamos si el cliente ya estaba unido al dominio previamente
if grep -q "$DOMINIO" /etc/hosts; then
	echo "El cliente ya está unido al dominio $DOMINIO."
	exit 1
fi

# Instalación de paquetes necesarios
echo "Instalando paquetes necesarios..."
# Esta línea sirve para que la instalación se realice automática sin que el usuario interactúe
sudo DEBIAN_FRONTEND=noninteractive apt update -y
sudo DEBIAN_FRONTEND=noninteractive apt install -y libnss-ldap libpam-ldap ldap-utils nscd

# Configuración del cliente LDAP
echo "Configurando cliente LDAP..."

# Configurar NSS para usar LDAP
# Busca las líneas que empiezan por passwd, group y shadow y les añade
# al final ldap
echo "Modificando el fichero /etc/nsswitch.conf para usar LDAP..."
sudo sed -i '/^passwd:/ s/$/ ldap/' /etc/nsswitch.conf
sudo sed -i '/^group:/ s/$/ ldap/' /etc/nsswitch.conf
sudo sed -i '/^shadow:/ s/$/ ldap/' /etc/nsswitch.conf

# Modificamos el fichero ldap.conf
echo "Configurando el fichero /etc/ldap.conf..."

# El contenido que hay entre <<EOL EOL es lo que se escribirá en el fichero /etc/ldap.conf
sudo bash -c " cat > /etc/ldap.conf" <<EOL base $LDAP_BASE_DN #Pedirá al usuario el nombre del dominio
uri $LDAP_URI #pedirá al usuario la dirección del servidor LDAP
ldap_version 3 #Versión de LDAP que se utilizará
binddn $ADMIN_DN #pedirá al usuario el DN del admin del dominio
bindpw $ADMIN_PASSWORD #pedirá al usuario la contraseña del admin del dominio
rootbinddn $ADMIN_DN #establece el DN de acceso para ROOT
pam_password md5 #Método de hashing que se utilizará para las contraseñas en PAM
EOL

# Modificamos el fichero /etc/pam.d/common-session
echo "Configurando /etc/pam.d/common-session..."
sudo bash -c "echo 'session required pam_mkhomedir.so skel=/etc/skel umask=0022' >> /etc/pam.d/common-session"

# Reiniciar servicios para aplicar los cambios
echo "Reiniciando servicios..."
sudo systemctl restart nscd

# Probar conexión con el servidor LDAP
echo "Espere, estamos conectando con el servidor LDAP..."
ldapsearch -x -b "dc=infomur,dc=es" || {echo "Error de conexión con el servidor LDAP"; exit 1;}

# Configuración finalizada
echo "El cliente Ubuntu ha sido configurado para unirse al dominio OpenLDAP."
