use std::ffi::{c_char, CStr};

const CORE_VERSION: &CStr = c"chronowave-core/0.1.0";
const TIMELINE_ENGINE_NAME: &str = "gstreamer-ges-planned";
const MEDIA_ENGINE_DIAGNOSTIC: &CStr = c"{\"engine\":\"GStreamer/GES\",\"status\":\"simulated\",\"mode\":\"rust-ffi-smoke\",\"native_bindings\":false,\"detail\":\"GStreamer/GES bindings are not compiled in this build; Rust FFI accepts timeline snapshots for preview/export diagnostics.\"}";

pub fn core_version() -> &'static str {
    CORE_VERSION
        .to_str()
        .expect("static ChronoWave core version must be valid UTF-8")
}

pub fn timeline_engine_name() -> &'static str {
    TIMELINE_ENGINE_NAME
}

pub fn media_engine_diagnostic_json() -> &'static str {
    MEDIA_ENGINE_DIAGNOSTIC
        .to_str()
        .expect("static ChronoWave media diagnostic must be valid UTF-8")
}

#[no_mangle]
pub extern "C" fn chronowave_core_version() -> *const c_char {
    CORE_VERSION.as_ptr()
}

#[no_mangle]
pub extern "C" fn chronowave_media_engine_diagnostic() -> *const c_char {
    MEDIA_ENGINE_DIAGNOSTIC.as_ptr()
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
