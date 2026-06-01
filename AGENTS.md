# Instrucciones obligatorias para IAs contribuyentes

Este proyecto puede ser modificado por varios contribuyentes que trabajaran con IA. La regla mas importante es que cada modificacion debe dejar contexto suficiente para que otra IA pueda continuar sin adivinar.

## Regla principal

Toda IA que cree, edite, elimine, mueva o configure archivos del proyecto debe crear un reporte fechado antes de terminar su turno.

Sin reporte, la modificacion se considera incompleta.

> [!IMPORTANT]
> **Subida Obligatoria de Documentación (docs/):**
> Al finalizar el turno, toda modificación en la documentación (todo lo contenido dentro de la carpeta `docs/`, incluyendo reportes de IA e índices) se debe subir (`push`) obligatoriamente a la rama principal `main` en `origin` de forma automática, sin requerir consulta ni aprobación previa del humano.

## Sincronizacion con GitHub

Al inicio de una tarea, antes de modificar archivos, la IA debe intentar trabajar sobre la version mas reciente del repositorio remoto.

Flujo recomendado:

1. Ejecutar `git status --short` para revisar si hay cambios locales.
2. Ejecutar `git branch --show-current` para identificar la rama actual.
3. Ejecutar `git remote -v` para confirmar que existe remoto de GitHub.
4. Si no hay cambios locales pendientes, ejecutar `git pull --ff-only`.
5. Si hay cambios locales pendientes, no hacer `pull` a ciegas. Revisar el estado y pedir instrucciones al humano si esos cambios no son claramente propios.
6. Si el `pull` falla por divergencia, conflictos, falta de Git, falta de remoto o autenticacion, detenerse y documentar el bloqueo en el reporte.

La IA no debe usar comandos que reescriban historia o descarten trabajo, como `reset --hard`, `checkout -- .`, `clean -fd`, `push --force` o equivalentes, salvo que el humano lo pida explicitamente y entienda el riesgo.

Al final de una tarea, despues de crear el reporte y validar los cambios, la IA debe preguntar al humano si quiere enviar los cambios de código a GitHub. No debe hacer `push` automatico de código de producción o desarrollo sin autorizacion.

**Excepción obligatoria para documentación:** Toda modificación en la documentación (todo lo contenido dentro de la carpeta `docs/`, incluyendo reportes de IA e índices) se debe subir (push) obligatoriamente a la rama principal `main` en `origin` de forma automática tan pronto como finalice la tarea, sin requerir consulta previa.

Si el humano aprueba enviar los cambios de código a GitHub, la IA debe confirmar o proponer:

- Rama destino.
- Archivos a incluir.
- Mensaje de commit.
- Si se hara `push` directo o pull request.

## Aprobación de Pull Requests por Consenso de IAs

Para que un Pull Request (PR) sea fusionado a la rama principal `main`, se requiere una votación y aprobación por consenso de las IAs activas en el proyecto:

1. **Revisión de PRs pendientes:** Toda IA que se active en el proyecto debe consultar si existen Pull Requests abiertos en el repositorio de GitHub.
2. **Evaluación y Voto:** Para cada PR pendiente, la IA debe realizar una validación técnica local de la rama correspondiente (ejecutando tests, análisis estático y compilación si es posible).
3. **Registro de Voto en GitHub:** La IA debe dejar un comentario en el PR (usando la herramienta `add_issue_comment`) con el formato:
   * **Voto:** A favor (APROBADO) o en contra (RECHAZADO).
   * **Justificación técnica:** Explicando qué pruebas realizó, qué hallazgos obtuvo y el motivo de su decisión.
4. **Consenso para Merge:** El umbral requerido para la aprobación es la mitad de los votos de las IAs activas en los últimos 7 días más uno (mitad + 1). La IA que emita el voto a favor que alcance o supere este umbral decisivo será la responsable directa de realizar la fusión (`merge`) de la rama del PR hacia la rama principal `main` y subir los cambios al repositorio remoto. En caso de no alcanzarse la mayoría, el PR permanecerá abierto a la espera de revisiones adicionales.

## Uso de .gitignore y archivos que se suben

La IA debe cuidar que el repositorio solo reciba archivos necesarios para reconstruir, ejecutar, revisar y entender el proyecto.

Reglas generales:

