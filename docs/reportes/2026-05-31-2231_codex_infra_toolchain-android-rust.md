# Reporte IA - 2026-05-31 22:31 - infra - toolchain Android Rust

## 1. Metadatos

* Fecha y hora local: 2026-05-31 22:31
* Zona horaria: America/Lima (-05:00)
* IA o herramienta: Codex
* Integrante responsable: Yosep Yordi / usuario solicitante
* Estado de la tarea: terminado
* Area o capa principal: infra / toolchain / Android / Rust / FFI
* Solicitud original del usuario: "Pendientes principales: instalar/configurar Android SDK, instalar Rust/Cargo y compilar chronowave_core real para que el puente deje de usar fallback. HAZ TODO ESTO"

## 2. Sincronizacion con GitHub antes de modificar

|Revision|Resultado|Evidencia|
|-|-|-|
|`git status --short`|ejecutado|La rama `codex/ffi-timeline-snapshot` tenia cambios locales del avance FFI anterior.|
|`git branch --show-current`|ejecutado|Rama actual: `codex/ffi-timeline-snapshot`.|
|`git remote -v`|ejecutado previamente|`origin` apunta a `https://github.com/YosepYordi/chronowave-studio.git`.|
|`git pull --ff-only`|no ejecutado en este turno|No se ejecuto por cambios locales propios ya presentes en la rama de trabajo.|

## 3. Contexto revisado antes de modificar

* Reportes leidos: `docs/reportes/2026-05-31-2152_codex_mixto_ffi-timeline-snapshot.md` y reportes recientes de Fase 1.
* Archivos o carpetas revisadas: `lib/src/core/ffi/chronowave_ffi.dart`, `test/core/ffi/chronowave_ffi_test.dart`, `rust/chronowave_core/Cargo.toml`, `rust/chronowave_core/src/lib.rs`, configuracion local de Flutter/Android/Rust.
* Supuestos usados: el entorno local debe quedar funcional para compilar APK debug y para cargar la DLL real de Rust desde `rust/target/release` durante validaciones de escritorio/tests.

## 4. Resumen para la siguiente IA

Se instalaron Rust/Cargo mediante `Rustlang.Rustup`, Android SDK command-line tools en `%LOCALAPPDATA%/Android/Sdk`, paquetes `platform-tools`, `platforms;android-36`, `build-tools;36.0.0` y CMake 3.22.1 instalado automaticamente durante el build. Tambien se instalo Microsoft OpenJDK 17 y Flutter quedo configurado con ese JDK para evitar el fallo de Gradle con Java 25. El crate `chronowave_core` compila en release y genera `rust/target/release/chronowave_core.dll`; el puente Flutter ahora la busca localmente antes del fallback. La prueba nativa con `CHRONOWAVE_REQUIRE_NATIVE_FFI=true` cargo la DLL real y ejecuto `process_timeline_snapshot`.

## 5. Cambios realizados

|Tipo|Archivo o carpeta|Detalle|
|-|-|-|
|modificado|`lib/src/core/ffi/chronowave_ffi.dart`|Agrega busqueda de `CHRONOWAVE_CORE_LIBRARY` y de DLL local en `rust/target/release` / `debug` antes de caer a fallback.|
|creado|`test/core/ffi/chronowave_ffi_native_test.dart`|Prueba opcional que exige FFI nativo real cuando `CHRONOWAVE_REQUIRE_NATIVE_FFI=true`.|
|creado|`docs/reportes/2026-05-31-2231_codex_infra_toolchain-android-rust.md`|Reporte obligatorio de instalacion/configuracion de toolchains.|
|modificado|`docs/reportes/INDICE.md`|Agrega este reporte al inicio del indice.|
|configurado local|Android SDK|Instalado en `C:\Users\USUARIO\AppData\Local\Android\Sdk`, con licencias aceptadas y Flutter apuntando a esa ruta.|
|configurado local|Rust toolchain|Instalado `stable-x86_64-pc-windows-msvc` con `cargo 1.96.0` y `rustc 1.96.0`.|
|configurado local|JDK|Instalado Microsoft OpenJDK 17 y configurado en Flutter como `jdk-dir`.|

## 6. Decisiones tomadas

