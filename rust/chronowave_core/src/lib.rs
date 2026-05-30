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
