# Reportes de modificaciones por IA

Esta carpeta guarda el historial operativo del proyecto. Cada reporte debe permitir que otra IA entienda que cambio, por que cambio, como se valido y que debe cuidar despues.

## Como orientarte rapido

1. Lee `AGENTS.md`.
2. Revisa el estado local de Git y sincroniza con GitHub segun `AGENTS.md`.
3. Revisa `docs/reportes/INDICE.md`.
4. Abre los reportes mas recientes de la capa que vas a modificar.
5. Confirma los archivos reales antes de asumir que el reporte sigue vigente.

## Formato de nombre

```text
YYYY-MM-DD-HHMM_<ia-o-integrante>_<area>_<resumen-corto>.md
```

Areas sugeridas:

- `frontend`
- `backend`
- `database`
- `infra`
- `docs`
- `tests`
- `mixto`
- `analisis`

Usa palabras cortas en minusculas y guiones para el resumen.

## Reglas de calidad

- Un reporte debe decir la verdad aunque el resultado sea parcial.
- Si una prueba falla, anota el comando y el error resumido.
- Si no se ejecuto validacion, explica la razon concreta.
- Si no se pudo actualizar desde GitHub antes de modificar, anota la razon concreta.
- Si terminaste cambios, registra que preguntaste al humano si desea enviarlos a GitHub.
- Evita frases vagas como "se hicieron mejoras" sin archivos ni detalle.
- No edites reportes antiguos salvo para corregir errores tipograficos evidentes. Si una decision cambia, crea un reporte nuevo.

## Lectura recomendada para otra IA

Para continuar una tarea, lee primero los reportes mas recientes y busca estas secciones:

- `Resumen para la siguiente IA`
- `Riesgos y pendientes`
- `Validacion realizada`
- `Decisiones tomadas`