|Decision|Motivo|Alternativas consideradas|
|-|-|-|
|Instalar Android command-line tools en lugar de Android Studio completo|Cumple lo necesario para Flutter/Gradle con menor peso y sin abrir IDE.|Instalar Android Studio via winget; descartado por ser mas pesado.|
|Fijar Flutter a JDK 17|El build con Java 25 fallo con `What went wrong: 25`; JDK 17 es compatible con Gradle/Android toolchain.|Seguir con Java 25; descartado por fallo real de Gradle.|
|No versionar `build/` ni `rust/target/`|Son artefactos generados e ignorados por `.gitignore`; se pueden reconstruir localmente.|Subir APK/DLL compilados; descartado por regla del proyecto de no subir artefactos generados.|
|Agregar busqueda local de DLL al puente|Permite que el desarrollo en Windows use Rust real despues de `cargo build --release` sin copiar binarios al repo.|Depender solo de `PATH`; descartado por fragilidad.|

## 7. Validacion realizada

|Validacion|Resultado|Evidencia|
|-|-|-|
|`flutter --no-version-check doctor -v`|paso|`No issues found`; Android SDK 36 y JDK 17 detectados, licencias aceptadas.|
|`cargo test --manifest-path rust\chronowave_core\Cargo.toml`|paso|5 tests Rust pasaron.|
|`cargo build --manifest-path rust\chronowave_core\Cargo.toml --release`|paso|Genero `rust/target/release/chronowave_core.dll` de 121344 bytes.|
|`CHRONOWAVE_REQUIRE_NATIVE_FFI=true flutter --no-version-check test test\core\ffi\chronowave_ffi_native_test.dart`|paso|Cargo Rust FFI real, imprimio `Rust [chronowave_core] FFI recibio snapshot (637 bytes).` y paso.|
|`flutter --no-version-check analyze`|paso|`No issues found!`.|
|`flutter --no-version-check test`|paso|`+11: All tests passed!`.|
|`flutter --no-version-check build apk --debug`|paso|Genero `build/app/outputs/flutter-apk/app-debug.apk` de 158964388 bytes.|

## 8. GitHub al finalizar

* Se pregunto al humano si quiere enviar los cambios a GitHub: si, en la respuesta final.
* Respuesta del humano, si existe: pendiente.
* Rama sugerida: `codex/ffi-timeline-snapshot`.
* Mensaje de commit sugerido: `feat: connect Flutter timeline snapshots to native Rust FFI`.
* Metodo sugerido: commit, push de rama y Pull Request hacia `main`.

## 9. Riesgos y pendientes

* Riesgo o pendiente 1: la DLL de Windows y el APK debug son artefactos generados e ignorados; otra maquina debera ejecutar `cargo build --release` y `flutter build apk --debug` para regenerarlos.
* Riesgo o pendiente 2: el puente carga Rust real en Windows local; para Android aun falta empaquetar `libchronowave_core.so` por ABI dentro del build Android antes de usar FFI real en dispositivo.
* Riesgo o pendiente 3: Java 25 sigue instalado, pero Flutter quedo configurado para JDK 17; si se borra esa configuracion, Gradle podria volver a fallar.

## 10. Instrucciones para la siguiente IA

* Siguiente paso recomendado: automatizar el empaquetado Android de `libchronowave_core.so` por ABI y conectar el FFI nativo en dispositivo real.
* Archivos que conviene leer primero: `lib/src/core/ffi/chronowave_ffi.dart`, `test/core/ffi/chronowave_ffi_native_test.dart`, `rust/chronowave_core/src/lib.rs`, `android/app/build.gradle.kts`.
* Cuidado especial: no subir `build/`, `rust/target/`, APKs, DLLs o caches; estan generados y deben permanecer fuera de Git.

## 11. Checklist de cierre

* [x] Actualice `docs/reportes/INDICE.md`.
* [x] Declare todos los archivos que cambie.
* [x] Registre validacion o razon concreta si no se valido.
* [x] Registre el estado de sincronizacion Git/GitHub.
* [x] Pregunte al humano si quiere enviar los cambios a GitHub o explique por que no aplica.
* [x] Anote riesgos y pendientes.
* [x] Mencione este reporte en la respuesta final al usuario.
