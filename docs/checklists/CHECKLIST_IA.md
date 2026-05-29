# Checklist obligatorio para IAs

Usa este checklist antes de cerrar cualquier tarea que haya modificado archivos.

## Antes de empezar

- [ ] Lei `AGENTS.md`.
- [ ] Revise `git status --short`.
- [ ] Identifique la rama con `git branch --show-current`.
- [ ] Confirme remoto con `git remote -v`.
- [ ] Si no habia cambios locales pendientes, intente `git pull --ff-only`.
- [ ] Si habia cambios locales, conflicto, falta de Git o falta de remoto, lo anote para el reporte antes de modificar.
- [ ] Lei `docs/reportes/README.md`.
- [ ] Revise `docs/reportes/INDICE.md`.
- [ ] Lei los reportes recientes relacionados con los archivos o capas que voy a tocar.
- [ ] Entendi el pedido actual del usuario y el alcance de la tarea.

## Antes de terminar

- [ ] Revise los archivos que cambie.
- [ ] Cree un reporte nuevo en `docs/reportes/`.
- [ ] Use el formato `YYYY-MM-DD-HHMM_<ia-o-integrante>_<area>_<resumen-corto>.md`.
- [ ] Complete todas las secciones relevantes de la plantilla.
- [ ] Actualice `docs/reportes/INDICE.md`.
- [ ] Ejecute validacion tecnica o documente por que no aplica.
- [ ] Revise si hay archivos dudosos para subir y si `.gitignore` necesita una propuesta futura.
- [ ] Anote riesgos, pendientes o ausencia de riesgos conocidos.
- [ ] Pregunte al humano si quiere enviar los cambios a GitHub, salvo que no aplique y explique por que.
- [ ] Prepare una respuesta final que mencione el reporte creado y la validacion realizada.

## Cierre sugerido para la respuesta final

```text
Reporte creado: docs/reportes/<archivo>.md
Validacion: <comando/revision realizada o razon por la que no aplica>
Pendientes o riesgos: <resumen breve>
GitHub: <pregunta al humano para enviar cambios o razon por la que no aplica>
Archivos dudosos / .gitignore: <resumen breve o "sin hallazgos">
```