- No subir secretos: `.env`, tokens, claves API, credenciales, llaves privadas, certificados privados ni configuraciones con datos sensibles.
- No subir dependencias instaladas o generadas: `node_modules/`, paquetes descargados, caches de gestores de dependencias o carpetas equivalentes.
- No subir resultados de compilacion o ejecucion generados automaticamente: `target/`, `build/`, `dist/`, `.next/`, `.angular/`, logs, temporales, caches o reportes generados por herramientas.
- No subir configuraciones personales del IDE o del equipo, salvo que sean convenciones compartidas del proyecto y el humano lo apruebe.
- Si el proyecto necesita variables de entorno o configuracion local, subir solo ejemplos seguros como `.env.example`, `application-example.properties` o archivos equivalentes sin secretos reales.
- Si aparece un archivo dudoso en `git status --short`, la IA debe explicar que es y preguntar antes de incluirlo.
- Si falta `.gitignore` o no cubre el stack real, la IA puede proponer cambios, pero no debe inventar reglas amplias sin entender primero la tecnologia del proyecto.
- La IA no debe modificar `.gitignore` ni crear uno nuevo cuando el humano haya pedido explicitamente no hacerlo.

Regla corta: se sube lo necesario para que otra persona o IA trabaje el proyecto; no se sube lo privado, lo local ni lo generado automaticamente.

## Antes de modificar

1. Lee este archivo completo.
2. Revisa el estado Git local y sincroniza con GitHub siguiendo la seccion `Sincronizacion con GitHub`.
3. Lee `docs/reportes/README.md`.
4. Revisa `docs/reportes/INDICE.md`.
5. Abre los reportes mas recientes relacionados con la capa o carpeta que vas a tocar.
6. Identifica si hay cambios previos, riesgos, decisiones o pendientes que afecten tu tarea.

## Durante la modificacion

- Mantente dentro del alcance pedido por el usuario.
- No borres reportes anteriores.
- No crees carpetas internas de herramientas dentro de `docs/`, como `docs/superpowers/`, `docs/claude/`, `docs/gemini/`, `docs/codex/` o similares, salvo que el humano lo pida explicitamente.
- Si una IA necesita guardar planes, specs, notas o borradores propios, debe usar `.ai/<nombre-ia>/` como zona de trabajo interna. Ejemplos: `.ai/codex/plans/`, `.ai/claude/specs/`, `.ai/gemini/tmp/`.
- Solo coloca en `docs/` documentacion oficial del proyecto que deba leer un humano o una IA futura como fuente de verdad.
- No ocultes errores, pruebas fallidas ni validaciones no ejecutadas.
- Si modificas varias capas, describe cada capa por separado en el reporte.
- Si cambias una decision tomada por otra IA, explica por que.
- Si encuentras algo riesgoso pero no lo arreglas, dejalo anotado para la siguiente IA.

## Reporte obligatorio

Crea un archivo nuevo en `docs/reportes/` usando este formato:

```text
YYYY-MM-DD-HHMM_<ia-o-integrante>_<area>_<resumen-corto>.md
```

Ejemplo:

```text
2026-05-24-0930_nombre-ia_backend_login.md
```

Usa la hora local del equipo cuando sea posible. En este proyecto se prefiere la zona horaria `America/Lima` o el offset visible, por ejemplo `-05:00`.

El reporte debe seguir `docs/reportes/PLANTILLA_REPORTE_IA.md` y debe incluir como minimo:

- Fecha y hora de la modificacion.
- IA o herramienta usada.
- Integrante responsable en formato: `Nombre Real (@UsuarioGitHub)`, si se conoce (por ejemplo: `Yosep Yordi (@YosepYordi)`).
- Objetivo de la tarea.
- Reportes previos leidos.
- Archivos creados, modificados o eliminados.
- Resumen claro de los cambios.
- Decisiones tomadas y motivo.
- Validacion realizada con comandos, revision manual o razon por la que no se valido.
- Riesgos conocidos.
- Instrucciones para la siguiente IA.

Despues de crear el reporte, agrega una fila nueva al inicio de la tabla en `docs/reportes/INDICE.md`.

## Checklist obligatorio de cierre

Antes de responder al usuario, completa `docs/checklists/CHECKLIST_IA.md`.

La respuesta final de la IA debe mencionar:

- Que reporte creo.
- Que validacion ejecuto o por que no ejecuto validacion tecnica.
- Cualquier riesgo o pendiente relevante.
- Si pregunto al humano por enviar los cambios de código a GitHub o por qué no aplica (recordando que para la documentación en `docs/` el push a `main origin` es automático, obligatorio y ya se realizó sin consultar).
- Si detecto archivos dudosos para subir o reglas de `.gitignore` que deban revisarse.

## Si solo investigaste

Si no modificaste archivos, no es obligatorio crear reporte. Si la investigacion deja una decision importante, un bloqueo o informacion que otra IA necesitara, crea un reporte de tipo `analisis`.

## Fuente de verdad

`AGENTS.md` es la fuente principal de instrucciones para IAs. Los archivos `CLAUDE.md` y `GEMINI.md`, si existen, deben apuntar a este archivo y no contradecirlo.
