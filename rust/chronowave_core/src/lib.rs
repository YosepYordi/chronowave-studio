use std::ffi::{c_char, CStr, CString};
use std::sync::OnceLock;

const CORE_VERSION: &CStr = c"chronowave-core/0.1.0";
const TIMELINE_ENGINE_NAME: &str = "gstreamer-ges-planned";
#[cfg(not(feature = "gstreamer-ges"))]
const SIMULATED_MEDIA_ENGINE_DIAGNOSTIC: &str = "{\"engine\":\"GStreamer/GES\",\"status\":\"simulated\",\"mode\":\"rust-ffi-smoke\",\"native_bindings\":false,\"detail\":\"GStreamer/GES bindings are not compiled in this build; Rust FFI accepts timeline snapshots for preview/export diagnostics.\"}";

static MEDIA_ENGINE_DIAGNOSTIC_JSON: OnceLock<&'static str> = OnceLock::new();
static MEDIA_ENGINE_DIAGNOSTIC_C_STRING: OnceLock<CString> = OnceLock::new();

pub fn core_version() -> &'static str {
    CORE_VERSION
        .to_str()
        .expect("static ChronoWave core version must be valid UTF-8")
}

pub fn timeline_engine_name() -> &'static str {
    TIMELINE_ENGINE_NAME
}

pub fn media_engine_diagnostic_json() -> &'static str {
    MEDIA_ENGINE_DIAGNOSTIC_JSON.get_or_init(build_media_engine_diagnostic)
}

#[no_mangle]
pub extern "C" fn chronowave_core_version() -> *const c_char {
    CORE_VERSION.as_ptr()
}

#[no_mangle]
pub extern "C" fn chronowave_media_engine_diagnostic() -> *const c_char {
    MEDIA_ENGINE_DIAGNOSTIC_C_STRING
        .get_or_init(|| {
            CString::new(media_engine_diagnostic_json())
                .expect("ChronoWave media diagnostic JSON must not contain NUL bytes")
        })
        .as_ptr()
}

#[cfg(feature = "gstreamer-ges")]
fn build_media_engine_diagnostic() -> &'static str {
    match initialize_gstreamer_ges() {
        Ok(()) => "{\"engine\":\"GStreamer/GES\",\"status\":\"ready\",\"mode\":\"rust-gstreamer-ges\",\"native_bindings\":true,\"detail\":\"GStreamer and GStreamer Editing Services initialized successfully from Rust.\"}",
        Err(detail) => Box::leak(
            format!(
                "{{\"engine\":\"GStreamer/GES\",\"status\":\"unavailable\",\"mode\":\"rust-gstreamer-ges\",\"native_bindings\":true,\"detail\":\"{}\"}}",
                escape_json_string(&detail)
            )
            .into_boxed_str(),
        ),
    }
}

#[cfg(not(feature = "gstreamer-ges"))]
fn build_media_engine_diagnostic() -> &'static str {
    SIMULATED_MEDIA_ENGINE_DIAGNOSTIC
}

#[cfg(feature = "gstreamer-ges")]
fn initialize_gstreamer_ges() -> Result<(), String> {
    gstreamer::init().map_err(|error| format!("GStreamer initialization failed: {error}"))?;
    gstreamer_editing_services::init()
        .map_err(|error| format!("GStreamer Editing Services initialization failed: {error}"))?;
    Ok(())
}

#[cfg(feature = "gstreamer-ges")]
fn escape_json_string(value: &str) -> String {
    value.replace('\\', "\\\\").replace('"', "\\\"")
}

/// Procesa un snapshot del timeline en formato JSON enviado por Dart/Flutter.
/// Retorna:
/// * `1` si el snapshot es aceptado por el motor simulado.
/// * `0` si el JSON no contiene marcas válidas de pistas/clips.
/// * `-1` si el puntero es nulo.
/// * `-2` si la decodificación de caracteres UTF-8 falla.
///
/// # Safety
///
/// `json_ptr` puede ser nulo. Si no lo es, debe apuntar a una cadena legible,
/// terminada en NUL y válida durante toda la llamada.
#[no_mangle]
pub unsafe extern "C" fn process_timeline_snapshot(json_ptr: *const c_char) -> i32 {
    if json_ptr.is_null() {
        return -1; // Puntero nulo
    }

    // SAFETY: el contrato del caller garantiza un puntero legible y terminado
    // en NUL; el caso nulo ya fue descartado.
    let c_str = unsafe { CStr::from_ptr(json_ptr) };
    let json_data = match c_str.to_str() {
        Ok(s) => s,
        Err(_) => return -2, // Cadena UTF-8 inválida
    };

    println!(
        "Rust [chronowave_core] FFI recibió snapshot ({} bytes).",
        json_data.len()
    );

    // Aceptar un snapshot solo valida el contrato FFI simulado. Cuando existan
    // bindings nativos, deberán exponer capacidad real sin reutilizar este código.
    if json_data.contains("\"tracks\"") {
        return 1;
    }

    0 // Formato de snapshot sin pistas
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::ffi::CString;

    #[test]
    fn test_chronowave_version() {
        assert_eq!(core_version(), "chronowave-core/0.1.0");
    }

    #[test]
    fn test_process_snapshot_null() {
        // SAFETY: el contrato permite explícitamente un puntero nulo.
        let res = unsafe { process_timeline_snapshot(std::ptr::null()) };
        assert_eq!(res, -1);
    }

    #[test]
    fn test_process_snapshot_valid() {
        let json = CString::new("{\"tracks\": [], \"clips\": []}").unwrap();
        // SAFETY: CString mantiene un buffer válido y terminado en NUL durante la llamada.
        let res = unsafe { process_timeline_snapshot(json.as_ptr()) };
        assert_eq!(res, 1); // Modo simulación activo en tests por defecto
    }
}
