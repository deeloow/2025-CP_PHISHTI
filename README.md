# Phishti Detector

A Flutter mobile application that proactively detects and prevents SMS phishing attacks using machine learning (ML) models via TensorFlow Lite.

## 🔹 Core Functionalities

### SMS Interception & Filtering
- Requests permission to become the default SMS app on Android
- Intercepts all incoming SMS messages
- Runs ML classification on SMS content
- Archives phishing messages in a secure SQLite database
- Prevents phishing messages from appearing in the main inbox

### URL Phishing Detection
- Extracts URLs from SMS messages
- Runs them through ML-powered URL analyzer (TensorFlow Lite)
- Blocks suspicious URLs from being clickable

### User Authentication & Cloud Sync
- Firebase Authentication (email/password and Google Sign-In)
- Syncs phishing signatures (hashed message fingerprints) to the cloud
- Downloads user's blocklist on login for cross-device protection

### Phishing Archive & User Controls
- Shows phishing messages in a separate Archive screen
- Allows users to restore messages (false positive correction)
- Whitelist trusted senders/URLs
- Report false positives/negatives to improve accuracy

### Notification System
- Push notifications when phishing attempts are detected
- Clear, non-alarming notifications: "Phishing SMS detected and archived safely"

## 🔹 Design & UI/UX

### Theme
- Modern, secure, minimal UI with cybersecurity-inspired design
- Dark mode default with neon highlights
- Unique "Threat Meter" gamifies security awareness

### Screens
- **Login/Register**: Firebase integration
- **Dashboard**: Recent detections and system status with Threat Meter
- **Inbox & Archive**: Separate phishing archive with user-friendly controls
- **Settings**: Control sync, model updates, thresholds, theme toggle

## 🔹 Tech Stack

- **Frontend**: Flutter (Dart)
- **ML Inference**: TensorFlow Lite models (SMS classification + URL detection)
- **Local Storage**: SQLite with SQLCipher encryption
- **Backend**: Firebase (Authentication + Firestore for synced blocklists)
- **Notification Service**: Firebase Cloud Messaging (FCM)

## 🔹 Security & Privacy

- Never uploads raw SMS content
- Only stores hashed signatures in the cloud
- Encrypts local archive using SQLCipher
- Requires explicit user opt-in for cloud sync
- All data processing happens locally

## 🔹 Setup Instructions

### Prerequisites
- Flutter SDK (>=3.10.0)
- Android Studio / Xcode
- Firebase project
- TensorFlow Lite models

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd phishti_detector
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Firebase**
   - Create a Firebase project
   - Enable Authentication and Firestore
   - Download `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)
   - Place them in the appropriate directories
   - Update `firebase_options.dart` with your project configuration

4. **Add ML Models**
   - Place your TensorFlow Lite models in `assets/models/`
   - Update model paths in `lib/core/services/ml_service.dart`

5. **Configure Permissions**
   - Android: Permissions are already configured in `android/app/src/main/AndroidManifest.xml`
   - iOS: Add required permissions in `ios/Runner/Info.plist`

6. **Run the app**
   ```bash
   flutter run
   ```

### Model Setup

1. **SMS Classification Model**
   - Place your SMS classifier model as `assets/models/sms_classifier.tflite`
   - Ensure the model expects text input and outputs phishing probability

2. **URL Classification Model**
   - Place your URL classifier model as `assets/models/url_classifier.tflite`
   - Ensure the model can analyze URLs for phishing patterns

3. **Vocabulary File**
   - Create `assets/models/vocab.json` with your text preprocessing vocabulary
   - Format: `{"word": index}` mapping

### Firebase Configuration

1. **Authentication**
   - Enable Email/Password authentication
   - Enable Google Sign-In
   - Configure OAuth consent screen

2. **Firestore**
   - Create collections: `users`, `phishing_signatures`
   - Set up security rules for user data protection

3. **Cloud Messaging**
   - Enable FCM for push notifications
   - Configure notification channels

## 🔹 Project Structure

```
lib/
├── core/
│   ├── providers/          # State management (Riverpod)
│   ├── services/           # Core services (Auth, SMS, ML, Database)
│   ├── router/             # Navigation routing
│   └── theme/              # App theming
├── models/                 # Data models
├── screens/                # UI screens
│   ├── auth/               # Login/Register screens
│   ├── dashboard/          # Main dashboard
│   ├── inbox/              # SMS inbox
│   ├── archive/            # Phishing archive
│   ├── settings/           # Settings screen
│   └── widgets/            # Reusable widgets
└── main.dart              # App entry point
```

## 🔹 Key Features

### Threat Meter
- Visualizes phishing attempts blocked per week
- Gamifies security awareness
- Shows threat levels: Low, Medium, High, Critical

### ML Integration
- TensorFlow Lite for on-device inference
- Rule-based fallback when models fail
- Continuous learning from user feedback

### Privacy-First Design
- Local processing of all SMS content
- Encrypted local storage
- Optional cloud sync with hashed signatures only

## 🔹 Permissions Required

### Android
- `RECEIVE_SMS`: Intercept incoming SMS
- `READ_SMS`: Read SMS messages
- `SEND_SMS`: Send SMS messages
- `WRITE_SMS`: Write SMS messages
- `BROADCAST_SMS`: Broadcast SMS events
- `POST_NOTIFICATIONS`: Show notifications
- `INTERNET`: Network access for Firebase

### iOS
- SMS permissions (limited on iOS)
- Notification permissions
- Network access

## 🔹 Development

### Running Tests
```bash
flutter test
```

### Building for Production
```bash
# Android
flutter build apk --release

# iOS
flutter build ios --release
```

### Code Generation
```bash
# Generate model classes
flutter packages pub run build_runner build
```

## 🔹 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## 🔹 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🔹 Support

For support and questions:
- Create an issue in the repository
- Check the documentation
- Review the code comments

## 🔹 Roadmap

- [ ] iOS SMS integration (when Apple allows)
- [ ] Advanced ML model training
- [ ] Real-time threat intelligence
- [ ] Multi-language support
- [ ] Advanced analytics dashboard
