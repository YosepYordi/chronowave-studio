# Checklist obligatorio para IAs

Usa este checklist antes de cerrar cualquier tarea que haya modificado archivos.

## Antes de empezar

- [x] Lei `AGENTS.md`.
- [x] Revise `git status --short`.
- [x] Identifique la rama con `git branch --show-current`.
- [x] Confirme remoto con `git remote -v`.
- [x] Si no habia cambios locales pendientes, intente `git pull --ff-only`.
- [x] Si habia cambios locales, conflicto, falta de Git o falta de remoto, lo anote para el reporte antes de modificar.
- [x] Lei `docs/reportes/README.md`.
- [x] Revise `docs/reportes/INDICE.md`.
- [x] Lei los reportes recientes relacionados con los archivos o capas que voy a tocar.
- [x] Entendi el pedido actual del usuario y el alcance de la tarea.

## Antes de terminar

- [x] Revise los archivos que cambie.
- [x] Cree un reporte nuevo en `docs/reportes/`.
- [x] Use el formato `YYYY-MM-DD-HHMM_<ia-o-integrante>_<area>_<resumen-corto>.md`.
- [x] Complete todas las secciones relevantes de la plantilla.
- [x] Actualice `docs/reportes/INDICE.md`.
- [x] Ejecute validacion tecnica o documente por que no aplica.
- [x] Revise si hay archivos dudosos para subir y si `.gitignore` necesita una propuesta futura.
- [x] Anote riesgos, pendientes o ausencia de riesgos conocidos.
- [x] Pregunte al humano si quiere enviar los cambios a GitHub, salvo que no aplique y explique por que.
- [x] Prepare una respuesta final que mencione el reporte creado y la validacion realizada.

## Cierre sugerido para la respuesta final

```text
Reporte creado: docs/reportes/<archivo>.md
Validacion: <comando/revision realizada o razon por la que no aplica>
Pendientes o riesgos: <resumen breve>
GitHub: <pregunta al humano para enviar cambios o razon por la que no aplica>
Archivos dudosos / .gitignore: <resumen breve o "sin hallazgos">
```
