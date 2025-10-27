import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/connectivity_service.dart';

/// Widget that shows a warning banner when there's no internet connection
class ConnectivityWarningWidget extends ConsumerStatefulWidget {
  const ConnectivityWarningWidget({super.key});

  @override
  ConsumerState<ConnectivityWarningWidget> createState() => _ConnectivityWarningWidgetState();
}

class _ConnectivityWarningWidgetState extends ConsumerState<ConnectivityWarningWidget> {
  bool _isOnline = true;

  @override
  void initState() {
    super.initState();
    _isOnline = ConnectivityService.instance.isOnline;
    
    // Listen to connectivity changes
    ConnectivityService.instance.connectivityStream.listen((isOnline) {
      if (mounted) {
        setState(() {
          _isOnline = isOnline;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Only show warning when offline
    if (_isOnline) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.red.shade600,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            Icons.wifi_off,
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'No Internet Connection',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Icon(
            Icons.error_outline,
            color: Colors.white,
            size: 20,
          ),
        ],
      ),
    );
  }
}

/// Animated connectivity warning that slides down from top
class AnimatedConnectivityWarning extends StatefulWidget {
  const AnimatedConnectivityWarning({super.key});

  @override
  State<AnimatedConnectivityWarning> createState() => _AnimatedConnectivityWarningState();
}

class _AnimatedConnectivityWarningState extends State<AnimatedConnectivityWarning>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    
    // Listen to connectivity changes
    ConnectivityService.instance.connectivityStream.listen((isOnline) {
      if (mounted) {
        if (!isOnline) {
          _animationController.forward();
        } else {
          _animationController.reverse();
        }
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: ConnectivityWarningWidget(),
    );
  }
}
