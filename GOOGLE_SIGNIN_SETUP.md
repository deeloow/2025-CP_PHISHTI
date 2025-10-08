# 🔐 Google Sign-In Setup Guide

## **Why Google Sign-In Isn't Working**

Your Google Sign-In button isn't working because Firebase project isn't configured with proper OAuth credentials. Here's how to fix it:

## **📋 Prerequisites**
- Google Cloud Console account
- Firebase project created
- Android app registered in Firebase

## **🔧 Step-by-Step Setup**

### **Step 1: Create Firebase Project**
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Create a project"
3. Enter project name: `phishti-detector`
4. Enable Google Analytics (optional)
5. Click "Create project"

### **Step 2: Add Android App to Firebase**
1. In Firebase Console, click "Add app" → Android
2. Enter package name: `com.example.phishti_detector`
3. Enter app nickname: `Phishti Detector`
4. Click "Register app"
5. Download `google-services.json` file
6. Place it in `android/app/` directory

### **Step 3: Enable Google Sign-In**
1. In Firebase Console, go to "Authentication"
2. Click "Get started"
3. Go to "Sign-in method" tab
4. Enable "Google" provider
5. Enter project support email
6. Click "Save"

### **Step 4: Configure OAuth Consent Screen**
1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Select your Firebase project
3. Go to "APIs & Services" → "OAuth consent screen"
4. Choose "External" user type
5. Fill in required information:
   - App name: `Phishti Detector`
   - User support email: Your email
   - Developer contact: Your email
6. Click "Save and Continue"

### **Step 5: Create OAuth 2.0 Credentials**
1. Go to "APIs & Services" → "Credentials"
2. Click "Create Credentials" → "OAuth 2.0 Client IDs"
3. Choose "Android" application type
4. Enter package name: `com.example.phishti_detector`
5. Enter SHA-1 fingerprint (see below for how to get it)
6. Click "Create"
7. Copy the generated client ID

### **Step 6: Get SHA-1 Fingerprint**
Run this command in your project directory:
```bash
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```

### **Step 7: Update Firebase Configuration**
1. Replace the content of `lib/firebase_options.dart` with your actual Firebase configuration
2. Update `android/app/google-services.json` with your downloaded file

### **Step 8: Test Google Sign-In**
1. Run the app: `flutter run`
2. Try Google Sign-In
3. Check if it works

## **🚨 Common Issues & Solutions**

### **Issue 1: "Google Sign-In cancelled"**
- **Cause**: User cancelled the sign-in process
- **Solution**: This is normal behavior, not an error

### **Issue 2: "Google sign in error: PlatformException"**
- **Cause**: Missing OAuth credentials or wrong package name
- **Solution**: Verify package name matches in Firebase and Google Cloud Console

### **Issue 3: "Google sign in error: SignInFailedException"**
- **Cause**: SHA-1 fingerprint mismatch
- **Solution**: Update SHA-1 fingerprint in Google Cloud Console

### **Issue 4: "Google sign in error: NetworkException"**
- **Cause**: No internet connection or Firebase not configured
- **Solution**: Check internet connection and Firebase configuration

## **📱 Alternative: Use Email/Password Authentication**

If Google Sign-In continues to have issues, you can use email/password authentication:

1. **Register with Email/Password**:
   - Go to Register screen
   - Enter email and password
   - Click "Sign Up"

2. **Login with Email/Password**:
   - Go to Login screen
   - Enter email and password
   - Click "Sign In"

## **✅ Verification Steps**

After setup, verify:
1. ✅ Firebase project created
2. ✅ Android app registered
3. ✅ Google Sign-In enabled
4. ✅ OAuth credentials created
5. ✅ SHA-1 fingerprint added
6. ✅ google-services.json updated
7. ✅ firebase_options.dart configured

## **🆘 Still Having Issues?**

If Google Sign-In still doesn't work:
1. Check Firebase Console for error logs
2. Verify all configuration steps
3. Try email/password authentication instead
4. Contact support with specific error messages

---

**Note**: This setup is required for Google Sign-In to work. Without proper Firebase configuration, the Google Sign-In button will fail silently.
