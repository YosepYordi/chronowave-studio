# Plan Maestro - ChronoWave Studio

Fecha: 2026-05-29  
Zona horaria de referencia: America/Lima (-05:00)  
Estado: plan maestro inicial  
Repositorio previsto: `YosepYordi/chronowave-studio`
Visibilidad actual: publico, para habilitar funciones gratuitas de GitHub como el grafo de dependencias y facilitar revision del equipo.

## 1. Vision del producto

ChronoWave Studio sera una app de edicion multitrack de video y audio. La primera version se enfocara en Android 10+ y mantendra una arquitectura que permita llevar el producto a escritorio, con Windows como primera plataforma desktop.

La app debe servir a usuarios que necesitan control real sobre video y audio, no solo plantillas casuales. El MVP debe incluir una base balanceada de timeline, audio y textos/efectos, con exportacion local a MP4 social.

## 2. Objetivos del MVP

- Permitir crear, abrir y guardar proyectos locales.
- Importar clips de video, imagenes y audio desde el dispositivo.
- Organizar clips en un timeline multitrack.
- Cortar, mover, recortar y ordenar clips con precision.
- Ajustar audio esencial: volumen, mute, fades y mezcla basica.
- Agregar textos y efectos visuales basicos.
- Previsualizar el resultado sin exportar.
- Exportar a MP4 H.264/AAC en presets sociales.
- Mantener datos locales preparados para futura sincronizacion.
- Dejar preparada la arquitectura de monetizacion sin activar anuncios reales.

## 3. Fuera de alcance inicial

- Backend, cuentas de usuario o nube obligatoria.
- Publicacion inmediata en Play Store o App Store.
- Anuncios reales en produccion.
- IA generativa, subtitulos automaticos o limpieza avanzada de audio.
- Colaboracion en tiempo real.
- Exportacion profesional avanzada como ProRes, DNxHR o flujos broadcast.
- Version desktop funcional en el primer MVP.

## 4. Plataformas

### 4.1 Android primero

La plataforma inicial sera Android 10+. Esta version equilibra alcance, APIs modernas, rendimiento multimedia y permisos de archivos menos problematicos que versiones mas antiguas.

### 4.2 Windows despues

Windows sera la primera ampliacion desktop. La arquitectura Flutter + Rust + GStreamer se elige para no atar el motor multimedia solo a Android. La version desktop no debe dictar todos los detalles del MVP movil, pero si debe influir en decisiones de modelo de proyecto, persistencia y motor multimedia.

## 5. Stack tecnologico

### 5.1 Flutter

Flutter sera responsable de:

- Interfaz movil.
- Timeline visual.
- Paneles de propiedades.
- Navegacion.
- Pantallas de importacion y exportacion.
- Integracion con servicios Dart.

Flutter no debe contener reglas pesadas del motor multimedia. Debe consumir servicios de dominio y estados claros.

### 5.2 Rust

Rust sera el nucleo para:

- Modelo interno del timeline.
- Validacion de composiciones.
- Orquestacion de preview y render.
- Puente hacia GStreamer/GES.
- Logica portable que pueda reutilizarse en Windows.

El puente Flutter-Rust se planteara con `flutter_rust_bridge` o una alternativa FFI equivalente si durante la implementacion se detecta una limitacion concreta.

### 5.3 GStreamer + GStreamer Editing Services

GStreamer/GES sera el motor de edicion y render. GES encaja con conceptos de timelines, capas, tracks, clips, transiciones y composiciones.

Para reducir riesgo inicial:

- Usar plugins conservadores primero.
- Evitar dependencias GPL o plugins con dudas comerciales durante el MVP.
- Documentar cada plugin multimedia agregado.
- Mantener exportacion inicial limitada a MP4 social.

### 5.4 Drift/SQLite

Drift/SQLite guardara metadatos locales:

- Proyectos.
- Assets importados.
- Tracks.
- Clips.
- Ajustes de audio.
- Textos.
- Efectos.
- Presets de exportacion.
- Estado de sincronizacion futura.

Los archivos multimedia reales no deben guardarse dentro de SQLite. Deben vivir en carpetas administradas por la app, con referencias estables desde la base de datos.

## 6. Modelo de datos inicial

### 6.1 Project

Representa un proyecto editable.

Campos previstos:

- `id`: identificador estable, preparado para nube futura.
- `name`: nombre visible.
- `createdAt`: fecha de creacion.
- `updatedAt`: ultima modificacion.
- `schemaVersion`: version del formato local.
- `durationMs`: duracion estimada.
- `thumbnailPath`: miniatura local opcional.
- `syncState`: `localOnly`, `pendingUpload`, `synced` o `conflict` para futuro.

