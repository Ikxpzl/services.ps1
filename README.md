# WINLOG - Panel de Auditoría Forense y Estado del Sistema

Este es un script avanzado de automatización desarrollado en **PowerShell** enfocado en la auditoría forense rápida, el control de integridad de características de Windows y la supervisión del estado del sistema en tiempo real. Está diseñado para ejecutarse de manera fluida, aislando por completo los errores de permisos y procesos protegidos del sistema operativo.

---

## 🚀 Método de Ejecución Rápida (Desde CMD)

No es necesario descargar el archivo manualmente. Puedes ejecutar el panel forense de forma remota directamente desde el **Símbolo del sistema (CMD)** introduciendo un único comando.

### Instrucciones paso a paso:

1. Haz clic derecho sobre el botón de Inicio de Windows y selecciona **Símbolo del sistema (Administrador)** o **CMD (Administrador)**.
2. Copia y pega el siguiente comando completo en la ventana negra y presiona `Enter`:

```cmd
powershell -ExecutionPolicy Bypass -Command "irm https://raw.githubusercontent.com/Ikxpzl/services.ps1/refs/heads/main/Services.ps1 | iex"
```

*Este comando descarga temporalmente el script seguro desde tu repositorio de GitHub, elude las restricciones de ejecución de la sesión actual y lo inicia de forma inmediata en la pantalla.*

---

## 📊 Características del Escaneo Forense

El panel analiza e imprime de forma visual las siguientes secciones críticas:

1. **System Boot Time:** Extrae el tiempo preciso del último arranque y calcula de forma dinámica los días, horas y minutos exactos de tiempo de actividad acumulado (`Uptime`).
2. **Connected Drives:** Muestra el sistema de archivos activo (`NTFS`, `FAT32`) de los volúmenes principales del sistema (`C:` y `D:`).
3. **Service Status con Horas de Actividad:** Lista los servicios y controladores esenciales de seguridad de Windows (`SysMain`, `DPS`, `wsearch`, etc.). Muestra la hora exacta en la que se iniciaron mapeando sus identificadores de proceso (`ProcessID`). Incluye un módulo especial para extraer de forma forzada el arranque del controlador protegido del Kernel **BAM** (*Background Activity Moderator*).
4. **Registry Checks:** Verifica el estado de políticas del sistema, tales como la disponibilidad de la consola clásica (`CMD`), el registro de bloques de comandos de PowerShell (`ScriptBlockLogging`), el almacenamiento de actividades de usuario y el estado de la tecnología `Prefetch`.
5. **Event Logs Forense:**
   * **Control del USN Journal:** Analiza los registros internos de telemetría NTFS (como el Evento 98) para detectar de forma real si un usuario ha forzado el borrado manual del diario mediante comandos de vaciado como `fsutil usn deletejournal`. Muestra un estado transparente de **"Deleted"** (si fue purgado) o **"Active"** (en condiciones normales).
   * Monitorea las marcas de tiempo del último apagado registrado (`ID 1074`), cambios bruscos en la hora del sistema operativo y el inicio del servicio de eventos de Windows (`ID 6005`).
6. **Prefetch Integrity:** Escanea la salud y la cantidad total de elementos indexados dentro del directorio de prelectura de aplicaciones de Windows.
7. **Recycle Bin:** Mapea mediante interfaces COM el estado actual de la papelera de reciclaje, mostrando el número de elementos contenidos y el nombre del último archivo enviado a la papelera.

---

## 🛠️ Notas de Estabilidad y Tolerancia a Fallos

El script ha sido estructurado siguiendo estrictas normas de estabilidad frente a caídas de consola de comandos:
* Se hace uso de una función inteligente de colores (`Write-Label`) que procesa los estados internamente, eliminando por completo los antiguos fallos de sintaxis sintáctica (`ObjectNotFoundException`).
* Si el historial de eventos (`Event Logs`) o el diario de cambios `USN Journal` han sido borrados de forma deliberada por procesos de limpieza profunda, el script no se detendrá ni colapsará; en su lugar, redireccionará la lectura y mostrará estados lógicos adaptativos como `"Deleted"`, `"Unknown"` o `"No records found"`.
