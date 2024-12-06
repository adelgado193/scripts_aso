#!/bin/bash
# Variables de configuración
LDAP_URI="ldap://192.168.2.254"         # URL del servidor LDAP
BASE_DN="dc=infomur,dc=es"              # Base DN del dominio LDAP
ADMIN_DN="cn=admin,dc=infomur,dc=es"    # Usuario admin del dominio
ADMIN_PASSWORD="Admin1"                 # Contraseña del admin

#  ------Función para obtener el siguiente uidNumber y el gidNumber

# Leemos y filtramos el fichero /etc/passwd

obtener_siguiente_uid_gid(){

# Realizar la consulta LDAP para obtener el mayor uidNumber en el rango válido

    ultimo_uid=$(ldapsearch -x -H "$LDAP_URI" -D "$ADMIN_DN" -w "$ADMIN_PASSWORD" \

        -b "$BASE_DN" "(uidNumber>=1001)" uidNumber 2>/dev/null | \

        grep "^uidNumber:" | awk '{print $2}' | sort -n | tail -1)


# Si no se encuentra ningún UID válido, asigna 1000 como inicial
    if [[ -z "$ultimo_uid" ]]; then
        echo "No se encontró ningún UID válido. Asignando UID inicial 1000."
        ultimo_uid=1000
    elif ! [[ "$ultimo_uid" =~ ^[0-9]+$ ]]; then
        echo "Error: UID inválido obtenido de LDAP: $ultimo_uid" >&2
        exit 1
    fi

# Incrementar el UID/GID en 1 para los nuevos usuarios
siguiente_uid=$((ultimo_uid + 1))


# Comprobar si está dentro del rango permitido (el uid que se ha encontrado)
if [[ "$siguiente_uid" -ge 65000 ]];then
echo "ERROR: No hay UIDs disponibles en el rango permitido (1000 - 65000).">&2
exit 1
fi

# Hacemos un "RETURN"
echo "$siguiente_uid"

}

# ----------------------------------------------------------
# --------- Función para crear un nuevo usuario
crear() {
# Datos que el usuario debe introducir:
echo "=== Bienvenido! Vamos a añadir un nuevo usuario al Dominio. Introduzca correctamente los datos: ==="

read -p "Nombre de Usuario: " nom_usuario
read -p "Nombre: " nombre
read -p "Primer Apellido: " apellido1
read -p "Segundo Apellido: " apellido2
read -sp "Contraseña: " password
echo ""
dn="uid=$nom_usuario,$BASE_DN"

# Calcular UID y GID
    uidNumber=$(obtener_siguiente_uid_gid)
    gidNumber=$uidNumber

# Validar UID obtenido
    if [[ -z "$uidNumber" || ! "$uidNumber" =~ ^[0-9]+$ ]]; then
        echo "Error: UID inválido: $uidNumber"
        exit 1
    fi
sleep 2

echo "Asignando UID: $uidNumber, y el GID: $gidNumber al usuario: $nom_usuario"
sleep 4

# Crear archivo LDIF para el nuevo usuario
cat <<EOF > crear_usuarios.ldif
dn: $dn
objectClass: inetOrgPerson
objectClass: posixAccount
objectClass: top
cn: $nombre $apellido1 $apellido2
sn: $apellido1
uid: $nom_usuario
givenName: $nombre
uidNumber: $uidNumber
gidNumber: $gidNumber
homeDirectory: /home/$nom_usuario
userPassword: $(echo -n "$password" | openssl passwd -6 -stdin)
loginShell: /bin/bash
mail: $nom_usuario@infomur.es
EOF

# Ejecutar ldapadd para crear el usuario
ldapadd -x -H "$LDAP_URI" -D "$ADMIN_DN" -w "$ADMIN_PASSWORD" -f crear_usuarios.ldif
    if [ $? -eq 0 ]; then
        echo "Usuario '$nom_usuario' creado correctamente con UID $uidNumber y GID $gidNumber."
    else
        echo "Error al crear el usuario '$nom_usuario'."
    fi
}

# ---------------------------------------------------------------
#  ------------ Función para modificar un usuario existente

modificar() {
echo "=== Vamos a realizar modificaciones: ==="
sleep 2
    read -p "Nombre de usuario: " nom_usuario
    read -sp "Nueva contraseña: " nueva_contrasena
    echo ""
    local dn="uid=$nom_usuario,$BASE_DN"

# Crear archivo LDIF para modificar el usuario
cat <<EOF > modificar_usuarios.ldif
dn: $dn
changetype: modify
replace: userPassword
userPassword: $nueva_contrasena
EOF


# Ejecutar ldapmodify para modificar el usuario
ldapmodify -x -H "$LDAP_URI" -D "$ADMIN_DN" -w "$ADMIN_PASSWORD" -f modificar_usuarios.ldif
    if [ $? -eq 0 ]; then
        echo "Contraseña del usuario '$nom_usuario' modificada correctamente."
    else
        echo "Error al modificar la contraseña del usuario '$nom_usuario'."
    fi
}

