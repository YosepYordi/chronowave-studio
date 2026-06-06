use chronowave_core::{
    core_version, media_engine_diagnostic_json, process_timeline_snapshot, timeline_engine_name,
};
use std::ffi::CString;

#[test]
fn exposes_stable_core_version_for_flutter_ffi_smoke_tests() {
    assert_eq!(core_version(), "chronowave-core/0.1.0");
}

#[test]
fn names_the_initial_timeline_engine() {
    assert_eq!(timeline_engine_name(), "gstreamer-ges-planned");
}

#[test]
fn exposes_media_engine_diagnostic_for_flutter() {
    let diagnostic = media_engine_diagnostic_json();

    assert!(diagnostic.contains("\"engine\":\"GStreamer/GES\""));
    if cfg!(feature = "gstreamer-ges") {
        assert!(diagnostic.contains("\"status\":\"ready\""));
        assert!(diagnostic.contains("\"native_bindings\":true"));
        assert!(diagnostic.contains("\"mode\":\"rust-gstreamer-ges\""));
    } else {
        assert!(diagnostic.contains("\"status\":\"simulated\""));
        assert!(diagnostic.contains("\"native_bindings\":false"));
        assert!(diagnostic.contains("\"mode\":\"rust-ffi-smoke\""));
    }
}

#[test]
fn processes_timeline_snapshots_only_in_simulated_mode() {
    let snapshot = CString::new("{\"tracks\": [], \"clips\": []}").unwrap();

    // SAFETY: CString mantiene un buffer válido y terminado en NUL durante la llamada.
    assert_eq!(unsafe { process_timeline_snapshot(snapshot.as_ptr()) }, 1);
}
