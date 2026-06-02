use chronowave_core::{core_version, media_engine_diagnostic_json, timeline_engine_name};

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
    assert!(diagnostic.contains("\"status\":\"simulated\""));
    assert!(diagnostic.contains("\"native_bindings\":false"));
}
