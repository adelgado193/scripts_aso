#!/bin/bash
# Archivo de log personalizado
LOGFILE="/var/log/monitorizacion.log"

# Email al que llegarán las alertas
mail_admin="3687279@alu.murciaeduca.es"


# Función para enviar alertas por correo
enviar_alerta(){
    echo "¡Alerta! $1" | mail -s "Alerta de supervisión del sistema" $mail_admin
    # Registramos la alerta en syslog también
    logger "ALERTA: $1"
}
# Si el script es detenido manualmente, ejecuta manejar_senal, que envía una alerta avisando que fue interrumpido.
manejar_senal(){
    echo "$(date '+%Y-%m-%d %H:%M:%S') - El script fue interrumpido o detenido, enviando alerta..."
    enviar_alerta "El script de monitorización fue detenido o interrumpido."
    exit 1
}

# Configurar el script para interceptar señales específicas del sistema operativo y ejecutar una acción personalizada cuando se reciban.
trap manejar_senal SIGINT SIGTERM



# Función para registrar mensajes en el archivo de log
mensaje_log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> $LOGFILE
}
sleep 3


# 1. Supervisar uso de CPU y memoria
mensaje_log "=== Supervisión de CPU y memoria ==="
sleep 2
# Mostrar los 5 procesos que más CPU y memoria consumen
top -b -o %CPU -n 1 | head -n 12 | tail -n 5 >> $LOGFILE
top -b -o %MEM -n 1 | head -n 12 | tail -n 5 >> $LOGFILE
mensaje_log "--- Fin de la supervisión de CPU y memoria ---"
sleep 2


# 2. Supervisar espacio en disco
mensaje_log "=== Supervisión de espacio en disco ==="
sleep 2
# Verificar espacio disponible en todas las particiones
df -h | awk 'NR>1 {if ($5+0 > 90) print $0}' >> $LOGFILE
mensaje_log "--- Fin de la supervisión de espacio en disco ---"
sleep 2


# 3. Supervisar logs del sistema
mensaje_log "=== Supervisión de logs del sistema ==="
sleep 2
# Revisar el syslog para errores y eventos críticos
grep -i "error" /var/log/syslog >> $LOGFILE
grep -i "critical" /var/log/syslog >> $LOGFILE
sleep 2


# Revisar el dmesg para posibles errores
dmesg | grep -i "error" >> $LOGFILE
dmesg | grep -i "critical" >> $LOGFILE

mensaje_log "--- Fin de la supervisión de logs del sistema ---"
sleep 2
mensaje_log "El proceso de monitorización ha finalizado."
