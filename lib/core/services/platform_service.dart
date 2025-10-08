import 'dart:io';

class PlatformService {
  static bool get isAndroid => Platform.isAndroid;
  static bool get isIOS => Platform.isIOS;
  static bool get isMobile => isAndroid || isIOS;
  static bool get isDesktop => Platform.isWindows || Platform.isMacOS || Platform.isLinux;
  
  static String get platformName {
    if (isAndroid) return 'android';
    if (isIOS) return 'ios';
    if (Platform.isWindows) return 'windows';
    if (Platform.isMacOS) return 'macos';
    if (Platform.isLinux) return 'linux';
    return 'unknown';
  }
}
