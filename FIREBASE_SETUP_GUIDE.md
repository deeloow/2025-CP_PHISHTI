# Firebase Setup Guide for Phishti Detector

## 🔥 **Complete Firebase Configuration**

### **Step 1: Create Firebase Project**

1. **Go to [Firebase Console](https://console.firebase.google.com/)**
2. **Click "Create a project"**
3. **Enter project name**: `phishti-detector`
4. **Enable Google Analytics** (recommended)
5. **Click "Create project"**

### **Step 2: Add Android App**

1. **In Firebase Console, click "Add app" → Android**
2. **Enter package name**: `com.example.phishti_detector`
3. **Enter app nickname**: `Phishti Detector`
4. **Click "Register app"**

### **Step 3: Download Configuration Files**

1. **Download `google-services.json`**
2. **Place it in**: `android/app/google-services.json`

### **Step 4: Enable Firebase Services**

In Firebase Console, enable these services:

#### **Authentication**
1. Go to **Authentication** → **Sign-in method**
2. Enable **Email/Password**
3. Enable **Google** (optional)

#### **Firestore Database**
1. Go to **Firestore Database**
2. Click **Create database**
3. Choose **Start in test mode**
4. Select location (closest to your users)

#### **Cloud Messaging**
1. Go to **Cloud Messaging**
2. No additional setup needed

### **Step 5: Update Firebase Options**

Replace the placeholder values in `firebase_options.dart` with your actual Firebase configuration:

```dart
static const FirebaseOptions android = FirebaseOptions(
  apiKey: 'YOUR_ACTUAL_API_KEY',
  appId: 'YOUR_ACTUAL_APP_ID',
  messagingSenderId: 'YOUR_ACTUAL_SENDER_ID',
  projectId: 'YOUR_ACTUAL_PROJECT_ID',
  storageBucket: 'YOUR_ACTUAL_PROJECT_ID.appspot.com',
);
```

### **Step 6: Enable Firebase in Your App**

Uncomment the Firebase initialization in `main.dart`:

```dart
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Rest of your initialization...
}
```

## 📱 **Firebase Services for Your App**

### **Authentication**
- User registration and login
- Google Sign-In integration
- Secure user management

### **Firestore Database**
- Store user data
- SMS message history
- Phishing detection results
- User preferences

### **Cloud Messaging**
- Push notifications
- Real-time alerts
- Background updates

### **Analytics**
- User behavior tracking
- App performance monitoring
- Usage statistics

## 🔧 **Configuration Files Needed**

### **1. google-services.json**
- **Location**: `android/app/google-services.json`
- **Source**: Firebase Console → Project Settings → Your Apps
- **Purpose**: Android app configuration

### **2. firebase_options.dart**
- **Location**: `firebase_options.dart` (root directory)
- **Source**: Firebase Console → Project Settings → General
- **Purpose**: Cross-platform configuration

## 🚀 **Testing Firebase Connection**

After setup, test the connection:

```dart
// Test Firebase connection
try {
  await Firebase.initializeApp();
  print('Firebase initialized successfully!');
} catch (e) {
  print('Firebase initialization failed: $e');
}
```

## 📋 **Checklist**

- [ ] Firebase project created
- [ ] Android app added to project
- [ ] google-services.json downloaded and placed
- [ ] firebase_options.dart updated with real values
- [ ] Firebase services enabled (Auth, Firestore, Messaging)
- [ ] Firebase initialization uncommented in main.dart
- [ ] App builds and runs successfully
- [ ] Firebase connection test passes

## 🆘 **Troubleshooting**

### **Common Issues:**

1. **"Firebase not initialized"**
   - Check if `google-services.json` is in correct location
   - Verify `firebase_options.dart` has correct values

2. **"Project not found"**
   - Verify project ID in `firebase_options.dart`
   - Check if project exists in Firebase Console

3. **"Authentication failed"**
   - Enable Authentication in Firebase Console
   - Check if Email/Password is enabled

4. **"Database permission denied"**
   - Check Firestore security rules
   - Ensure database is created

## 📞 **Need Help?**

1. **Firebase Documentation**: https://firebase.google.com/docs
2. **FlutterFire Documentation**: https://firebase.flutter.dev/
3. **Firebase Console**: https://console.firebase.google.com/

Your app will be fully connected to Firebase once you complete these steps!
