#!/bin/bash
# Definición de variables
DOMINIO="infomur.es" # Define el dominio LDAP
NOMBRE_USUARIO="cn=admin,dc=infomur,dc=es" # DN del admin LDAP
PASSWORD="Admin1" # Contraseña del admin LDAP
CREAR_USU="crear_usuarios.ldif" # Archivo .ldif para crear usuarios
MODIFICAR_USU="modificar_usuarios.ldif" # Archivo .ldif para modificar usuarios
# Función para crear un usuario
crear_usuario() {
    echo "Creando usuario..."
    ldapadd -x -D "$NOMBRE_USUARIO" -w "$PASSWORD" -f "$CREAR_USU" || {
        echo "Error al crear el usuario."
        exit 1
    }
    echo "Usuario creado exitosamente."
}

# Función para modificar un usuario
modificar_usuario() {
    echo "Modificando usuario..."
    ldapmodify -x -D "$NOMBRE_USUARIO" -w "$PASSWORD" -f "$MODIFICAR_USU" || {
        echo "Error al modificar el usuario."
        exit 1
    }
    echo "Usuario modificado exitosamente."
}

# Función para eliminar un usuario
eliminar_usuario() {
    echo "Eliminando usuario..."
    ldapdelete -x -D "$NOMBRE_USUARIO" -w "$PASSWORD" "$1" || {
        echo "Error al eliminar el usuario."
        exit 1
    }
    echo "Usuario eliminado exitosamente."
}

# Comprobar el argumento recibido
# Si se recibe menos de 2 argumentos, se muestra por pantalla el contenido
# del echo y finaliza el script indicando que ha habido un error (exit 1)
# $0 Es el nombre de este script, es decir, se referencia a sí mismo.
if [ "$#" -lt 2 ]; then
    echo "Uso: $0 {crear|modificar|eliminar} [crear_usuarios.ldif|modificar_objetos.ldif|eliminar_objetos.ldif|DN]"
    exit 1
fi

# Determinar la acción que realiza el usuario:
# Si el usuario indica como primer argumento alguna de las 3 palabras, cada
# una llamará a la función correspondiente.
# Si el usuario introduce un argumento que no sea crear, modificar o eliminar
# se irá a la parte del ELSE y terminará con código de salida 1, es decir,
# mostrará que ha ocurrido un error.
ACCION=$1
if [ "$ACCION" == "crear" ]; then
    CREAR_USU="$2"
    crear_usuario
elif [ "$ACCION" == "modificar" ]; then
    MODIFICAR_USU="$2"
    modificar_usuario
elif [ "$ACCION" == "eliminar" ]; then
    eliminar_usuario "$2"
else
    echo "Acción no válida. Usa crear, modificar o eliminar."
    exit 1
fi
