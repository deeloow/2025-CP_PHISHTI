import 'package:flutter/foundation.dart';

class PlatformService {
  static bool get isAndroid => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  static bool get isIOS => !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;
  static bool get isWeb => kIsWeb;
  static bool get isMobile => isAndroid || isIOS;
  static bool get isDesktop => !kIsWeb && (defaultTargetPlatform == TargetPlatform.windows || 
                                          defaultTargetPlatform == TargetPlatform.macOS || 
                                          defaultTargetPlatform == TargetPlatform.linux);
  
  static String get platformName {
    if (kIsWeb) return 'web';
    if (isAndroid) return 'android';
    if (isIOS) return 'ios';
    if (defaultTargetPlatform == TargetPlatform.windows) return 'windows';
    if (defaultTargetPlatform == TargetPlatform.macOS) return 'macos';
    if (defaultTargetPlatform == TargetPlatform.linux) return 'linux';
    return 'unknown';
  }
}
