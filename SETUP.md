# Phishti Detector - Setup Guide

This guide will help you set up the Phishti Detector Flutter application for development and production.

## Prerequisites

### Required Software
- **Flutter SDK**: Version 3.10.0 or higher
- **Dart SDK**: Version 3.0.0 or higher
- **Android Studio**: Latest version with Android SDK
- **Xcode**: Latest version (for iOS development)
- **Firebase CLI**: For Firebase configuration
- **Git**: For version control

### Required Accounts
- **Google Account**: For Firebase and Google Sign-In
- **Apple Developer Account**: For iOS development (optional)

## Step 1: Environment Setup

### Install Flutter
1. Download Flutter SDK from [flutter.dev](https://flutter.dev)
2. Extract to a suitable location (e.g., `C:\flutter` on Windows)
3. Add Flutter to your PATH environment variable
4. Run `flutter doctor` to verify installation

### Install Android Studio
1. Download from [developer.android.com](https://developer.android.com/studio)
2. Install with Android SDK
3. Configure Android emulator or connect physical device

### Install Firebase CLI
```bash
npm install -g firebase-tools
firebase login
```

## Step 2: Project Setup

### Clone Repository
```bash
git clone <repository-url>
cd phishti_detector
```

### Install Dependencies
```bash
flutter pub get
```

### Generate Model Classes
```bash
flutter packages pub run build_runner build
```

## Step 3: Firebase Configuration

### Create Firebase Project
1. Go to [Firebase Console](https://console.firebase.google.com)
2. Click "Create a project"
3. Enter project name: "Phishti Detector"
4. Enable Google Analytics (optional)
5. Choose or create a Google Analytics account

### Configure Authentication
1. In Firebase Console, go to "Authentication"
2. Click "Get started"
3. Go to "Sign-in method" tab
4. Enable "Email/Password" authentication
5. Enable "Google" authentication
6. Configure OAuth consent screen

### Configure Firestore
1. In Firebase Console, go to "Firestore Database"
2. Click "Create database"
3. Choose "Start in test mode" (for development)
4. Select a location for your database

### Configure Cloud Messaging
1. In Firebase Console, go to "Cloud Messaging"
2. Note down the Server Key for later use

### Download Configuration Files

#### Android Configuration
1. In Firebase Console, go to "Project Settings"
2. Click "Add app" and select Android
3. Enter package name: `com.example.phishti_detector`
4. Download `google-services.json`
5. Place it in `android/app/` directory

#### iOS Configuration
1. In Firebase Console, go to "Project Settings"
2. Click "Add app" and select iOS
3. Enter bundle ID: `com.example.phishtiDetector`
4. Download `GoogleService-Info.plist`
5. Place it in `ios/Runner/` directory

### Update Firebase Options
1. Open `firebase_options.dart`
2. Replace placeholder values with your actual Firebase configuration
3. Use Firebase CLI to generate the file:
   ```bash
   flutterfire configure
   ```

## Step 4: ML Models Setup

### Prepare TensorFlow Lite Models

#### SMS Classification Model
1. Train or obtain a TensorFlow model for SMS phishing detection
2. Convert to TensorFlow Lite format:
   ```python
   import tensorflow as tf
   
   # Load your trained model
   model = tf.keras.models.load_model('your_sms_model.h5')
   
   # Convert to TFLite
   converter = tf.lite.TFLiteConverter.from_keras_model(model)
   tflite_model = converter.convert()
   
   # Save the model
   with open('sms_classifier.tflite', 'wb') as f:
       f.write(tflite_model)
   ```

2. Place the model in `assets/models/sms_classifier.tflite`

#### URL Classification Model
1. Train or obtain a TensorFlow model for URL phishing detection
2. Convert to TensorFlow Lite format (similar to above)
3. Place the model in `assets/models/url_classifier.tflite`

#### Vocabulary File
1. Create a vocabulary file for text preprocessing:
   ```json
   {
     "<PAD>": 0,
     "<UNK>": 1,
     "the": 2,
     "a": 3,
     "and": 4,
     ...
   }
   ```

2. Place the vocabulary in `assets/models/vocab.json`

### Update Model Configuration
1. Open `lib/core/services/ml_service.dart`
2. Update model paths if necessary
3. Adjust input/output dimensions based on your models

## Step 5: Platform-Specific Configuration

### Android Configuration

#### Update AndroidManifest.xml
The required permissions are already configured in `android/app/src/main/AndroidManifest.xml`.

#### Update build.gradle
1. Open `android/app/build.gradle`
2. Ensure minimum SDK version is 21
3. Update target SDK version to latest

#### Configure ProGuard (for release builds)
1. Create `android/app/proguard-rules.pro`
2. Add rules for TensorFlow Lite:
   ```
   -keep class org.tensorflow.lite.** { *; }
   ```

### iOS Configuration

#### Update Info.plist
1. Open `ios/Runner/Info.plist`
2. Add required permissions:
   ```xml
   <key>NSCameraUsageDescription</key>
   <string>This app needs camera access for biometric authentication</string>
   <key>NSFaceIDUsageDescription</key>
   <string>This app uses Face ID for secure authentication</string>
   ```

#### Update Podfile
1. Open `ios/Podfile`
2. Ensure minimum iOS version is 11.0
3. Run `pod install` in the `ios/` directory

## Step 6: Development Setup

### Run the Application
```bash
# Debug mode
flutter run

# Release mode
flutter run --release
```

### Run Tests
```bash
flutter test
```

### Code Analysis
```bash
flutter analyze
```

## Step 7: Production Setup

### Android Production Build
1. Generate signing key:
   ```bash
   keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```

2. Create `android/key.properties`:
   ```
   storePassword=<password>
   keyPassword=<password>
   keyAlias=upload
   storeFile=<path-to-keystore>
   ```

3. Update `android/app/build.gradle` for signing configuration

4. Build release APK:
   ```bash
   flutter build apk --release
   ```

### iOS Production Build
1. Open project in Xcode
2. Configure signing and provisioning profiles
3. Build for App Store:
   ```bash
   flutter build ios --release
   ```

## Step 8: Testing

### Unit Tests
```bash
flutter test
```

### Integration Tests
```bash
flutter test integration_test/
```

### Manual Testing Checklist
- [ ] User registration and login
- [ ] SMS interception (Android only)
- [ ] ML model inference
- [ ] Phishing detection and archiving
- [ ] Notification system
- [ ] Cloud sync functionality
- [ ] Settings and preferences
- [ ] Whitelist management

## Step 9: Deployment

### Firebase Hosting (Optional)
```bash
firebase init hosting
firebase deploy
```

### App Store Deployment
1. Follow platform-specific guidelines
2. Prepare app store listings
3. Submit for review

## Troubleshooting

### Common Issues

#### Flutter Doctor Issues
```bash
flutter doctor --android-licenses
```

#### Firebase Configuration Issues
- Verify `google-services.json` and `GoogleService-Info.plist` are in correct locations
- Check Firebase project settings
- Ensure all required services are enabled

#### ML Model Issues
- Verify model files are in correct locations
- Check model input/output dimensions
- Test models independently

#### Permission Issues
- Check Android manifest permissions
- Verify iOS Info.plist permissions
- Test on physical devices

### Debug Mode
```bash
flutter run --debug
```

### Log Analysis
```bash
flutter logs
```

## Security Considerations

### Production Security
1. Enable Firebase security rules
2. Use encrypted local storage
3. Implement proper authentication
4. Regular security audits

### Data Privacy
1. Never store raw SMS content in cloud
2. Use hashed signatures only
3. Implement data retention policies
4. Regular privacy audits

## Support

For issues and questions:
1. Check this documentation
2. Review code comments
3. Create GitHub issues
4. Contact development team

## Additional Resources

- [Flutter Documentation](https://flutter.dev/docs)
- [Firebase Documentation](https://firebase.google.com/docs)
- [TensorFlow Lite Documentation](https://www.tensorflow.org/lite)
- [Android SMS Documentation](https://developer.android.com/guide/components/broadcasts)
