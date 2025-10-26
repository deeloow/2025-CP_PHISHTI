# Migration from Firebase/PHP to Supabase - Summary

## Overview
This document summarizes the migration of the PhishTi Detector app from Firebase and PHP authentication to Supabase.

## Changes Made

### 1. Dependencies Updated
- **Removed**: Firebase dependencies (`firebase_core`, `firebase_auth`, `cloud_firestore`, `firebase_messaging`)
- **Added**: Supabase dependency (`supabase_flutter: ^2.5.6`)

### 2. Configuration Files
- **Created**: `lib/supabase_options.dart` - Supabase configuration
- **Removed**: `lib/firebase_options.dart` - Firebase configuration
- **Created**: `SUPABASE_SETUP_GUIDE.md` - Setup instructions

### 3. Authentication Service
- **Created**: `lib/core/services/supabase_auth_service.dart` - New Supabase authentication service
- **Removed**: `lib/core/services/auth_service.dart` - Old Firebase authentication service
- **Removed**: `lib/core/services/php_auth_service.dart` - PHP authentication service

### 4. Database Service
- **Created**: `lib/core/services/supabase_database_service.dart` - New Supabase database service
- **Updated**: Database operations to use Supabase instead of Firestore

### 5. Updated Files
- **`lib/main.dart`**: Updated to initialize Supabase instead of Firebase
- **`lib/core/providers/auth_provider.dart`**: Updated to use Supabase authentication
- **`lib/screens/auth/login_screen.dart`**: Updated to use Supabase authentication
- **`lib/screens/auth/register_screen.dart`**: Updated to use Supabase authentication

### 6. Removed Files
- **`backend/`**: Entire PHP backend directory removed
- **`lib/firebase_options.dart`**: Firebase configuration removed
- **`firebase_options.dart`**: Firebase configuration removed
- **`lib/core/services/firebase_test_service.dart`**: Firebase test service removed

## Database Schema

The new Supabase database includes the following tables:

### Users Table
```sql
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  email TEXT UNIQUE NOT NULL,
  display_name TEXT,
  photo_url TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  last_login TIMESTAMP WITH TIME ZONE,
  is_verified BOOLEAN DEFAULT FALSE,
  preferences JSONB DEFAULT '{}',
  security_settings JSONB DEFAULT '{}'
);
```

### SMS Analyses Table
```sql
CREATE TABLE sms_analyses (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  sms_content TEXT NOT NULL,
  analysis_result JSONB NOT NULL,
  risk_score DECIMAL(3,2),
  risk_level TEXT CHECK (risk_level IN ('low', 'medium', 'high')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

### Phishing Detections Table
```sql
CREATE TABLE phishing_detections (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  detection_data JSONB NOT NULL,
  risk_score DECIMAL(3,2),
  risk_level TEXT CHECK (risk_level IN ('low', 'medium', 'high')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

### ML Models Table
```sql
CREATE TABLE ml_models (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  model_name TEXT NOT NULL,
  model_version TEXT NOT NULL,
  model_data JSONB NOT NULL,
  accuracy DECIMAL(5,4),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

## Security Features

### Row Level Security (RLS)
- All tables have RLS enabled
- Users can only access their own data
- ML models are publicly readable

### Authentication
- Email/password authentication
- Google OAuth integration
- Email verification
- Password reset functionality

## Benefits of Migration

### 1. Simplified Architecture
- Single backend service (Supabase) instead of Firebase + PHP
- Reduced complexity and maintenance overhead

### 2. Better Database
- PostgreSQL instead of Firestore
- SQL queries instead of NoSQL
- Better performance for complex queries

### 3. Real-time Features
- Built-in real-time subscriptions
- Better real-time performance

### 4. Open Source
- Supabase is open source
- More transparency and control

### 5. Cost Efficiency
- Potentially lower costs
- Better pricing model

## Next Steps

### 1. Configure Supabase
1. Create a Supabase project
2. Update `lib/supabase_options.dart` with your credentials
3. Run the database schema SQL in Supabase

### 2. Test the Migration
1. Test user registration
2. Test user login
3. Test Google Sign-In
4. Test password reset
5. Test guest mode functionality

### 3. Data Migration (if needed)
If you have existing data in Firebase:
1. Export data from Firebase
2. Transform data to match new schema
3. Import data into Supabase

### 4. Update Environment
1. Update any environment variables
2. Update deployment configurations
3. Update CI/CD pipelines

## Files to Update

### Required Configuration
- `lib/supabase_options.dart` - Add your Supabase credentials

### Optional Updates
- Update any hardcoded Firebase references
- Update documentation
- Update tests

## Troubleshooting

### Common Issues
1. **"Invalid API key"**: Check Supabase credentials
2. **"Project not found"**: Verify project URL
3. **RLS blocking access**: Check RLS policies
4. **Google Sign-In not working**: Configure OAuth in Supabase

### Debug Mode
Enable debug logging:
```dart
Supabase.initialize(
  url: SupabaseOptions.supabaseUrl,
  anonKey: SupabaseOptions.supabaseAnonKey,
  debug: kDebugMode,
);
```

## Support

- [Supabase Documentation](https://supabase.com/docs)
- [Flutter Supabase Package](https://pub.dev/packages/supabase_flutter)
- [Supabase Discord](https://discord.supabase.com)

---

**Note**: Remember to update your `supabase_options.dart` file with your actual Supabase credentials before running the app!