# ------------------------------------------------------------------
# --------- Función para modificar el email de un usuario

modificar_email() {
    echo "=== Modificar el email de un usuario ==="
    read -p "Nombre de usuario: " nom_usuario
    read -p "Nuevo email: " nuevo_email
    dn="uid=$nom_usuario,$BASE_DN"

    cat <<EOF > modificar_email.ldif
dn: $dn
changetype: modify
replace: mail
mail: $nuevo_email
EOF

    ldapmodify -x -H "$LDAP_URI" -D "$ADMIN_DN" -w "$ADMIN_PASSWORD" -f modificar_email.ldif
    if [ $? -eq 0 ]; then
        echo "Email del usuario '$nom_usuario' modificado correctamente a '$nuevo_email'."
    else
        echo "ERROR: No se pudo modificar el email del usuario '$nom_usuario'." >&2
    fi
}

# --------------------------------------------------------------
# --------- Función para crear un grupo

crear_grupo() {
    echo "=== Crear un grupo en el Dominio ==="
    read -p "Introduzca el nombre del grupo: " nombre_grupo
    gidNumber=$(obtener_siguiente_uid_gid)

    cat <<EOF > crear_grupo.ldif
dn: cn=$nombre_grupo,$BASE_DN
objectClass: posixGroup
objectClass: top
cn: $nombre_grupo
gidNumber: $gidNumber
EOF

    ldapadd -x -H "$LDAP_URI" -D "$ADMIN_DN" -w "$ADMIN_PASSWORD" -f crear_grupo.ldif
    if [ $? -eq 0 ]; then
        echo "Grupo '$nombre_grupo' creado correctamente con GID $gidNumber."
    else
        echo "ERROR: No se pudo crear el grupo '$nombre_grupo'." >&2
    fi
}



# --------------------------------------------------------------
# --------- Función para añadir un usuario a un grupo

anadir_usuario_grupo() {

    echo "=== Añadir un usuario a un grupo ==="
    read -p "Introduzca el nombre de usuario: " nom_usuario
    read -p "Introduzca el nombre del grupo: " nombre_grupo

    cat <<EOF > anadir_usuario_grupo.ldif
dn: cn=$nombre_grupo,$BASE_DN
changetype: modify
add: memberUid
memberUid: $nom_usuario
EOF

    ldapmodify -x -H "$LDAP_URI" -D "$ADMIN_DN" -w "$ADMIN_PASSWORD" -f anadir_usuario_grupo.ldif
    if [ $? -eq 0 ]; then
        echo "Usuario '$nom_usuario' añadido correctamente al grupo '$nombre_grupo'."
    else
        echo "ERROR: No se pudo añadir el usuario '$nom_usuario' al grupo '$nombre_grupo'." >&2
    fi
}

# --------------------------------------------------------------
# -------- Función para eliminar un usuario

eliminar() {

echo "=== Está a punto de Eliminar un Usuario: ==="
sleep 3
    read -p "Introduzca el Nombre de usuario que desea eliminar: " nom_usuario
    local dn="uid=$nom_usuario,$BASE_DN"


# Crear archivo LDIF para eliminar el usuario

cat <<EOF > eliminar_usuarios.ldif
dn: $dn
changetype: delete
EOF

# Ejecutar ldapdelete para eliminar el usuario
ldapdelete -x -H "$LDAP_URI" -D "$ADMIN_DN" -w "$ADMIN_PASSWORD" "$dn"
    if [ $? -eq 0 ]; then
        echo "Usuario '$nom_usuario' eliminado correctamente."
    else
        echo "Error al eliminar el usuario '$nom_usuario'."
    fi
}


# Menú Interactivo para que el usuario realice la acción que desee:
while true;do
echo "" #Imprime línea en blanco
 echo "=== Bienvenido/a a la Gestión de Usuarios LDAP ==="
    echo "1. Crear nuevo usuario"
    echo "2. Modificar contraseña de usuario"
    echo "3. Modificar el Email de un usuario"
    echo "4. Eliminar Usuario"
    echo "5. Crear nuevo grupo"
    echo "6. Añadir usuario a un grupo"
    echo "7. Salir"
    echo "================================="
    read -p "Seleccione una opción: " opcion

    case $opcion in
    
        1) crear ;;
        2) modificar ;;
        3) modificar_email ;;
        4) eliminar ;;
        5) crear_grupo ;;
        6) anadir_usuario_grupo ;;
        7) echo "Saliendo..."; exit 0 ;;
        *) echo "Opción no válida, inténtelo de nuevo." ;;
    esac
done
