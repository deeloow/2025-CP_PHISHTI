// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AppUser _$AppUserFromJson(Map<String, dynamic> json) => AppUser(
  id: json['id'] as String,
  email: json['email'] as String,
  displayName: json['displayName'] as String?,
  photoUrl: json['photoUrl'] as String?,
  createdAt: DateTime.parse(json['createdAt'] as String),
  lastLoginAt: DateTime.parse(json['lastLoginAt'] as String),
  preferences: UserPreferences.fromJson(
    json['preferences'] as Map<String, dynamic>,
  ),
  securitySettings: SecuritySettings.fromJson(
    json['securitySettings'] as Map<String, dynamic>,
  ),
);

Map<String, dynamic> _$AppUserToJson(AppUser instance) => <String, dynamic>{
  'id': instance.id,
  'email': instance.email,
  'displayName': instance.displayName,
  'photoUrl': instance.photoUrl,
  'createdAt': instance.createdAt.toIso8601String(),
  'lastLoginAt': instance.lastLoginAt.toIso8601String(),
  'preferences': instance.preferences,
  'securitySettings': instance.securitySettings,
};

UserPreferences _$UserPreferencesFromJson(Map<String, dynamic> json) =>
    UserPreferences(
      darkMode: json['darkMode'] as bool? ?? true,
      language: json['language'] as String? ?? 'en',
      notificationsEnabled: json['notificationsEnabled'] as bool? ?? true,
      cloudSyncEnabled: json['cloudSyncEnabled'] as bool? ?? false,
      phishingThreshold: (json['phishingThreshold'] as num?)?.toDouble() ?? 0.7,
      autoArchiveEnabled: json['autoArchiveEnabled'] as bool? ?? true,
    );

Map<String, dynamic> _$UserPreferencesToJson(UserPreferences instance) =>
    <String, dynamic>{
      'darkMode': instance.darkMode,
      'language': instance.language,
      'notificationsEnabled': instance.notificationsEnabled,
      'cloudSyncEnabled': instance.cloudSyncEnabled,
      'phishingThreshold': instance.phishingThreshold,
      'autoArchiveEnabled': instance.autoArchiveEnabled,
    };

SecuritySettings _$SecuritySettingsFromJson(Map<String, dynamic> json) =>
    SecuritySettings(
      encryptionEnabled: json['encryptionEnabled'] as bool? ?? true,
      biometricEnabled: json['biometricEnabled'] as bool? ?? false,
      sessionTimeout: (json['sessionTimeout'] as num?)?.toInt() ?? 30,
      autoLockEnabled: json['autoLockEnabled'] as bool? ?? true,
      whitelistedSenders:
          (json['whitelistedSenders'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      whitelistedUrls:
          (json['whitelistedUrls'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
    );

Map<String, dynamic> _$SecuritySettingsToJson(SecuritySettings instance) =>
    <String, dynamic>{
      'encryptionEnabled': instance.encryptionEnabled,
      'biometricEnabled': instance.biometricEnabled,
      'sessionTimeout': instance.sessionTimeout,
      'autoLockEnabled': instance.autoLockEnabled,
      'whitelistedSenders': instance.whitelistedSenders,
      'whitelistedUrls': instance.whitelistedUrls,
    };
