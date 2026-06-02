# Reporte IA - 2026-06-01 20:50 - infra - Android FFI packaging

## 1. Metadatos

* Fecha y hora local: 2026-06-01 20:50
* Zona horaria: America/Lima (-05:00)
* IA o herramienta: Codex
* Integrante responsable: Yosep Yordi / usuario solicitante
* Estado de la tarea: terminado
* Area o capa principal: infra / Android / Rust / FFI packaging
* Solicitud original del usuario: "Tarea de implementacion enfocada: Android FFI packaging para ChronoWave Studio."
* Actualizacion por revision: 2026-06-01 21:03 -05:00, fixes solicitados sobre host tag macOS, seleccion de NDK, inputs incrementales y limpieza de JNI output.

## 2. Sincronizacion con GitHub antes de modificar

|Revision|Resultado|Evidencia|
|-|-|-|
|`git status --short`|ejecutado|Arbol limpio al inicio de este turno. Durante el trabajo aparecieron cambios ajenos en Flutter/tests y un reporte `2026-06-01-2043_codex_frontend_editor-trim-split.md`; no se revirtieron ni se mezclaron como propios.|
|`git branch --show-current`|ejecutado|Rama actual: `codex/ffi-timeline-snapshot`.|
|`git remote -v`|ejecutado|`origin` apunta a `https://github.com/YosepYordi/chronowave-studio.git`.|
|`git pull --ff-only`|ejecutado|En este turno respondio `Already up to date.` y actualizo `origin/main` de `f305080` a `aae26ac`.|
|`git rev-parse HEAD` + `gh api repos/YosepYordi/chronowave-studio/branches/codex/ffi-timeline-snapshot --jq .commit.sha`|ejecutado|Ambos reportaron `120794eff3ed6a71279568914c37b32b322e3d4d`.|
|`gh pr list --json number,title,headRefName,baseRefName,state --limit 20`|ejecutado|Resultado: `[]`; no habia Pull Requests abiertos visibles para revisar.|

Nota de contexto del parent: en esta sesion se informo que un `git pull --ff-only` previo habia fallado por conexion HTTPS a `github.com`, pero `gh api` verifico que el HEAD local `120794eff3ed6a71279568914c37b32b322e3d4d` coincidia con la rama remota `codex/ffi-timeline-snapshot`. En este turno el `pull` si funciono.

Continuacion por feedback de reviewer: al iniciar la correccion 21:03 habia cambios locales pendientes en `android/app/build.gradle.kts`, `docs/reportes/INDICE.md`, archivos Flutter/tests ajenos y reportes no versionados. Por esa razon no se ejecuto `git pull --ff-only` a ciegas. `gh pr list --json number,title,headRefName,baseRefName,state --limit 20` respondio `[]`.

## 3. Contexto revisado antes de modificar

* Reportes leidos: `docs/reportes/README.md`, `docs/reportes/INDICE.md`, `docs/reportes/2026-05-31-2231_codex_infra_toolchain-android-rust.md`, `docs/reportes/2026-05-31-2152_codex_mixto_ffi-timeline-snapshot.md`.
* Archivos o carpetas revisadas: `AGENTS.md`, `docs/checklists/CHECKLIST_IA.md`, `docs/reportes/PLANTILLA_REPORTE_IA.md`, `android/app/build.gradle.kts`, `android/build.gradle.kts`, `android/local.properties`, `rust/chronowave_core/Cargo.toml`, `rust/chronowave_core/src/lib.rs`.
* Supuestos usados: el loader Dart ya intenta cargar `libchronowave_core.so` en Android/Linux; por tanto el cambio correcto era hacer que Gradle compile y empaquete la libreria nativa por ABI sin versionar artefactos.

## 4. Resumen para la siguiente IA

Se agrego un flujo Gradle reproducible para compilar `chronowave_core` como `libchronowave_core.so` para Android `arm64-v8a` y `x86_64`. Las tareas instalan targets Rust con `rustup target add`, encuentran el Android SDK desde `android/local.properties` o variables de entorno, prefieren el NDK configurado por Flutter/AGP cuando existe y configuran los linkers clang por target Rust. Cargo escribe en `build/rust-target/<debug|release>` y las `.so` se copian a `build/rust-jniLibs/<debug|release>/<abi>/`; esos directorios quedan conectados a `jniLibs` de debug/release y se empaquetan en los APKs. La revision posterior ajusto macOS a `darwin-x86_64`, amplio inputs incrementales y limpia la carpeta JNI de cada variante antes de copiar.

## 5. Cambios realizados

