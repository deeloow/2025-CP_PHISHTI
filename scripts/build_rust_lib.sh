#!/bin/bash

echo "Building Rust DistilBERT library for Android..."

# Check if Rust is installed
if ! command -v rustc &> /dev/null; then
    echo "Error: Rust is not installed. Please install Rust first."
    echo "Visit: https://rustup.rs/"
    exit 1
fi

# Check if Android NDK is available
if [ -z "$ANDROID_NDK_HOME" ]; then
    echo "Error: ANDROID_NDK_HOME is not set."
    echo "Please set ANDROID_NDK_HOME to your Android NDK installation path."
    echo "Example: export ANDROID_NDK_HOME=/path/to/android-ndk"
    exit 1
fi

echo "ANDROID_NDK_HOME: $ANDROID_NDK_HOME"

# Add Android targets if not already added
echo "Adding Android targets..."
rustup target add aarch64-linux-android
rustup target add armv7-linux-androideabi
rustup target add x86_64-linux-android
rustup target add i686-linux-android

# Set up environment variables for Android builds
export AR_aarch64-linux-android="$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/bin/aarch64-linux-android21-ar"
export AR_armv7-linux-androideabi="$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/bin/armv7a-linux-androideabi21-ar"
export AR_x86_64-linux-android="$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/bin/x86_64-linux-android21-ar"
export AR_i686-linux-android="$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/bin/i686-linux-android21-ar"

export CC_aarch64-linux-android="$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/bin/aarch64-linux-android21-clang"
export CC_armv7-linux-androideabi="$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/bin/armv7a-linux-androideabi21-clang"
export CC_x86_64-linux-android="$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/bin/x86_64-linux-android21-clang"
export CC_i686-linux-android="$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/bin/i686-linux-android21-clang"

# Create output directory
mkdir -p "android/app/src/main/jniLibs"

# Build for different Android architectures
echo "Building for aarch64-linux-android..."
cargo build --target aarch64-linux-android --release
if [ $? -ne 0 ]; then
    echo "Error building for aarch64-linux-android"
    exit 1
fi
cp "target/aarch64-linux-android/release/librust_ml.so" "android/app/src/main/jniLibs/arm64-v8a/librust_ml.so"

echo "Building for armv7-linux-androideabi..."
cargo build --target armv7-linux-androideabi --release
if [ $? -ne 0 ]; then
    echo "Error building for armv7-linux-androideabi"
    exit 1
fi
cp "target/armv7-linux-androideabi/release/librust_ml.so" "android/app/src/main/jniLibs/armeabi-v7a/librust_ml.so"

echo "Building for x86_64-linux-android..."
cargo build --target x86_64-linux-android --release
if [ $? -ne 0 ]; then
    echo "Error building for x86_64-linux-android"
    exit 1
fi
cp "target/x86_64-linux-android/release/librust_ml.so" "android/app/src/main/jniLibs/x86_64/librust_ml.so"

echo "Building for i686-linux-android..."
cargo build --target i686-linux-android --release
if [ $? -ne 0 ]; then
    echo "Error building for i686-linux-android"
    exit 1
fi
cp "target/i686-linux-android/release/librust_ml.so" "android/app/src/main/jniLibs/x86/librust_ml.so"

echo ""
echo "✅ Rust DistilBERT library built successfully!"
echo ""
echo "Library files created:"
echo "- android/app/src/main/jniLibs/arm64-v8a/librust_ml.so"
echo "- android/app/src/main/jniLibs/armeabi-v7a/librust_ml.so"
echo "- android/app/src/main/jniLibs/x86_64/librust_ml.so"
echo "- android/app/src/main/jniLibs/x86/librust_ml.so"
echo ""
echo "You can now build your Flutter app with ML-based phishing detection!"
echo ""