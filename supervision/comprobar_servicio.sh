#!/bin/bash
# Script para comprobar si un servicio está corriendo

SERVICIO="atd" # Nombre del servicio que vamos a supervisar
LOGFILE="/home/angel/supervision/servicio_comprobado.log"  # Archivo de log donde se registrará el resultado

# Comprobar si el servicio está corriendo
if systemctl is-active --quiet $SERVICIO; then
    echo "$(date) - El servicio $SERVICIO está corriendo." >> $LOGFILE
else
    echo "$(date) - El servicio $SERVICIO NO está corriendo." >> $LOGFILE
fi

