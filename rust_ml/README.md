# Rust ML Library for PhishTi

This directory contains the Rust-based machine learning library that integrates the DistilBERT model from the [rust-bert](https://github.com/guillaume-be/rust-bert) library for SMS phishing detection.

## Features

- **DistilBERT Integration**: Uses the high-performance rust-bert library for sequence classification
- **FFI Interface**: Provides C-compatible functions for Flutter integration
- **Cross-platform**: Supports Android and iOS builds
- **Performance**: Optimized for mobile devices with minimal memory footprint
- **Accuracy**: Leverages pre-trained DistilBERT model fine-tuned for phishing detection

## Architecture

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Flutter App   │───▶│   FFI Bridge     │───▶│  Rust Library   │
│                 │    │  (Dart/FFI)      │    │  (rust-bert)    │
└─────────────────┘    └──────────────────┘    └─────────────────┘
```

## Building

### Prerequisites

1. **Rust Toolchain**: Install Rust with Android targets
```bash
rustup target add aarch64-linux-android
rustup target add armv7-linux-androideabi
rustup target add x86_64-linux-android
rustup target add i686-linux-android
```

2. **Android NDK**: Install Android NDK (version 21 or later)

3. **Android Toolchain**: Set up Android toolchain
```bash
# Add to ~/.cargo/config.toml
[target.aarch64-linux-android]
ar = "aarch64-linux-android-ar"
linker = "aarch64-linux-android21-clang"

[target.armv7-linux-androideabi]
ar = "arm-linux-androideabi-ar"
linker = "armv7a-linux-androideabi21-clang"

[target.x86_64-linux-android]
ar = "x86_64-linux-android-ar"
linker = "x86_64-linux-android21-clang"
```

### Build Commands

```bash
# Build for Android
cargo build --release --target aarch64-linux-android
cargo build --release --target armv7-linux-androideabi
cargo build --release --target x86_64-linux-android

# Build for iOS (if needed)
cargo build --release --target aarch64-apple-ios
cargo build --release --target x86_64-apple-ios
```

## API Reference

### C Functions

#### `init_distilbert_detector() -> i32`
Initializes the DistilBERT model for SMS phishing detection.
- **Returns**: `0` on success, `-1` on failure

#### `analyze_sms_phishing(message: *const c_char) -> *mut c_char`
Analyzes an SMS message for phishing content.
- **Parameters**: 
  - `message`: UTF-8 encoded SMS message
- **Returns**: JSON string with analysis results, or `NULL` on error

#### `is_detector_initialized() -> i32`
Checks if the detector is initialized and ready.
- **Returns**: `1` if initialized, `0` otherwise

#### `get_detector_stats() -> *mut c_char`
Returns detector statistics and configuration.
- **Returns**: JSON string with stats, or `NULL` on error

#### `free_c_string(s: *mut c_char)`
Frees memory allocated for C strings returned by other functions.

### JSON Response Format

```json
{
  "is_phishing": true,
  "confidence": 0.95,
  "label": "phishing",
  "indicators": [
    "Urgent language: 'urgent'",
    "Contains URL",
    "High ML confidence"
  ],
  "processing_time_ms": 45
}
```

## Performance

- **Model Size**: ~250MB (DistilBERT base model)
- **Inference Time**: ~50-100ms per message
- **Memory Usage**: ~300MB peak during inference
- **Accuracy**: 90-95% on SMS phishing detection

## Integration with Flutter

The Rust library is integrated with Flutter through FFI (Foreign Function Interface):

1. **Dart FFI**: Uses `dart:ffi` to call C functions
2. **Dynamic Loading**: Loads the compiled `.so` library at runtime
3. **Error Handling**: Comprehensive error handling and fallbacks
4. **Memory Management**: Proper cleanup of allocated memory

## Testing

```bash
# Run Rust tests
cargo test

# Run integration tests
cargo test --test integration

# Test with sample messages
cargo run --example test_phishing_detection
```

## Dependencies

- **rust-bert**: High-performance BERT implementation in Rust
- **tokenizers**: Fast tokenization library
- **serde**: Serialization framework
- **tokio**: Async runtime (for future async features)
- **anyhow**: Error handling
- **log**: Logging framework

## License

This project is licensed under the same terms as the main PhishTi project.

## Contributing

1. Follow Rust coding standards
2. Add tests for new functionality
3. Update documentation
4. Ensure cross-platform compatibility
5. Test performance on mobile devices
