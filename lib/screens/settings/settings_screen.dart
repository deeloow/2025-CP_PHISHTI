import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/auth_provider.dart';
import '../../core/providers/sms_provider.dart';
import '../../core/providers/ml_provider.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/biometric_service.dart';
import '../../models/user.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _cloudSyncEnabled = false;
  bool _autoArchiveEnabled = true;
  double _phishingThreshold = 0.7;
  bool _encryptionEnabled = true;
  bool _biometricEnabled = false;
  
  bool get isGuestMode => AuthService.instance.isGuestMode;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _initializeBiometric();
  }

  void _loadSettings() {
    if (isGuestMode) {
      // Load default settings for guest mode
      _loadGuestModeSettings();
    } else {
      // Load settings from provider for authenticated users
      final currentUser = ref.read(currentAppUserProvider);
      currentUser.whenData((user) {
        if (user != null) {
          setState(() {
            _notificationsEnabled = user.preferences.notificationsEnabled;
            _cloudSyncEnabled = user.preferences.cloudSyncEnabled;
            _autoArchiveEnabled = user.preferences.autoArchiveEnabled;
            _phishingThreshold = user.preferences.phishingThreshold;
            _encryptionEnabled = user.securitySettings.encryptionEnabled;
            _biometricEnabled = user.securitySettings.biometricEnabled;
          });
        }
      });
    }
  }
  
  void _loadGuestModeSettings() {
    // Set default settings for guest mode
    setState(() {
      _notificationsEnabled = true;
      _cloudSyncEnabled = false; // Not available in guest mode
      _autoArchiveEnabled = true;
      _phishingThreshold = 0.7;
      _encryptionEnabled = true;
      _biometricEnabled = false; // Not available in guest mode
    });
  }
  
  Future<void> _initializeBiometric() async {
    try {
      await BiometricService.instance.initialize();
      final isEnabled = await BiometricService.instance.isBiometricEnabledInSettings();
      setState(() {
        _biometricEnabled = isEnabled;
      });
    } catch (e) {
      print('Error initializing biometric: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentAppUserProvider);
    final modelStatus = ref.watch(modelStatusProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            backgroundColor: Theme.of(context).colorScheme.background,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'Settings',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onBackground,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                    ],
                  ),
                ),
              ),
            ),
          ),
          
          // Settings Content
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Guest Mode Banner
                if (isGuestMode) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).colorScheme.primary.withOpacity(0.1),
                          Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.person_outline,
                              color: Theme.of(context).colorScheme.primary,
                              size: 24,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Guest Mode',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'You\'re using the app in guest mode. Some features are limited. Sign in to unlock full functionality:',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _FeatureItem(
                              icon: Icons.security,
                              text: 'Enhanced security and encryption',
                            ),
                            _FeatureItem(
                              icon: Icons.sync,
                              text: 'Cross-device synchronization',
                            ),
                            _FeatureItem(
                              icon: Icons.person,
                              text: 'Personalized settings and preferences',
                            ),
                            _FeatureItem(
                              icon: Icons.cloud,
                              text: 'Cloud backup and restore',
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => context.go('/auth/login'),
                                icon: const Icon(Icons.login, size: 16),
                                label: const Text('Sign In'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => context.go('/auth/register'),
                                icon: const Icon(Icons.person_add, size: 16),
                                label: const Text('Create Account'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
                
                // User Profile Section
                _SettingsSection(
                  title: 'Profile',
                  children: [
                    if (isGuestMode)
                      _GuestProfileTile(
                        onSignIn: () => context.go('/auth/login'),
                        onSignUp: () => context.go('/auth/register'),
                      )
                    else
                      currentUser.when(
                        data: (user) => _UserProfileTile(
                          user: user,
                          onTap: () => _showProfileDialog(context, user),
                        ),
                        loading: () => const _LoadingTile(),
                        error: (_, __) => const _ErrorTile(),
                      ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Security Settings
                _SettingsSection(
                  title: 'Security',
                  children: [
                    _SwitchTile(
                      title: 'Encryption',
                      subtitle: 'Encrypt local data',
                      value: _encryptionEnabled,
                      onChanged: (value) {
                        setState(() {
                          _encryptionEnabled = value;
                        });
                        _updateSecuritySettings();
                      },
                      icon: Icons.lock,
                    ),
                    if (!isGuestMode)
                      _SwitchTile(
                        title: 'Biometric Authentication',
                        subtitle: 'Use fingerprint or face unlock',
                        value: _biometricEnabled,
                        onChanged: (value) async {
                          if (value) {
                            // Enable biometric authentication
                            final success = await _enableBiometricAuthentication();
                            if (success) {
                              setState(() {
                                _biometricEnabled = true;
                              });
                              _updateSecuritySettings();
                            }
                          } else {
                            // Disable biometric authentication
                            final success = await _disableBiometricAuthentication();
                            if (success) {
                              setState(() {
                                _biometricEnabled = false;
                              });
                              _updateSecuritySettings();
                            }
                          }
                        },
                        icon: Icons.fingerprint,
                      )
                    else
                      _GuestRestrictedTile(
                        title: 'Biometric Authentication',
                        subtitle: 'Sign in to use fingerprint or face unlock',
                        icon: Icons.fingerprint,
                        onSignIn: () => context.go('/auth/login'),
                        onSignUp: () => context.go('/auth/register'),
                      ),
                    _ListTile(
                      title: 'Whitelist',
                      subtitle: 'Manage trusted senders and URLs',
                      icon: Icons.verified_user,
                      onTap: () => _showWhitelistDialog(context),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Detection Settings
                _SettingsSection(
                  title: 'Detection',
                  children: [
                    _SliderTile(
                      title: 'Phishing Threshold',
                      subtitle: 'Sensitivity level for phishing detection',
                      value: _phishingThreshold,
                      min: 0.1,
                      max: 1.0,
                      divisions: 9,
                      onChanged: (value) {
                        setState(() {
                          _phishingThreshold = value;
                        });
                        _updatePreferences();
                      },
                    ),
                    _SwitchTile(
                      title: 'Auto Archive',
                      subtitle: 'Automatically archive detected phishing messages',
                      value: _autoArchiveEnabled,
                      onChanged: (value) {
                        setState(() {
                          _autoArchiveEnabled = value;
                        });
                        _updatePreferences();
                      },
                      icon: Icons.archive,
                    ),
                    _ListTile(
                      title: 'ML Models',
                      subtitle: modelStatus.isLoaded ? 'Models loaded' : 'Loading models...',
                      icon: Icons.psychology,
                      onTap: () => _showModelStatusDialog(context),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Notification Settings
                _SettingsSection(
                  title: 'Notifications',
                  children: [
                    _SwitchTile(
                      title: 'Push Notifications',
                      subtitle: 'Receive notifications for phishing detections',
                      value: _notificationsEnabled,
                      onChanged: (value) {
                        setState(() {
                          _notificationsEnabled = value;
                        });
                        _updatePreferences();
                      },
                      icon: Icons.notifications,
                    ),
                    _ListTile(
                      title: 'Notification Settings',
                      subtitle: 'Configure notification preferences',
                      icon: Icons.settings,
                      onTap: () => _showNotificationSettingsDialog(context),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Cloud Sync Settings (only for authenticated users)
                if (!isGuestMode) ...[
                  _SettingsSection(
                    title: 'Cloud Sync',
                    children: [
                      _SwitchTile(
                        title: 'Cloud Sync',
                        subtitle: 'Sync phishing signatures across devices',
                        value: _cloudSyncEnabled,
                        onChanged: (value) {
                          setState(() {
                            _cloudSyncEnabled = value;
                          });
                          _updatePreferences();
                        },
                        icon: Icons.cloud_sync,
                      ),
                      _ListTile(
                        title: 'Sync Status',
                        subtitle: _cloudSyncEnabled ? 'Last synced: 2 hours ago' : 'Sync disabled',
                        icon: Icons.sync,
                        onTap: () => _showSyncStatusDialog(context),
                      ),
                    ],
                  ),
                ] else ...[
                  // Guest mode cloud sync prompt
                  _SettingsSection(
                    title: 'Cloud Sync',
                    children: [
                      _GuestRestrictedTile(
                        title: 'Cloud Sync',
                        subtitle: 'Sign in to sync your data across devices',
                        icon: Icons.cloud_sync,
                        onSignIn: () => context.go('/auth/login'),
                        onSignUp: () => context.go('/auth/register'),
                      ),
                    ],
                  ),
                ],
                
                const SizedBox(height: 24),
                
                // App Settings
                _SettingsSection(
                  title: 'App',
                  children: [
                    _ListTile(
                      title: 'About',
                      subtitle: 'Version 1.0.0',
                      icon: Icons.info,
                      onTap: () => _showAboutDialog(context),
                    ),
                    _ListTile(
                      title: 'Privacy Policy',
                      subtitle: 'How we protect your data',
                      icon: Icons.privacy_tip,
                      onTap: () => _showPrivacyPolicyDialog(context),
                    ),
                    _ListTile(
                      title: 'Terms of Service',
                      subtitle: 'App usage terms',
                      icon: Icons.description,
                      onTap: () => _showTermsDialog(context),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Danger Zone (only for authenticated users)
                if (!isGuestMode) ...[
                  _SettingsSection(
                    title: 'Danger Zone',
                    children: [
                      _ListTile(
                        title: 'Clear All Data',
                        subtitle: 'Delete all messages and settings',
                        icon: Icons.delete_forever,
                        onTap: () => _showClearDataDialog(context),
                        textColor: Theme.of(context).colorScheme.error,
                      ),
                      _ListTile(
                        title: 'Logout',
                        subtitle: 'Sign out of your account',
                        icon: Icons.logout,
                        onTap: () => _showLogoutDialog(context),
                        textColor: Theme.of(context).colorScheme.error,
                      ),
                    ],
                  ),
                ] else ...[
                  // Guest mode danger zone prompt
                  _SettingsSection(
                    title: 'Danger Zone',
                    children: [
                      _GuestRestrictedTile(
                        title: 'Account Management',
                        subtitle: 'Sign in to manage your account and data',
                        icon: Icons.security,
                        onSignIn: () => context.go('/auth/login'),
                        onSignUp: () => context.go('/auth/register'),
                      ),
                    ],
                  ),
                ],
                
                const SizedBox(height: 32),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  void _updatePreferences() {
    if (isGuestMode) {
      // For guest mode, just save to local storage
      _saveGuestModeSettings();
    } else {
      // For authenticated users, update user preferences
      final currentUser = ref.read(currentAppUserProvider);
      currentUser.whenData((user) {
        if (user != null) {
          final updatedPreferences = user.preferences.copyWith(
            notificationsEnabled: _notificationsEnabled,
            cloudSyncEnabled: _cloudSyncEnabled,
            autoArchiveEnabled: _autoArchiveEnabled,
            phishingThreshold: _phishingThreshold,
          );
          ref.read(userPreferencesProvider.notifier).updatePreferences(updatedPreferences);
        }
      });
    }
  }
  
  void _saveGuestModeSettings() {
    // Save guest mode settings to local storage
    // This would typically use SharedPreferences or similar
    print('Saving guest mode settings: notifications=$_notificationsEnabled, autoArchive=$_autoArchiveEnabled, threshold=$_phishingThreshold');
  }
  
  /// Enable biometric authentication
  Future<bool> _enableBiometricAuthentication() async {
    try {
      // Check if biometric is available
      final isAvailable = await BiometricService.instance.isBiometricAvailable();
      if (!isAvailable) {
        _showBiometricErrorDialog(
          'Biometric Not Available',
          'Biometric authentication is not available on this device. Please ensure your device supports fingerprint or face recognition.',
        );
        return false;
      }
      
      // Show biometric setup dialog
      final success = await BiometricService.instance.showBiometricSetupDialog(context);
      return success;
    } catch (e) {
      _showBiometricErrorDialog(
        'Setup Error',
        'An error occurred while setting up biometric authentication: $e',
      );
      return false;
    }
  }
  
  /// Disable biometric authentication
  Future<bool> _disableBiometricAuthentication() async {
    try {
      // Show confirmation dialog
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Disable Biometric Authentication'),
          content: const Text(
            'Are you sure you want to disable biometric authentication? You will need to use your password to access the app.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Disable'),
            ),
          ],
        ),
      );
      
      if (confirmed == true) {
        final success = await BiometricService.instance.disableBiometric();
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Biometric authentication disabled'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return success;
      }
      
      return false;
    } catch (e) {
      _showBiometricErrorDialog(
        'Disable Error',
        'An error occurred while disabling biometric authentication: $e',
      );
      return false;
    }
  }
  
  /// Show biometric error dialog
  void _showBiometricErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.error,
              color: Colors.red,
            ),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _updateSecuritySettings() {
    final currentUser = ref.read(currentAppUserProvider);
    currentUser.whenData((user) {
      if (user != null) {
        final updatedSettings = user.securitySettings.copyWith(
          encryptionEnabled: _encryptionEnabled,
          biometricEnabled: _biometricEnabled,
        );
        ref.read(securitySettingsProvider.notifier).updateSecuritySettings(updatedSettings);
      }
    });
  }

  void _showProfileDialog(BuildContext context, AppUser? user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (user != null) ...[
              CircleAvatar(
                radius: 40,
                backgroundImage: user.photoUrl != null ? NetworkImage(user.photoUrl!) : null,
                child: user.photoUrl == null ? Text(user.displayName?[0] ?? 'U') : null,
              ),
              const SizedBox(height: 16),
              Text(
                user.displayName ?? 'Unknown User',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(user.email),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showWhitelistDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Whitelist'),
        content: const Text('Manage your whitelisted senders and URLs here.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showModelStatusDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ML Model Status'),
        content: const Text('SMS Classification Model: Loaded\nURL Detection Model: Loaded'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showNotificationSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notification Settings'),
        content: const Text('Configure your notification preferences here.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showSyncStatusDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sync Status'),
        content: const Text('Last sync: 2 hours ago\nStatus: Connected'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About Phishti Detector'),
        content: const Text('Version 1.0.0\nAI-powered SMS phishing protection'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showPrivacyPolicyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy Policy'),
        content: const Text('Your privacy is important to us. We only store hashed signatures in the cloud, never raw messages.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showTermsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Terms of Service'),
        content: const Text('By using this app, you agree to our terms of service.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showClearDataDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Data'),
        content: const Text('This will permanently delete all your messages and settings. This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Handle clear data
            },
            child: const Text('Clear Data'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(authServiceProvider).signOut();
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsSection({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
            ),
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }
}

class _UserProfileTile extends StatelessWidget {
  final AppUser? user;

  const _UserProfileTile({required this.user, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundImage: user?.photoUrl != null ? NetworkImage(user!.photoUrl!) : null,
        child: user?.photoUrl == null ? Text(user?.displayName?[0] ?? 'U') : null,
      ),
      title: Text(user?.displayName ?? 'Unknown User'),
      subtitle: Text(user?.email ?? ''),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

class _LoadingTile extends StatelessWidget {
  const _LoadingTile();

  @override
  Widget build(BuildContext context) {
    return const ListTile(
      leading: CircularProgressIndicator(),
      title: Text('Loading...'),
    );
  }
}

class _ErrorTile extends StatelessWidget {
  const _ErrorTile();

  @override
  Widget build(BuildContext context) {
    return const ListTile(
      leading: Icon(Icons.error),
      title: Text('Error loading profile'),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final IconData icon;

  const _SwitchTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
      ),
    );
  }
}

class _ListTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final Color? textColor;

  const _ListTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: textColor),
      title: Text(title, style: TextStyle(color: textColor)),
      subtitle: Text(subtitle, style: TextStyle(color: textColor)),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

class _SliderTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final ValueChanged<double> onChanged;

  const _SliderTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.tune),
      title: Text(title),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(subtitle),
          const SizedBox(height: 8),
          Row(
            children: [
              Text('${(value * 100).toStringAsFixed(0)}%'),
              const Spacer(),
              Text('${(min * 100).toStringAsFixed(0)}%'),
              const SizedBox(width: 8),
              Expanded(
                child: Slider(
                  value: value,
                  min: min,
                  max: max,
                  divisions: divisions,
                  onChanged: onChanged,
                ),
              ),
              Text('${(max * 100).toStringAsFixed(0)}%'),
            ],
          ),
        ],
      ),
    );
  }
}

class _GuestRestrictedTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onSignIn;
  final VoidCallback onSignUp;

  const _GuestRestrictedTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onSignIn,
    required this.onSignUp,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: Theme.of(context).colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.lock_outline,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onSignIn,
                  icon: const Icon(Icons.login, size: 16),
                  label: const Text('Sign In'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onSignUp,
                  icon: const Icon(Icons.person_add, size: 16),
                  label: const Text('Sign Up'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _FeatureItem({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GuestProfileTile extends StatelessWidget {
  final VoidCallback onSignIn;
  final VoidCallback onSignUp;

  const _GuestProfileTile({
    required this.onSignIn,
    required this.onSignUp,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            child: Icon(
              Icons.person_outline,
              size: 30,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Guest User',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Sign in to access your profile and settings',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onSignIn,
                  icon: const Icon(Icons.login, size: 16),
                  label: const Text('Sign In'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onSignUp,
                  icon: const Icon(Icons.person_add, size: 16),
                  label: const Text('Sign Up'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
