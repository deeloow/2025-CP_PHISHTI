@echo off
echo Building Rust DistilBERT library for Android...

REM Check if Rust is installed
rustc --version >nul 2>&1
if %errorlevel% neq 0 (
    echo Error: Rust is not installed. Please install Rust first.
    echo Visit: https://rustup.rs/
    pause
    exit /b 1
)

REM Check if Android NDK is available
if not defined ANDROID_NDK_HOME (
    echo Error: ANDROID_NDK_HOME is not set.
    echo Please set ANDROID_NDK_HOME to your Android NDK installation path.
    echo Example: set ANDROID_NDK_HOME=C:\Users\YourName\AppData\Local\Android\Sdk\ndk\21.4.7075529
    pause
    exit /b 1
)

echo ANDROID_NDK_HOME: %ANDROID_NDK_HOME%

REM Add Android targets if not already added
echo Adding Android targets...
rustup target add aarch64-linux-android
rustup target add armv7-linux-androideabi
rustup target add x86_64-linux-android
rustup target add i686-linux-android

REM Set up environment variables for Android builds
set AR_aarch64-linux-android=%ANDROID_NDK_HOME%\toolchains\llvm\prebuilt\windows-x86_64\bin\aarch64-linux-android21-ar.exe
set AR_armv7-linux-androideabi=%ANDROID_NDK_HOME%\toolchains\llvm\prebuilt\windows-x86_64\bin\armv7a-linux-androideabi21-ar.exe
set AR_x86_64-linux-android=%ANDROID_NDK_HOME%\toolchains\llvm\prebuilt\windows-x86_64\bin\x86_64-linux-android21-ar.exe
set AR_i686-linux-android=%ANDROID_NDK_HOME%\toolchains\llvm\prebuilt\windows-x86_64\bin\i686-linux-android21-ar.exe

set CC_aarch64-linux-android=%ANDROID_NDK_HOME%\toolchains\llvm\prebuilt\windows-x86_64\bin\aarch64-linux-android21-clang.exe
set CC_armv7-linux-androideabi=%ANDROID_NDK_HOME%\toolchains\llvm\prebuilt\windows-x86_64\bin\armv7a-linux-androideabi21-clang.exe
set CC_x86_64-linux-android=%ANDROID_NDK_HOME%\toolchains\llvm\prebuilt\windows-x86_64\bin\x86_64-linux-android21-clang.exe
set CC_i686-linux-android=%ANDROID_NDK_HOME%\toolchains\llvm\prebuilt\windows-x86_64\bin\i686-linux-android21-clang.exe

REM Create output directory
if not exist "android\app\src\main\jniLibs" mkdir "android\app\src\main\jniLibs"

REM Build for different Android architectures
echo Building for aarch64-linux-android...
cargo build --target aarch64-linux-android --release
if %errorlevel% neq 0 (
    echo Error building for aarch64-linux-android
    pause
    exit /b 1
)
copy "target\aarch64-linux-android\release\librust_ml.so" "android\app\src\main\jniLibs\arm64-v8a\librust_ml.so"

echo Building for armv7-linux-androideabi...
cargo build --target armv7-linux-androideabi --release
if %errorlevel% neq 0 (
    echo Error building for armv7-linux-androideabi
    pause
    exit /b 1
)
copy "target\armv7-linux-androideabi\release\librust_ml.so" "android\app\src\main\jniLibs\armeabi-v7a\librust_ml.so"

echo Building for x86_64-linux-android...
cargo build --target x86_64-linux-android --release
if %errorlevel% neq 0 (
    echo Error building for x86_64-linux-android
    pause
    exit /b 1
)
copy "target\x86_64-linux-android\release\librust_ml.so" "android\app\src\main\jniLibs\x86_64\librust_ml.so"

echo Building for i686-linux-android...
cargo build --target i686-linux-android --release
if %errorlevel% neq 0 (
    echo Error building for i686-linux-android
    pause
    exit /b 1
)
copy "target\i686-linux-android\release\librust_ml.so" "android\app\src\main\jniLibs\x86\librust_ml.so"

echo.
echo ✅ Rust DistilBERT library built successfully!
echo.
echo Library files created:
echo - android\app\src\main\jniLibs\arm64-v8a\librust_ml.so
echo - android\app\src\main\jniLibs\armeabi-v7a\librust_ml.so
echo - android\app\src\main\jniLibs\x86_64\librust_ml.so
echo - android\app\src\main\jniLibs\x86\librust_ml.so
echo.
echo You can now build your Flutter app with ML-based phishing detection!
echo.
pause