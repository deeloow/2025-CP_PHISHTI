import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:device_info_plus/device_info_plus.dart';

class DeviceOptimizer {
  static DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
  static String? deviceManufacturer;
  static String? deviceModel;
  static bool isLowEndDevice = false;
  
  static Future<void> initialize() async {
    if (kIsWeb) {
      // Web: use default settings
      deviceManufacturer = 'web';
      deviceModel = 'browser';
      isLowEndDevice = false;
      return;
    }
    
    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
        deviceManufacturer = androidInfo.manufacturer.toLowerCase();
        deviceModel = androidInfo.model.toLowerCase();
        
        // Detect low-end devices
        isLowEndDevice = _isLowEndDevice(androidInfo);
        
        // Apply manufacturer-specific optimizations
        await _applyManufacturerOptimizations();
      }
    } catch (e) {
      print('Error initializing device optimizer: $e');
      // Fallback to default settings
      deviceManufacturer = 'unknown';
      deviceModel = 'unknown';
      isLowEndDevice = false;
    }
  }
  
  static bool _isLowEndDevice(AndroidDeviceInfo info) {
    // Check RAM - use available memory instead of totalMemory
    // For now, we'll use device model detection
    // int totalMemory = info.totalMemory ?? 0;
    // if (totalMemory < 3 * 1024 * 1024 * 1024) { // Less than 3GB
    //   return true;
    // }
    
    // Check for known low-end devices
    List<String> lowEndModels = [
      'redmi', 'xiaomi', 'huawei', 'honor', 'oppo', 'vivo',
      'samsung galaxy j', 'samsung galaxy a', 'motorola',
      'nokia', 'alcatel', 'zte', 'coolpad', 'lenovo'
    ];
    
    for (String model in lowEndModels) {
      if (deviceModel?.contains(model) == true) {
        return true;
      }
    }
    
    return false;
  }
  
  static Future<void> _applyManufacturerOptimizations() async {
    switch (deviceManufacturer) {
      case 'huawei':
        await _applyHuaweiOptimizations();
        break;
      case 'xiaomi':
        await _applyXiaomiOptimizations();
        break;
      case 'samsung':
        await _applySamsungOptimizations();
        break;
      case 'oppo':
      case 'vivo':
        await _applyOppoVivoOptimizations();
        break;
      default:
        await _applyGenericOptimizations();
    }
  }
  
  static Future<void> _applyHuaweiOptimizations() async {
    // Huawei-specific optimizations
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.black,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );
    
    // Disable hardware acceleration for problematic Huawei devices
    if (isLowEndDevice) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    }
  }
  
  static Future<void> _applyXiaomiOptimizations() async {
    // Xiaomi-specific optimizations
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.black,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );
  }
  
  static Future<void> _applySamsungOptimizations() async {
    // Samsung-specific optimizations
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.black,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );
  }
  
  static Future<void> _applyOppoVivoOptimizations() async {
    // Oppo/Vivo-specific optimizations
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.black,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );
  }
  
  static Future<void> _applyGenericOptimizations() async {
    // Generic optimizations for all devices
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.black,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );
  }
  
  static Widget buildOptimizedScaffold({
    required Widget body,
    PreferredSizeWidget? appBar,
    Widget? bottomNavigationBar,
    Widget? floatingActionButton,
  }) {
    return Scaffold(
      appBar: appBar,
      body: isLowEndDevice 
        ? _LowEndDeviceBody(child: body)
        : body,
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
    );
  }
  
  static Widget buildOptimizedListView({
    required List<Widget> children,
    ScrollController? controller,
    bool shrinkWrap = true,
    bool physics = true,
  }) {
    if (isLowEndDevice) {
      return ListView.builder(
        controller: controller,
        shrinkWrap: shrinkWrap,
        physics: physics ? const AlwaysScrollableScrollPhysics() : const NeverScrollableScrollPhysics(),
        itemCount: children.length,
        itemBuilder: (context, index) {
          return _LowEndDeviceListItem(child: children[index]);
        },
      );
    } else {
      return ListView(
        controller: controller,
        shrinkWrap: shrinkWrap,
        physics: physics ? const AlwaysScrollableScrollPhysics() : const NeverScrollableScrollPhysics(),
        children: children,
      );
    }
  }
}

class _LowEndDeviceBody extends StatelessWidget {
  final Widget child;
  
  const _LowEndDeviceBody({required this.child});
  
  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: child,
    );
  }
}

class _LowEndDeviceListItem extends StatelessWidget {
  final Widget child;
  
  const _LowEndDeviceListItem({required this.child});
  
  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: child,
    );
  }
}