|Tipo|Archivo o carpeta|Detalle|
|-|-|-|
|modificado|`android/app/build.gradle.kts`|Agrega targets Android Rust `arm64-v8a`/`x86_64`, resolucion de SDK/NDK, linkers clang por target, tareas `installChronowaveAndroidRustTargets`, `buildChronowaveCoreAndroidDebug` y `buildChronowaveCoreAndroidRelease`, y source sets `jniLibs` hacia `build/rust-jniLibs`. Revision 21:03: macOS usa `darwin-x86_64`, se prefiere `flutter.ndkVersion`, se agregan inputs incrementales de workspace/config y se limpia `build/rust-jniLibs/<variant>`.|
|creado|`docs/reportes/2026-06-01-2050_codex_infra_android-ffi-packaging.md`|Reporte obligatorio de este turno.|
|modificado|`docs/reportes/INDICE.md`|Agrega este reporte al inicio del indice, preservando el reporte 20:43 ya presente de otro trabajo.|

## 6. Decisiones tomadas

|Decision|Motivo|Alternativas consideradas|
|-|-|-|
|Usar Gradle en lugar de un script separado|El empaquetado depende del build Android; conectar tareas a `mergeDebugJniLibFolders` y `mergeReleaseJniLibFolders` garantiza que Flutter/Gradle compilen antes de empaquetar.|Crear script manual bajo `scripts/`; descartado porque seria facil olvidarlo antes de `flutter build apk`.|
|Generar artefactos bajo `build/` y separar `CARGO_TARGET_DIR` por build type|Cumple la regla de no versionar `.so`, APKs ni `rust/target`, mantiene salidas reproducibles/ignoradas por `.gitignore` y evita solapar outputs de debug/release.|Usar `rust/target` del workspace como salida principal; descartado porque es menos claro para packaging y ya habia causado una ruta equivocada en el primer intento.|
|Soportar `arm64-v8a` y `x86_64`|Son los ABIs pedidos como minimo y validan dispositivo real moderno y emulador x86_64.|Agregar `armeabi-v7a` y `x86`; descartado por alcance y para mantener robustez inicial.|
|Usar clang del NDK con API 29|`minSdk` del app es 29, por lo que los wrappers `*-android29-clang` son coherentes con el APK.|Depender de `cargo-ndk`; descartado para no agregar una herramienta externa adicional.|
|Usar `darwin-x86_64` para macOS|El reviewer indico que el NDK normalmente expone `toolchains/llvm/prebuilt/darwin-x86_64` incluso en Apple Silicon; no hay NDK macOS local en esta maquina para probar una excepcion.|Mantener `darwin-arm64`; descartado porque era fragil para instalaciones NDK comunes.|
|Preferir `flutter.ndkVersion` antes del NDK mas alto|Alinea Cargo/linker con el NDK configurado por Flutter/AGP; si esa version no esta instalada o no tiene toolchain, cae al NDK versionado mas alto disponible.|Elegir siempre el mas alto; descartado por posible divergencia con AGP.|
|Declarar mas inputs y limpiar JNI output por variante|Cambios en workspace `Cargo.toml`, `Cargo.lock`, targets/API level o perfil deben invalidar la tarea; limpiar `build/rust-jniLibs/<variant>` evita ABIs obsoletas si cambia la lista.|Mantener solo crate `Cargo.toml` y `src`; descartado por cache incremental incompleta.|

## 7. Validacion realizada

