#!/bin/bash

# Variables de configuración
LDAP_URI="ldap://192.168.2.254"     	# URL del servidor LDAP
BASE_DN="dc=infomur,dc=es"          	# Base DN del dominio LDAP
ADMIN_DN="cn=admin,dc=infomur,dc=es" 	# Usuario administrador del dominio LDAP
ADMIN_PASSWORD="Admin1"              	# Contraseña del admin


# Función para mostrar el menú
mostrar_menu() {
  echo "Configuración del Cliente LDAP"
  echo "1. Modificar dirección del servidor LDAP"
  echo "2. Modificar DN base"
  echo "3. Modificar credenciales del administrador"
  echo "4. Continuar sin cambios"
  echo "5. Salir"
  echo
}


# Función para modificar configuraciones
modificar_configuracion() {
  while true; do
    mostrar_menu
    read -p "Seleccione una opción: " opcion
    case $opcion in
      1)
        read -p "Ingrese la nueva dirección del servidor LDAP: " LDAP_URI
        ;;
      2)
        read -p "Ingrese el nuevo DN base: " BASE_DN
        ;;
      3)
        read -p "Ingrese el nuevo DN del administrador: " ADMIN_DN
        read -s -p "Ingrese la nueva contraseña del administrador: " ADMIN_PASSWORD
        echo
        ;;
      4)
        echo "Continuando con la configuración actual..."
        break
        ;;
      5)
        echo "No se ha realizado ninguna acción."
        exit 0
        ;;
      *)
        echo "Opción no válida, intente nuevamente."
        ;;
    esac
  done
}

# Llamar a la función de configuración
modificar_configuracion

# Para que el proceso sea automatizado:
export DEBIAN_FRONTEND=noninteractive

# Actualizar los repositorios y asegurarse de que el sistema esté actualizado
# sudo apt update && sudo apt upgrade -y

# Instalar paquetes necesarios en modo no interactivo
sudo DEBIAN_FRONTEND=noninteractive apt install -y libnss-ldap libpam-ldap ldap-utils ldap-auth-config

# Configurar LDAP (sin interacción del usuario) usando debconf y un archivo preseed
cat <<EOF | sudo debconf-set-selections
ldap-auth-config ldap-auth-config/enable-ldap boolean true
ldap-auth-config ldap-auth-config/ldapns/ldap-server string $LDAP_URI
ldap-auth-config ldap-auth-config/ldapns/base-dn string $BASE_DN
ldap-auth-config ldap-auth-config/ldapns/ldap_version select 3
ldap-auth-config ldap-auth-config/dbrootlogin boolean false
ldap-auth-config ldap-auth-config/dblogin boolean false
ldap-auth-config ldap-auth-config/rootbinddn string $ADMIN_DN
ldap-auth-config ldap-auth-config/rootbindpw password $ADMIN_PASSWORD
ldap-auth-config ldap-auth-config/pam_password select md5
ldap-auth-config ldap-auth-config/move-to-debconf boolean true
ldap-auth-config ldap-auth-config/override boolean true
EOF

# Forzar la reconfiguración de ldap-auth-config sin interacción
sudo dpkg-reconfigure -f noninteractive ldap-auth-config

# Configuración de NSS (Name Service Switch)
sudo sed -i '/^passwd:.*systemd/s/systemd/ldap/' /etc/nsswitch.conf
sudo sed -i '/^group:.*systemd/s/systemd/ldap/' /etc/nsswitch.conf
sudo sed -i '/^shadow:.*systemd/s/systemd/ldap/' /etc/nsswitch.conf

# Configuración de PAM (Authentication)
sudo pam-auth-update --enable mkhomedir --quiet

# Modificación en /etc/pam.d/common-password para eliminar use_authtok de la línea 26
sudo sed -i '26s/use_authtok //' /etc/pam.d/common-password

# Agregar línea (justo antes de la última) en /etc/pam.d/common-session para crear directorio home automáticamente
sudo sed -i '$ i session optional pam_mkhomedir.so skel=/etc/skel umask=077' /etc/pam.d/common-session

# Modificar la línea 27 del archivo /etc/ldap.conf para establecer la base
sudo sed -i '27s|.*|base dc=infomur,dc=es|' /etc/ldap.conf

# Modificar la línea 30 del archivo /etc/ldap.conf para establecer la URI
sudo sed -i '30s|.*|uri ldap://192.168.2.254|' /etc/ldap.conf

# Verificación de conexión LDAP
if ldapsearch -x -H "$LDAP_URI" -b "$BASE_DN" -D "$ADMIN_DN" -w "$ADMIN_PASSWORD" | grep -q "dn: $BASE_DN"; then
	echo "El cliente Ubuntu se ha unido correctamente al dominio OpenLDAP."
else
	echo "Error: No se pudo conectar al dominio OpenLDAP."
fi
