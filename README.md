# ChronoWave Studio

Fecha del proyecto: 2026-05-29  
Zona horaria de referencia: America/Lima (-05:00)

ChronoWave Studio es una app de edicion multitrack de video y audio pensada para iniciar en Android y crecer despues hacia escritorio, con Windows como primera ampliacion. El objetivo es construir una base tecnica seria para edicion local: timeline preciso, mezcla de audio esencial, textos/efectos basicos y exportacion MP4 para formatos sociales.

## Estado actual

Este repositorio esta en fase inicial de planificacion tecnica. Todavia no contiene codigo de aplicacion, motor multimedia ni proyecto Flutter generado. La prioridad actual es dejar una base documentada para que varias IAs o integrantes puedan colaborar sin perder contexto.

El repositorio se mantiene publico para habilitar funciones gratuitas de GitHub como el grafo de dependencias y facilitar revision del equipo. No deben subirse secretos, credenciales, archivos privados, dependencias instaladas ni artefactos generados.

## Producto objetivo

- App movil Android primero, compatible desde Android 10.
- Expansion futura a escritorio, empezando por Windows.
- Editor multitrack balanceado: video, audio, textos y efectos basicos desde el MVP.
- Procesamiento local en el dispositivo, sin backend obligatorio al inicio.
- Proyectos locales preparados para sincronizacion o nube futura.
- Exportacion inicial orientada a redes sociales: MP4 H.264/AAC en 720p/1080p, 9:16, 1:1 y 16:9.

## Stack definido

- UI y app movil: Flutter.
- Nucleo multimedia y de proyecto: Rust.
- Motor de timeline/render: GStreamer + GStreamer Editing Services (GES).
- Persistencia local: Drift/SQLite.
- Archivos de usuario: almacenamiento local administrado por la app.
- Monetizacion: preparada para AdMob, pero sin anuncios activos en el MVP.

## Arquitectura prevista

ChronoWave Studio se construira por capas para mantener separadas la interfaz, el dominio del editor y el motor multimedia:

1. Flutter presenta la interfaz, timeline, controles, bibliotecas de medios y pantallas de exportacion.
2. Dart mantiene el estado de UI, validaciones de flujo y adaptadores hacia persistencia.
3. Rust administra el modelo de proyecto, timeline, comandos de preview/render y puente hacia GStreamer.
4. GStreamer/GES ejecuta composiciones multimedia, preview y exportacion.
5. Drift/SQLite guarda metadatos de proyectos, assets, tracks, clips, presets y estado local.

## Documentacion principal

- Plan maestro: `docs/planes/2026-05-29-plan-maestro-chronowave-studio.md`
- Instrucciones para IAs: `AGENTS.md`
- Indice de reportes: `docs/reportes/INDICE.md`
- Plantilla de reportes: `docs/reportes/PLANTILLA_REPORTE_IA.md`
- Checklist de cierre: `docs/checklists/CHECKLIST_IA.md`

## Colaboracion con IA

Antes de contribuir, cualquier IA o integrante debe leer `AGENTS.md`. Este proyecto exige reportes fechados para cada modificacion de archivos. Los reportes deben permitir que otra IA entienda que cambio, por que se cambio, como se valido y que queda pendiente.

## Costos, licencias y publicacion

El desarrollo local se plantea con herramientas gratuitas y abiertas. Aun asi, ChronoWave Studio esta pensado como producto comercial futuro, por lo que antes de publicar o monetizar se deberan revisar:

- Licencias de plugins/codecs usados por GStreamer.
- Requisitos de Google Play, App Store o tiendas de escritorio.
- Politica de privacidad y consentimiento si se activa AdMob.
- Manejo de archivos personales de video/audio en el dispositivo.

En el MVP no se activaran anuncios reales, no se usara nube obligatoria y no se asumiran codecs avanzados sin evaluacion tecnica y legal previa.
