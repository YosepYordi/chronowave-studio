# Reporte IA - YYYY-MM-DD HH:mm - area - resumen

## 1\. Metadatos

* Fecha y hora local:
* Zona horaria:
* IA o herramienta:
* Integrante responsable: (Obtener del contexto de sesion o preguntar al usuario. No copiar ejemplos. Si no se puede determinar, escribir `Desconocido`.)
* Estado de la tarea: terminado | parcial | bloqueado
* Area o capa principal:
* Solicitud original del usuario:

## 2\. Sincronizacion con GitHub antes de modificar

|Revision|Resultado|Evidencia|
|-|-|-|
|`git status --short`|ejecutado|Resumen del estado local|
|`git branch --show-current`|ejecutado|Rama actual|
|`git remote -v`|ejecutado|Remoto confirmado o razon si no existe|
|`git pull --ff-only`|ejecutado|Resultado o razon concreta si no se ejecuto|

Si no hay Git disponible, no hay remoto configurado, hay cambios locales ajenos o aparece conflicto, explica el bloqueo y como se procedio.

## 3\. Contexto revisado antes de modificar

* Reportes leidos:
* Archivos o carpetas revisadas:
* Supuestos usados:

## 4\. Resumen para la siguiente IA

Explica en 3 a 7 lineas que cambio y que debe saber otra IA antes de tocar esta parte del proyecto.

## 5\. Cambios realizados

|Tipo|Archivo o carpeta|Detalle|
|-|-|-|
|creado|ruta/del/archivo|Que se agrego y por que|
|modificado|ruta/del/archivo|Que se cambio y por que|
|eliminado|ruta/del/archivo|Que se retiro y por que|

Elimina las filas que no apliquen y agrega las necesarias.

## 6\. Decisiones tomadas

|Decision|Motivo|Alternativas consideradas|
|-|-|-|
|Decision concreta|Razon verificable|Opciones descartadas o "ninguna"|

## 7\. Validacion realizada

|Validacion|Resultado|Evidencia|
|-|-|-|
|Comando, revision manual o inspeccion|Paso, fallo o no ejecutado|Salida resumida, archivo revisado o razon concreta|

## 8\. GitHub al finalizar

* Se pregunto al humano si quiere enviar los cambios a GitHub: si | no | no aplica
* Respuesta del humano, si existe:
* Rama sugerida:
* Mensaje de commit sugerido:
* Metodo sugerido: push directo | pull request | no decidido

## 9\. Riesgos y pendientes

* Riesgo o pendiente 1:
* Riesgo o pendiente 2:

Si no hay riesgos conocidos, escribe: `No hay riesgos conocidos despues de la validacion realizada.`

## 10\. Instrucciones para la siguiente IA

* Siguiente paso recomendado:
* Archivos que conviene leer primero:
* Cuidado especial:

## 11\. Checklist de cierre

* \[ ] Actualice `docs/reportes/INDICE.md`.
* \[ ] Declare todos los archivos que cambie.
* \[ ] Registre validacion o razon concreta si no se valido.
* \[ ] Registre el estado de sincronizacion Git/GitHub.
* \[ ] Pregunte al humano si quiere enviar los cambios a GitHub o explique por que no aplica.
* \[ ] Anote riesgos y pendientes.
* \[ ] Mencione este reporte en la respuesta final al usuario.