### 6.2 MediaAsset

Representa un archivo importado.

Campos previstos:

- `id`.
- `projectId`.
- `type`: `video`, `audio`, `image`.
- `originalUri`.
- `localPath`.
- `displayName`.
- `durationMs`.
- `width`.
- `height`.
- `sampleRate`.
- `channels`.
- `createdAt`.
- `checksum` opcional para detectar duplicados.

### 6.3 Track

Representa una pista del timeline.

Campos previstos:

- `id`.
- `projectId`.
- `type`: `video`, `audio`, `text`.
- `name`.
- `orderIndex`.
- `muted`.
- `locked`.
- `visible`.
- `volume`.

### 6.4 Clip

Representa un segmento colocado en una pista.

Campos previstos:

- `id`.
- `trackId`.
- `assetId` opcional para textos generados.
- `startMs`.
- `durationMs`.
- `sourceInMs`.
- `sourceOutMs`.
- `zIndex`.
- `volume`.
- `fadeInMs`.
- `fadeOutMs`.
- `effectConfigJson`.
- `textConfigJson`.

## 7. Funciones del MVP

### 7.1 Timeline preciso

El timeline debe permitir:

- Zoom horizontal.
- Scroll fluido.
- Seleccion de clips.
- Arrastre de clips.
- Recorte desde inicio y fin.
- Corte en posicion del cabezal.
- Snapping basico entre clips y cabezal.
- Reordenamiento de pistas.
- Bloqueo y ocultamiento de pistas.

### 7.2 Audio esencial

El audio debe permitir:

- Mostrar waveform simplificada cuando sea viable.
- Ajustar volumen por clip.
- Ajustar volumen por pista.
- Mute por pista.
- Fade in y fade out.
- Mezcla basica en exportacion.
- Mantener sincronizacion entre audio y video.

### 7.3 Textos y efectos basicos

Textos:

- Crear texto como clip en pista dedicada.
- Editar contenido.
- Ajustar posicion, escala y opacidad.
- Definir color, fuente base y alineacion.
- Cambiar duracion en timeline.

Efectos basicos:

- Fade visual.
- Recorte/transformacion simple.
- Ajuste de brillo/contraste si GStreamer lo permite con bajo riesgo.
- Transiciones simples solo cuando no compliquen preview/export.

### 7.4 Exportacion MP4 social

Presets iniciales:

- Vertical 9:16, 720p.
- Vertical 9:16, 1080p.
- Cuadrado 1:1, 1080p.
- Horizontal 16:9, 1080p.

Parametros iniciales:

- Contenedor: MP4.
- Video: H.264 cuando este disponible con plugins seguros.
- Audio: AAC cuando este disponible con plugins seguros.
- Bitrate: perfiles conservadores por preset.
- Progreso: porcentaje y estado textual.
- Cancelacion: detener render sin corromper el proyecto.

## 8. Arquitectura por capas

### 8.1 Capa Flutter UI

Responsabilidades:

- Pantalla de inicio y proyectos recientes.
- Editor principal.
- Timeline visual.
- Inspector de clip/pista.
- Biblioteca de medios.
- Dialogo de exportacion.
- Pantalla de ajustes.

Regla: la UI no debe construir comandos GStreamer directamente.

### 8.2 Capa de dominio Dart

Responsabilidades:

- Casos de uso de proyecto.
- Coordinacion entre persistencia y motor Rust.
- Validacion de acciones de usuario.
- Adaptadores de estado para la UI.

Servicios previstos:

- `ProjectRepository`.
- `MediaAssetService`.
- `TimelineService`.
- `ExportService`.
- `MonetizationService`.

### 8.3 Puente Rust

Responsabilidades:

- Recibir snapshots de timeline.
- Validar composiciones.
- Traducir timeline a estructuras GES.
- Exponer preview, render, progreso y errores.
- Mantener API estable hacia Flutter.

### 8.4 Motor GStreamer/GES

Responsabilidades:

- Construir pipelines.
- Manejar timeline multimedia.
- Renderizar exportaciones.
- Reportar errores recuperables.

### 8.5 Persistencia local

Responsabilidades:

- Guardar metadatos en SQLite.
- Mantener rutas locales de assets.
- Versionar esquema.
- Preparar campos para sincronizacion futura.

## 9. Monetizacion preparada, no activa

El MVP no debe mostrar anuncios reales. La arquitectura dejara una interfaz de monetizacion con estado desactivado.

Futuro AdMob:

- Usar IDs de prueba durante desarrollo.
- Solicitar consentimiento cuando aplique.
- Agregar politica de privacidad antes de activar anuncios reales.
- Evitar banners dentro del timeline.
- Evaluar anuncios recompensados en momentos no destructivos, por ejemplo exportaciones extra, plantillas o quitar marca de agua si el modelo de negocio lo requiere.