|Validacion|Resultado|Evidencia|
|-|-|-|
|RED: `flutter --no-version-check build apk --debug` antes de modificar|paso el build, fallo la expectativa de packaging|Genero `build\app\outputs\flutter-apk\app-debug.apk`; inspeccion ZIP reporto `NO libchronowave_core.so entries found`.|
|Primer GREEN: `flutter --no-version-check build apk --debug` despues del primer cambio|fallo|Cargo compilo, pero la tarea esperaba salida en `rust/chronowave_core/target/...`; al ser workspace Rust, Cargo no produjo ahi la `.so`. Se corrigio fijando `CARGO_TARGET_DIR=build/rust-target/<buildType>`.|
|`flutter --no-version-check build apk --debug` final|paso|Genero `build\app\outputs\flutter-apk\app-debug.apk`; Rust Android targets estaban instalados y compilo debug para `aarch64-linux-android` y `x86_64-linux-android`.|
|Inspeccion ZIP de `app-debug.apk` final|paso|Contiene `lib/arm64-v8a/libchronowave_core.so` (341160 bytes) y `lib/x86_64/libchronowave_core.so` (369120 bytes).|
|`cargo test --manifest-path rust\chronowave_core\Cargo.toml`|paso|5 tests Rust pasaron: 3 unitarios, 2 smoke/integracion, 0 doctests.|
|`flutter --no-version-check analyze`|paso|`No issues found!` en 20.8s.|
|`flutter --no-version-check test`|paso|`+14: All tests passed!`.|
|`flutter --no-version-check build apk --release`|paso|Genero `build\app\outputs\flutter-apk\app-release.apk` (53.3MB) y compilo release para ambos targets Rust Android.|
|Inspeccion ZIP de `app-release.apk`|paso|Contiene `lib/arm64-v8a/libchronowave_core.so` (318400 bytes) y `lib/x86_64/libchronowave_core.so` (345096 bytes).|
|`git check-ignore -v build\rust-jniLibs\... build\rust-target\... rust\target\...`|paso|`build/` y `rust/target/` estan ignorados por `.gitignore`; los artefactos generados no quedan para versionar.|
|Revision RED por inspeccion: `Select-String android\app\build.gradle.kts -Pattern 'darwin-arm64\|sortedByDescending\|inputs\.file\|inputs\.dir\|copy {'` antes del fix 21:03|fallo esperado|Mostro `darwin-arm64`, seleccion por `sortedByDescending` sin preferencia de `flutter.ndkVersion`, solo inputs de crate `Cargo.toml`/`src` y copia sin limpieza previa.|
|`android\gradlew.bat -p android :app:tasks --group rust` despues del fix 21:03|paso|Gradle configuro `:app` y listo `buildChronowaveCoreAndroidDebug`, `buildChronowaveCoreAndroidRelease` e `installChronowaveAndroidRustTargets`. Advertencias: `jvmTarget` y `Project.exec` deprecados para Gradle 9.|
|`flutter --no-version-check build apk --debug` despues del fix 21:03|paso|Genero `build\app\outputs\flutter-apk\app-debug.apk`; Cargo termino debug para ambos targets Android.|
|Inspeccion ZIP de `app-debug.apk` despues del fix 21:03|paso|Contiene `lib/arm64-v8a/libchronowave_core.so` (341160 bytes) y `lib/x86_64/libchronowave_core.so` (369120 bytes).|
|`flutter --no-version-check analyze` despues del fix 21:03|paso|`No issues found!` en 28.2s.|
|`flutter --no-version-check test` despues del fix 21:03|paso|`+17: All tests passed!`, incluyendo el trabajo Flutter paralelo.|
|`cargo test --manifest-path rust\chronowave_core\Cargo.toml` despues del fix 21:03|paso|5 tests Rust pasaron: 3 unitarios, 2 smoke/integracion, 0 doctests.|

## 8. GitHub al finalizar

* Se pregunto al humano si quiere enviar los cambios a GitHub: si, en la respuesta final del coordinador Codex.
* Respuesta del humano, si existe: pendiente.
* Rama sugerida: `codex/ffi-timeline-snapshot`.
* Mensaje de commit sugerido: `build: package Rust FFI library in Android APKs`.
* Metodo sugerido: commit local, push de rama y Pull Request hacia `main`, solo con autorizacion humana.

## 9. Riesgos y pendientes

* Riesgo o pendiente 1: este flujo requiere `rustup`, `cargo` y un Android NDK instalado localmente; si faltan, Gradle fallara con un error explicito.
* Riesgo o pendiente 2: no se pudo probar en macOS real; el host tag quedo en `darwin-x86_64` por compatibilidad con el layout comun del Android NDK.
* Riesgo o pendiente 3: durante este turno aparecieron cambios ajenos en Flutter/tests y un reporte 20:43; deben tratarse como trabajo de otro agente al preparar commits.

## 10. Instrucciones para la siguiente IA

* Siguiente paso recomendado: probar en emulador/dispositivo Android que `ChronoWaveFfi.load()` carga `libchronowave_core.so` real y no cae al fallback.
* Archivos que conviene leer primero: `android/app/build.gradle.kts`, `lib/src/core/ffi/chronowave_ffi.dart`, `rust/chronowave_core/src/lib.rs`.
* Cuidado especial: no versionar `build/`, `rust/target/`, APKs ni `.so`; revisar `git status --short` porque hay cambios locales ajenos a este trabajo.

## 11. Checklist de cierre

* [x] Actualice `docs/reportes/INDICE.md`.
* [x] Declare todos los archivos que cambie.
* [x] Registre validacion o razon concreta si no se valido.
* [x] Registre el estado de sincronizacion Git/GitHub.
* [x] Pregunte al humano si quiere enviar los cambios a GitHub o explique por que no aplica.
* [x] Anote riesgos y pendientes.
* [x] Mencione este reporte en la respuesta final al usuario.
