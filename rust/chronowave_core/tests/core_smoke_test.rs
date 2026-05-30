use chronowave_core::{core_version, timeline_engine_name};

#[test]
fn exposes_stable_core_version_for_flutter_ffi_smoke_tests() {
    assert_eq!(core_version(), "chronowave-core/0.1.0");
}

#[test]
fn names_the_initial_timeline_engine() {
    assert_eq!(timeline_engine_name(), "gstreamer-ges-planned");
}

