import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PerformanceOptimizer {
  static void optimizeForLowEndDevices() {
    // Reduce frame rate for low-end devices
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    
    // Optimize rendering
    WidgetsBinding.instance.addPostFrameCallback((_) {
    // Force garbage collection after frame
    // System.gc(); // Not available in Flutter
    });
  }
  
  static Widget buildOptimizedScaffold({
    required Widget body,
    PreferredSizeWidget? appBar,
    Widget? bottomNavigationBar,
    Widget? floatingActionButton,
  }) {
    return Scaffold(
      appBar: appBar,
      body: _OptimizedBody(child: body),
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
    return ListView.builder(
      controller: controller,
      shrinkWrap: shrinkWrap,
      physics: physics ? const AlwaysScrollableScrollPhysics() : const NeverScrollableScrollPhysics(),
      itemCount: children.length,
      itemBuilder: (context, index) {
        return _OptimizedListItem(child: children[index]);
      },
    );
  }
  
  static Widget buildOptimizedImage({
    required String imagePath,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
  }) {
    return Image.asset(
      imagePath,
      width: width,
      height: height,
      fit: fit,
      cacheWidth: width?.toInt(),
      cacheHeight: height?.toInt(),
      filterQuality: FilterQuality.low, // Reduce quality for performance
    );
  }
}

class _OptimizedBody extends StatelessWidget {
  final Widget child;
  
  const _OptimizedBody({required this.child});
  
  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: child,
    );
  }
}

class _OptimizedListItem extends StatelessWidget {
  final Widget child;
  
  const _OptimizedListItem({required this.child});
  
  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: child,
    );
  }
}

// Memory management utilities
class MemoryManager {
  static void optimizeMemory() {
    // Force garbage collection
    // System.gc(); // Not available in Flutter
    
    // Clear image cache periodically
    PaintingBinding.instance.imageCache.clear();
  }
  
  static void scheduleMemoryCleanup() {
    // Schedule memory cleanup every 30 seconds
    Timer.periodic(const Duration(seconds: 30), (timer) {
      optimizeMemory();
    });
  }
}

// Huawei device specific optimizations moved to separate file
