import os
import sys


# Importamos CUPS solo si estamos en Linux o macOS
if sys.platform == "darwin" or sys.platform.startswith("linux"):
    import cups


def listar_impresoras():
    """Listar todas las impresoras disponibles en el sistema."""
    if sys.platform == "darwin" or sys.platform.startswith("linux"):
        conn = cups.Connection()
        impresoras = conn.getPrinters()
        return list(impresoras.keys())
    elif sys.platform == "win32":
        try:
            resultado = os.popen("wmic printer get name").read()
            impresoras = resultado.split("\n")[1:]  # Omitimos la primera línea (encabezado)
            return [imp.strip() for imp in impresoras if imp.strip()]
        except Exception:
            return ["Error al obtener las impresoras en Windows."]
    else:
        return ["Sistema no soportado"]


def obtener_impresora_principal():
    """Obtener la impresora principal del sistema."""
    if sys.platform == "darwin" or sys.platform.startswith("linux"):
        conn = cups.Connection()
        return conn.getDefault()
    elif sys.platform == "win32":
        try:
            return os.popen("wmic printer where Default=True get Name").read().strip().split("\n")[-1]
        except Exception:
            return "No se pudo determinar la impresora predeterminada en Windows."
    else:
        return "No disponible"


def enviar_a_imprimir(archivo, impresora):
    """Enviar un archivo a la impresora para imprimir."""
    ruta_completa = os.path.join(os.getcwd(), archivo)  # Buscar el archivo en el directorio actual
    if not os.path.exists(ruta_completa):
        print("Error: El archivo no existe en el directorio actual.")
        return
   
    if sys.platform == "darwin" or sys.platform.startswith("linux"):
        conn = cups.Connection()
        conn.printFile(impresora, ruta_completa, os.path.basename(ruta_completa), {})
    elif sys.platform == "win32":
        # Usamos el Bloc de notas para imprimir el archivo en Windows
        os.system(f'notepad /p "{ruta_completa}"')
    else:
        print("No disponible en este sistema operativo.")


def listar_trabajos_impresion():
    """Listar los trabajos de impresión actuales."""
    trabajos = []
    if sys.platform == "darwin" or sys.platform.startswith("linux"):
        conn = cups.Connection()
        trabajos = conn.getJobs()
    elif sys.platform == "win32":
        try:
            resultado = os.popen("wmic printjob get JobID,DocumentName,Status").read()
            trabajos = resultado.split("\n")[1:]  # Omitimos la primera línea (encabezado)
        except Exception:
            print("Error al obtener los trabajos de impresión.")
   
    if trabajos:
        print("Trabajos de impresión actuales:")
        for idx, trabajo in enumerate(trabajos, start=1):
            if trabajo.strip():
                print(f"{idx}. {trabajo.strip()}")
        return trabajos
    else:
        print("No tienes trabajos de impresión pendientes.")
        return []


def cancelar_trabajo(trabajos):
    """Cancelar un trabajo de impresión específico."""
    if trabajos:
        try:
            # Pedir al usuario que seleccione el trabajo
            seleccion = int(input("Ingresa el número del trabajo que quieres cancelar: "))
            if 1 <= seleccion <= len(trabajos):
                trabajo_seleccionado = trabajos[seleccion - 1]
                # Extraer el ID del trabajo (por ejemplo, en CUPS)
                if sys.platform == "darwin" or sys.platform.startswith("linux"):
                    conn = cups.Connection()
                    trabajo_id = trabajo_seleccionado.split()[0]  # Asumiendo que el ID es la primera palabra
                    conn.cancelJob(trabajo_id)
                    print(f"Trabajo ID {trabajo_id} cancelado exitosamente.")
                elif sys.platform == "win32":
                    # Para Windows, supongo que el JobID está en la primera columna
                    job_id = trabajo_seleccionado.split()[0]
                    os.system(f"cancel {job_id}")
                    print(f"Trabajo ID {job_id} cancelado exitosamente.")
            else:
                print("Selección no válida.")
        except Exception as e:
            print(f"Error al cancelar el trabajo: {e}")
    else:
        print("No hay trabajos disponibles para cancelar.")


def main():
    """Función principal para interactuar con el usuario."""
    while True:
        print("\nGestión de Impresión")
        print("1. Listar impresoras")
        print("2. Enviar archivo a imprimir")
        print("3. Listar trabajos de impresión")
        print("4. Cancelar trabajo de impresión")
        print("5. Salir")
        opcion = input("Elige una opción: ")


        if opcion == "1":
            impresoras = listar_impresoras()
            print("Impresoras disponibles:")
            for imp in impresoras:
                print(f"- {imp}")
       
        elif opcion == "2":
            archivo = input("Ingresa el nombre del archivo a imprimir (debe estar en la misma carpeta): ")
            impresora = obtener_impresora_principal()
            enviar_a_imprimir(archivo, impresora)
            print(f"Archivo '{archivo}' enviado a imprimir.")
       
        elif opcion == "3":
            trabajos = listar_trabajos_impresion()
       
        elif opcion == "4":
            trabajos = listar_trabajos_impresion()
            cancelar_trabajo(trabajos)
       
        elif opcion == "5":
            print("\nGracias por usar el gestor de impresión. ¡Hasta la próxima! 😊")
            sys.exit()
       
        else:
            print("Opción no válida.")


if __name__ == "__main__":
    main()
