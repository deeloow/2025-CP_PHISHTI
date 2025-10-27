#!/bin/bash

# Build script for Rust DistilBERT library for Android
# This script builds the library for all Android targets

set -e

echo "🔨 Building Rust DistilBERT library for Android..."

# Check if Rust is installed
if ! command -v cargo &> /dev/null; then
    echo "❌ Rust is not installed. Please install Rust first:"
    echo "curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh"
    exit 1
fi

# Check if Android NDK is available
if [ -z "$ANDROID_NDK_HOME" ]; then
    echo "⚠️ ANDROID_NDK_HOME is not set. Please set it to your Android NDK path."
    echo "Example: export ANDROID_NDK_HOME=/path/to/android-ndk"
    exit 1
fi

# Add Android targets if not already added
echo "📱 Adding Android targets..."
rustup target add aarch64-linux-android
rustup target add armv7-linux-androideabi
rustup target add x86_64-linux-android
rustup target add i686-linux-android

# Build for each Android target
echo "🏗️ Building for aarch64-linux-android..."
cargo build --release --target aarch64-linux-android

echo "🏗️ Building for armv7-linux-androideabi..."
cargo build --release --target armv7-linux-androideabi

echo "🏗️ Building for x86_64-linux-android..."
cargo build --release --target x86_64-linux-android

echo "🏗️ Building for i686-linux-android..."
cargo build --release --target i686-linux-android

echo "✅ Build completed successfully!"
echo ""
echo "📁 Built libraries are located in:"
echo "  - target/aarch64-linux-android/release/librust_ml.so"
echo "  - target/armv7-linux-androideabi/release/librust_ml.so"
echo "  - target/x86_64-linux-android/release/librust_ml.so"
echo "  - target/i686-linux-android/release/librust_ml.so"
echo ""
echo "📋 Next steps:"
echo "  1. Copy the appropriate .so file to your Flutter app's android/app/src/main/jniLibs/"
echo "  2. Run 'flutter clean && flutter build apk' to rebuild your app"
echo "  3. Test the DistilBERT integration"
