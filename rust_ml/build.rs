extern crate cbindgen;

use std::env;
use std::path::PathBuf;

fn main() {
    let crate_dir = env::var("CARGO_MANIFEST_DIR").unwrap();

    cbindgen::Builder::new()
        .with_crate(crate_dir)
        .with_language(cbindgen::Language::C)
        .with_include_guard("RUST_ML_H")
        .with_header("/* PhishTi Rust ML Library - DistilBERT SMS Phishing Detection */")
        .with_documentation(true)
        .generate()
        .expect("Unable to generate bindings")
        .write_to_file("rust_ml.h");
}
