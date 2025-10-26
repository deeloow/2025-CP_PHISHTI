# Supabase Setup Guide for PhishTi Detector

This guide will help you set up Supabase for your PhishTi Detector Flutter app, replacing Firebase and PHP authentication.

## Prerequisites

- A Supabase account (sign up at [supabase.com](https://supabase.com))
- Flutter development environment set up
- Basic understanding of PostgreSQL and Supabase

## Step 1: Create a Supabase Project

1. Go to [supabase.com](https://supabase.com) and sign in
2. Click "New Project"
3. Choose your organization
4. Enter project details:
   - **Name**: `phishti-detector`
   - **Database Password**: Choose a strong password
   - **Region**: Select the closest region to your users
5. Click "Create new project"
6. Wait for the project to be set up (this may take a few minutes)

## Step 2: Get Your Project Credentials

1. In your Supabase dashboard, go to **Settings** → **API**
2. Copy the following values:
   - **Project URL** (e.g., `https://your-project-id.supabase.co`)
   - **anon public** key (starts with `eyJ...`)
   - **service_role** key (starts with `eyJ...`) - keep this secret!

## Step 3: Configure Your Flutter App

1. Open `lib/supabase_options.dart`
2. Replace the placeholder values with your actual credentials:

```dart
class SupabaseOptions {
  static const String supabaseUrl = 'https://your-project-id.supabase.co';
  static const String supabaseAnonKey = 'your-anon-key-here';
  static const String supabaseServiceRoleKey = 'your-service-role-key-here';
  // ... other configurations
}
```

## Step 4: Set Up Database Schema

Run the following SQL in your Supabase SQL Editor (Dashboard → SQL Editor):

```sql
-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Create users table
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

-- Create SMS analyses table
CREATE TABLE sms_analyses (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  sms_content TEXT NOT NULL,
  analysis_result JSONB NOT NULL,
  risk_score DECIMAL(3,2),
  risk_level TEXT CHECK (risk_level IN ('low', 'medium', 'high')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create phishing detections table
CREATE TABLE phishing_detections (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  detection_data JSONB NOT NULL,
  risk_score DECIMAL(3,2),
  risk_level TEXT CHECK (risk_level IN ('low', 'medium', 'high')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create ML models table
CREATE TABLE ml_models (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  model_name TEXT NOT NULL,
  model_version TEXT NOT NULL,
  model_data JSONB NOT NULL,
  accuracy DECIMAL(5,4),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for better performance
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_sms_analyses_user_id ON sms_analyses(user_id);
CREATE INDEX idx_sms_analyses_created_at ON sms_analyses(created_at);
CREATE INDEX idx_phishing_detections_user_id ON phishing_detections(user_id);
CREATE INDEX idx_phishing_detections_created_at ON phishing_detections(created_at);
CREATE INDEX idx_ml_models_created_at ON ml_models(created_at);

-- Enable Row Level Security (RLS)
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE sms_analyses ENABLE ROW LEVEL SECURITY;
ALTER TABLE phishing_detections ENABLE ROW LEVEL SECURITY;
ALTER TABLE ml_models ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
-- Users can only access their own data
CREATE POLICY "Users can view own profile" ON users
  FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON users
  FOR UPDATE USING (auth.uid() = id);

-- SMS analyses policies
CREATE POLICY "Users can view own SMS analyses" ON sms_analyses
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own SMS analyses" ON sms_analyses
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own SMS analyses" ON sms_analyses
  FOR DELETE USING (auth.uid() = user_id);

-- Phishing detections policies
CREATE POLICY "Users can view own phishing detections" ON phishing_detections
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own phishing detections" ON phishing_detections
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own phishing detections" ON phishing_detections
  FOR DELETE USING (auth.uid() = user_id);

-- ML models are public read-only
CREATE POLICY "Anyone can view ML models" ON ml_models
  FOR SELECT USING (true);
```

## Step 5: Configure Authentication

1. In your Supabase dashboard, go to **Authentication** → **Settings**
2. Configure the following:

### Email Settings
1. Click on **Emails** under the **CONFIGURATION** section
2. Enable the following settings:
   - **Enable email confirmations**: ON
   - **Enable email change confirmations**: ON
   - **Enable secure email change**: ON

### SMTP Configuration
In the **Emails** section, configure your SMTP settings:

1. **SMTP Host**: `smtp.gmail.com` (if using Gmail)
2. **SMTP Port**: `587`
3. **SMTP User**: Your Gmail address
4. **SMTP Password**: Your Gmail app password (not your regular password)
5. **SMTP Admin Email**: Your admin email
6. **SMTP Sender Name**: "PhishTi Detector"

### OAuth Providers
- **Google**: Enable and configure with your Google OAuth credentials
- **Apple**: Enable if you plan to support iOS

### URL Configuration
- **Site URL**: `http://localhost:3000` (for development)
- **Redirect URLs**: Add your app's redirect URLs

## Step 6: Configure Storage (Optional)

If you plan to store files (like user avatars):

1. Go to **Storage** in your Supabase dashboard
2. Create a new bucket called `user-avatars`
3. Set up appropriate policies for file access

## Step 7: Test Your Setup

1. Run your Flutter app
2. Check the console for "✅ Supabase initialized successfully"
3. Try signing up with a test email
4. Check your Supabase dashboard to see if the user was created

## Step 8: Environment Variables (Production)

For production, store your credentials securely:

1. Create a `.env` file (don't commit this to version control)
2. Add your credentials:
```
SUPABASE_URL=https://your-project-id.supabase.co
SUPABASE_ANON_KEY=your-anon-key
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key
```

## Troubleshooting

### Common Issues

1. **"Invalid API key"**: Check that you copied the correct anon key
2. **"Project not found"**: Verify your project URL is correct
3. **RLS policies blocking access**: Check that your RLS policies are correctly configured
4. **Google Sign-In not working**: Verify your Google OAuth configuration

### Debug Mode

Enable debug logging in your Flutter app:

```dart
// In your main.dart
Supabase.initialize(
  url: SupabaseOptions.supabaseUrl,
  anonKey: SupabaseOptions.supabaseAnonKey,
  debug: kDebugMode, // Enable debug mode
);
```

## Migration from Firebase/PHP

### Data Migration

If you have existing data in Firebase or your PHP database:

1. Export your data from Firebase Firestore
2. Transform the data to match the new Supabase schema
3. Import the data using Supabase's SQL editor or API

### Code Changes

The main changes in your codebase:
- `AuthService` → `SupabaseAuthService`
- `DatabaseService` → `SupabaseDatabaseService`
- Firebase imports → Supabase imports
- Firestore queries → Supabase queries

## Security Best Practices

1. **Never expose your service role key** in client-side code
2. **Use RLS policies** to secure your data
3. **Validate all inputs** on both client and server
4. **Use HTTPS** in production
5. **Regularly rotate your API keys**

## Support

- [Supabase Documentation](https://supabase.com/docs)
- [Supabase Discord](https://discord.supabase.com)
- [Flutter Supabase Package](https://pub.dev/packages/supabase_flutter)

## Next Steps

1. Update your app's authentication screens to use the new Supabase service
2. Test all authentication flows (sign up, sign in, password reset)
3. Update your database operations to use Supabase
4. Remove Firebase and PHP dependencies
5. Deploy and test in production

---

**Note**: Remember to update your `supabase_options.dart` file with your actual credentials before running the app!
