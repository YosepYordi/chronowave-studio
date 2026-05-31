use std::ffi::{c_char, CStr};

const CORE_VERSION: &CStr = c"chronowave-core/0.1.0";
const TIMELINE_ENGINE_NAME: &str = "gstreamer-ges-planned";

pub fn core_version() -> &'static str {
    CORE_VERSION
        .to_str()
        .expect("static ChronoWave core version must be valid UTF-8")
}

pub fn timeline_engine_name() -> &'static str {
    TIMELINE_ENGINE_NAME
}

#[no_mangle]
pub extern "C" fn chronowave_core_version() -> *const c_char {
    CORE_VERSION.as_ptr()
}

/// Procesa un snapshot del timeline en formato JSON enviado por Dart/Flutter.
/// Retorna:
/// * `1` o `100` en caso de éxito (modo simulación vs modo real GStreamer).
/// * `0` si el JSON no contiene marcas válidas de pistas/clips.
/// * `-1` si el puntero es nulo.
/// * `-2` si la decodificación de caracteres UTF-8 falla.
#[no_mangle]
pub extern "C" fn process_timeline_snapshot(json_ptr: *const c_char) -> i32 {
    if json_ptr.is_null() {
        return -1; // Puntero nulo
    }

    let c_str = unsafe { CStr::from_ptr(json_ptr) };
    let json_data = match c_str.to_str() {
        Ok(s) => s,
        Err(_) => return -2, // Cadena UTF-8 inválida
    };

    println!("Rust [chronowave_core] FFI recibió snapshot ({} bytes).", json_data.len());

    // Simulación del motor según la feature flag de GStreamer
    #[cfg(feature = "gstreamer")]
    {
        // En un pipeline real, aquí llamaríamos a gstreamer::init() y compilaríamos
        // el pipeline de GStreamer Editing Services (GES)
        if json_data.contains("\"tracks\"") {
            return 100; // Código de GStreamer Real inicializado
        }
    }

    #[cfg(not(feature = "gstreamer"))]
    {
        // En simulación simplemente verificamos la estructura básica
        if json_data.contains("\"tracks\"") {
            return 1; // Éxito en Simulación
        }
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
        let res = process_timeline_snapshot(std::ptr::null());
        assert_eq!(res, -1);
    }

    #[test]
    fn test_process_snapshot_valid() {
        let json = CString::new("{\"tracks\": [], \"clips\": []}").unwrap();
        let res = process_timeline_snapshot(json.as_ptr());
        assert_eq!(res, 1); // Modo simulación activo en tests por defecto
    }
}