## 10. Roadmap por fases

### Fase 0 - Base del repositorio

- Inicializar Git.
- Publicar repositorio publico.
- Documentar README y plan maestro.
- Mantener flujo de reportes IA.

### Fase 1 - Esqueleto Flutter

- Crear proyecto Flutter.
- Configurar estructura de carpetas.
- Agregar navegacion base.
- Crear tema visual inicial.
- Definir pantallas vacias: proyectos, editor, exportacion, ajustes.

### Fase 2 - Persistencia local

- Agregar Drift/SQLite.
- Crear tablas de proyectos, assets, tracks y clips.
- Implementar repositorios.
- Crear tests de modelo y persistencia.

### Fase 3 - Timeline UI

- Implementar timeline visual.
- Agregar tracks y clips simulados.
- Implementar seleccion, zoom, scroll y snapping basico.
- Conectar timeline con datos reales.

### Fase 4 - Rust bridge

- Agregar crate Rust.
- Configurar puente Flutter-Rust.
- Exponer API minima de diagnostico.
- Enviar snapshot de timeline desde Flutter a Rust.

### Fase 5 - GStreamer/GES

- Integrar GStreamer en Rust.
- Probar pipeline minimo.
- Crear composicion GES simple con un clip.
- Reportar errores al lado Flutter.

### Fase 6 - Preview

- Generar preview local de timeline.
- Sincronizar cabezal de reproduccion.
- Manejar play, pause y seek.
- Medir rendimiento en Android.

### Fase 7 - Exportacion

- Implementar exportacion MP4 social.
- Agregar presets.
- Mostrar progreso.
- Permitir cancelacion.
- Validar archivo exportado.

### Fase 8 - Audio, textos y efectos

- Agregar waveform basica.
- Implementar volumen, mute y fades.
- Crear clips de texto.
- Agregar efectos basicos seguros.

### Fase 9 - Monetizacion preparada

- Crear interfaz de monetizacion desactivada.
- Documentar puntos futuros de AdMob.
- Mantener IDs reales fuera del repositorio.

### Fase 10 - Preparacion Windows

- Revisar compatibilidad Flutter desktop.
- Revisar empaquetado GStreamer en Windows.
- Validar que el modelo Rust no depende de Android.
- Crear plan especifico de port desktop.

## 11. Validacion esperada por fase

- Fase 0: `git status --short`, `git remote -v`, `gh repo view`.
- Fase 1: `flutter test`, analisis estatico y ejecucion en emulador si existe.
- Fase 2: tests de repositorios y migraciones.
- Fase 3: pruebas manuales de timeline y tests de reglas de snapping.
- Fase 4: prueba de ida y vuelta Flutter-Rust.
- Fase 5: prueba de pipeline minimo GStreamer.
- Fase 6: preview con clip corto real.
- Fase 7: exportacion MP4 reproducible.
- Fase 8: prueba de mezcla audio/texto/efecto.
- Fase 9: confirmar que no hay anuncios reales ni secretos en repo.
- Fase 10: prueba de compilacion desktop o reporte de bloqueo.

## 12. Riesgos conocidos

### 12.1 Empaquetado GStreamer en Android

Puede requerir trabajo nativo, configuracion NDK y pruebas por arquitectura. Es el riesgo tecnico principal del stack elegido.

### 12.2 Rendimiento

Preview y exportacion multitrack pueden variar mucho por dispositivo. El MVP debe usar clips cortos y presets conservadores antes de prometer cargas pesadas.

### 12.3 Licencias de codecs/plugins

GStreamer es adecuado para desarrollo abierto, pero cada plugin y codec debe revisarse antes de uso comercial o publicacion.

### 12.4 Publicacion en tiendas

Desarrollar localmente puede ser gratis, pero publicar en tiendas puede requerir cuentas, pagos, politicas y revisiones.

### 12.5 Privacidad futura

Si se activa nube, cuentas o anuncios, se necesitara politica de privacidad, consentimiento y manejo cuidadoso de archivos personales.

## 13. Reglas para siguientes IAs

- Leer `AGENTS.md` antes de modificar.
- Revisar `docs/reportes/INDICE.md` y el reporte mas reciente.
- No crear carpetas internas de herramienta dentro de `docs/`.
- No agregar `.gitignore` sin entender el stack real o sin que aparezca una necesidad concreta.
- No subir secretos, caches, dependencias ni resultados generados.
- Registrar todo cambio en `docs/reportes/`.
- Si una decision tecnica cambia este plan, crear un reporte explicando el motivo.
