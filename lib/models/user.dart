import 'package:json_annotation/json_annotation.dart';

part 'user.g.dart';

@JsonSerializable()
class AppUser {
  final String id;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final DateTime createdAt;
  final DateTime lastLoginAt;
  final UserPreferences preferences;
  final SecuritySettings securitySettings;

  const AppUser({
    required this.id,
    required this.email,
    this.displayName,
    this.photoUrl,
    required this.createdAt,
    required this.lastLoginAt,
    required this.preferences,
    required this.securitySettings,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) => _$AppUserFromJson(json);

  Map<String, dynamic> toJson() => _$AppUserToJson(this);

  AppUser copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoUrl,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    UserPreferences? preferences,
    SecuritySettings? securitySettings,
  }) {
    return AppUser(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      preferences: preferences ?? this.preferences,
      securitySettings: securitySettings ?? this.securitySettings,
    );
  }
}

@JsonSerializable()
class UserPreferences {
  final bool darkMode;
  final String language;
  final bool notificationsEnabled;
  final bool cloudSyncEnabled;
  final double phishingThreshold;
  final bool autoArchiveEnabled;

  const UserPreferences({
    this.darkMode = true,
    this.language = 'en',
    this.notificationsEnabled = true,
    this.cloudSyncEnabled = false,
    this.phishingThreshold = 0.7,
    this.autoArchiveEnabled = true,
  });

  factory UserPreferences.fromJson(Map<String, dynamic> json) =>
      _$UserPreferencesFromJson(json);

  Map<String, dynamic> toJson() => _$UserPreferencesToJson(this);

  UserPreferences copyWith({
    bool? darkMode,
    String? language,
    bool? notificationsEnabled,
    bool? cloudSyncEnabled,
    double? phishingThreshold,
    bool? autoArchiveEnabled,
  }) {
    return UserPreferences(
      darkMode: darkMode ?? this.darkMode,
      language: language ?? this.language,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      cloudSyncEnabled: cloudSyncEnabled ?? this.cloudSyncEnabled,
      phishingThreshold: phishingThreshold ?? this.phishingThreshold,
      autoArchiveEnabled: autoArchiveEnabled ?? this.autoArchiveEnabled,
    );
  }
}

@JsonSerializable()
class SecuritySettings {
  final bool encryptionEnabled;
  final bool biometricEnabled;
  final int sessionTimeout; // in minutes
  final bool autoLockEnabled;
  final List<String> whitelistedSenders;
  final List<String> whitelistedUrls;

  const SecuritySettings({
    this.encryptionEnabled = true,
    this.biometricEnabled = false,
    this.sessionTimeout = 30,
    this.autoLockEnabled = true,
    this.whitelistedSenders = const [],
    this.whitelistedUrls = const [],
  });

  factory SecuritySettings.fromJson(Map<String, dynamic> json) =>
      _$SecuritySettingsFromJson(json);

  Map<String, dynamic> toJson() => _$SecuritySettingsToJson(this);

  SecuritySettings copyWith({
    bool? encryptionEnabled,
    bool? biometricEnabled,
    int? sessionTimeout,
    bool? autoLockEnabled,
    List<String>? whitelistedSenders,
    List<String>? whitelistedUrls,
  }) {
    return SecuritySettings(
      encryptionEnabled: encryptionEnabled ?? this.encryptionEnabled,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      sessionTimeout: sessionTimeout ?? this.sessionTimeout,
      autoLockEnabled: autoLockEnabled ?? this.autoLockEnabled,
      whitelistedSenders: whitelistedSenders ?? this.whitelistedSenders,
      whitelistedUrls: whitelistedUrls ?? this.whitelistedUrls,
    );
  }
}
