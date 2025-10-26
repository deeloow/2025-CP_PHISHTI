# SMS Sharing Integration Guide for PhishTi

This guide explains how to use the SMS sharing integration feature that allows users to analyze suspicious SMS messages directly from their phone's SMS app.

## 🎯 **What This Enables**

- **Share SMS from any SMS app** to PhishTi for analysis
- **Long-press SMS** → Share → PhishTi appears in share menu
- **Instant phishing detection** using ML models
- **Auto-archive phishing messages** to protect users
- **Seamless integration** with existing SMS workflow

## 📱 **How to Use SMS Sharing**

### **Step 1: Share SMS from SMS App**
1. **Open your SMS app** (Messages, WhatsApp, Telegram, etc.)
2. **Long-press** on any suspicious SMS message
3. **Tap "Share"** from the context menu
4. **Select "PhishTi Detector"** from the share options

### **Step 2: Automatic Analysis**
1. **PhishTi opens automatically** with the shared SMS content
2. **ML analysis runs immediately** using DistilBERT or online services
3. **Results displayed instantly** with confidence score and indicators
4. **Auto-archive if phishing** detected (based on user settings)

### **Step 3: Review Results**
- **Green result**: Message appears legitimate
- **Red result**: Phishing detected and auto-archived
- **Detailed analysis**: Shows confidence score and specific indicators
- **Save option**: Store analysis results in database

## 🔧 **Technical Implementation**

### **Android Integration**
The app registers as a text sharing target in the Android manifest:

```xml
<!-- SMS Share Intent Filter -->
<intent-filter>
    <action android:name="android.intent.action.SEND" />
    <category android:name="android.intent.category.DEFAULT" />
    <data android:mimeType="text/plain" />
</intent-filter>

<!-- SMS Text Share Intent Filter -->
<intent-filter>
    <action android:name="android.intent.action.SEND" />
    <category android:name="android.intent.category.DEFAULT" />
    <data android:mimeType="text/*" />
</intent-filter>
```

### **Intent Handling**
- **MainActivity** receives shared text via intent
- **SmsShareService** processes the shared content
- **ML analysis** runs automatically
- **Results displayed** in dedicated analysis screen

### **Auto-Archive Integration**
- **Phishing messages** automatically archived (if enabled)
- **Safe messages** stored normally
- **User settings** control auto-archive behavior
- **Database integration** for persistent storage

## 🛡️ **Security Features**

### **Immediate Protection**
- **Phishing messages** never reach user's inbox
- **Auto-archived** to prevent accidental interaction
- **Notifications** inform user about detected threats
- **Sender blocking** for high-confidence phishing

### **Analysis Capabilities**
- **ML-based detection** using DistilBERT
- **URL analysis** for suspicious links
- **Pattern recognition** for common phishing techniques
- **Confidence scoring** for accurate results

## 📊 **User Experience Flow**

```
SMS App → Long Press → Share → PhishTi → Analysis → Results
    ↓
[If Phishing] → Auto-Archive → Notification → User Protected
    ↓
[If Safe] → Store in Database → User Can Review
```

## ⚙️ **Configuration Options**

### **Auto-Archive Settings**
Users can control the auto-archive behavior:

- **Enabled (Default)**: Phishing messages auto-archived
- **Disabled**: Phishing detected but message remains in inbox
- **Threshold Control**: Confidence level for auto-archiving

### **Analysis Settings**
- **ML Model Selection**: DistilBERT, online services, or rule-based
- **Confidence Threshold**: Minimum confidence for phishing detection
- **Notification Preferences**: Control alert behavior

## 🧪 **Testing the Integration**

### **Test with Sample Messages**

**High Confidence Phishing:**
```
"URGENT: Your account will be suspended. Click here to verify: bit.ly/verify-now"
"Congratulations! You won $1000. Claim now: suspicious-site.com"
"Your bank account needs verification. Reply with your PIN immediately."
```

**Low Confidence (Legitimate):**
```
"Your package has been delivered. Tracking: UPS123456"
"Reminder: Your appointment is tomorrow at 2 PM"
"Thank you for your purchase. Receipt attached."
```

### **Expected Results**
- **Phishing messages**: Red alert, auto-archived, high confidence score
- **Legitimate messages**: Green result, stored normally, low confidence score

## 🔄 **Integration with Existing Features**

### **ML Service Integration**
- **DistilBERT analysis** for best accuracy
- **Online ML services** as fallback
- **Rule-based detection** as last resort
- **Consistent results** across all analysis methods

### **Database Integration**
- **Shared SMS stored** in database
- **Analysis results** linked to messages
- **Archive integration** for phishing messages
- **Statistics tracking** for shared content

### **Notification System**
- **Immediate alerts** for phishing detection
- **Detailed information** about threats
- **User education** about phishing indicators
- **Protection confirmation** for auto-archived messages

## 📱 **Supported SMS Apps**

The sharing integration works with any SMS app that supports Android's standard sharing mechanism:

- **Google Messages**
- **Samsung Messages**
- **WhatsApp**
- **Telegram**
- **Signal**
- **Any SMS app** with share functionality

## 🚀 **Benefits for Users**

### **Convenience**
- **No app switching** required
- **Instant analysis** from SMS context
- **Seamless workflow** integration
- **One-tap sharing** for analysis

### **Protection**
- **Immediate threat detection**
- **Auto-archiving** prevents exposure
- **Educational feedback** about threats
- **Proactive security** measures

### **Flexibility**
- **Works with any SMS app**
- **Configurable settings**
- **Optional auto-archiving**
- **Manual review** when needed

## 🔧 **Troubleshooting**

### **PhishTi Not Appearing in Share Menu**
1. **Check app installation** - Ensure PhishTi is properly installed
2. **Restart device** - Sometimes required for intent registration
3. **Check permissions** - Ensure app has necessary permissions
4. **Reinstall app** - If sharing still doesn't work

### **Analysis Not Working**
1. **Check ML service** - Ensure ML models are initialized
2. **Check internet** - Online services require connectivity
3. **Check permissions** - Ensure app has required permissions
4. **Restart app** - Sometimes service initialization is needed

### **Auto-Archive Not Working**
1. **Check settings** - Verify auto-archive is enabled
2. **Check confidence** - Ensure detection confidence > threshold
3. **Check database** - Verify database service is working
4. **Check logs** - Look for error messages in debug output

## 📋 **Files Modified**

### **Android Integration**
- `android/app/src/main/AndroidManifest.xml` - Intent filters for sharing
- `android/app/src/main/kotlin/.../MainActivity.kt` - Intent handling

### **Flutter Integration**
- `lib/core/services/sms_share_service.dart` - Share service implementation
- `lib/screens/analysis/shared_sms_analysis_screen.dart` - Analysis UI
- `lib/core/router/app_router.dart` - Route configuration
- `lib/main.dart` - Service initialization

## 🎉 **Result**

Your PhishTi app now provides **complete SMS sharing integration**:

1. **Users can share any SMS** from any SMS app to PhishTi
2. **Instant ML analysis** using DistilBERT or online services
3. **Automatic protection** through auto-archiving of phishing messages
4. **Seamless user experience** with no app switching required
5. **Educational feedback** about phishing threats and indicators

**Users now have a powerful tool to analyze suspicious SMS messages directly from their SMS app, with automatic protection against phishing threats!**
