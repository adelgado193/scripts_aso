import os
import platform


def establecer_conexion():
    sistema = platform.system()


    if sistema == "Windows":
        print("Conexión remota en Windows (MSTSC).")
        host = input("Introduce la dirección IP o nombre del host: ")
        comando = f"mstsc /v:{host} /f"
        os.system(comando)


    elif sistema == "Linux" or sistema == "Darwin":
        print("Conexión remota en Ubuntu (SSH).")
        host = input("Introduce la dirección IP o nombre del host: ")
        usuario = input("Introduce el nombre de usuario: ")
        contrasena = input("Introduce la contraseña: ")
        comando = f"ssh {usuario}@{host}"
        os.system(comando)


    else:
        print("Sistema no compatible para esta operación.")


if __name__ == "__main__":
    establecer_conexion()
