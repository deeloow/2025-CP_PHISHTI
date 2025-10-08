import 'package:flutter/material.dart';

import '../../core/services/url_interceptor_service.dart';

class UrlSafetyIndicator extends StatefulWidget {
  final String url;
  final double size;

  const UrlSafetyIndicator({
    super.key,
    required this.url,
    this.size = 16,
  });

  @override
  State<UrlSafetyIndicator> createState() => _UrlSafetyIndicatorState();
}

class _UrlSafetyIndicatorState extends State<UrlSafetyIndicator> {
  String _safetyStatus = 'checking';

  @override
  void initState() {
    super.initState();
    _checkSafety();
  }

  Future<void> _checkSafety() async {
    final status = await UrlInterceptorService.instance.getUrlSafetyStatus(widget.url);
    if (mounted) {
      setState(() {
        _safetyStatus = status;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return _buildIndicator();
  }

  Widget _buildIndicator() {
    switch (_safetyStatus) {
      case 'blocked':
        return Icon(
          Icons.block,
          size: widget.size,
          color: Colors.red,
        );
      case 'dangerous':
        return Icon(
          Icons.dangerous,
          size: widget.size,
          color: Colors.red.shade700,
        );
      case 'suspicious':
        return Icon(
          Icons.warning,
          size: widget.size,
          color: Colors.orange.shade700,
        );
      case 'caution':
        return Icon(
          Icons.info,
          size: widget.size,
          color: Colors.yellow.shade700,
        );
      case 'safe':
        return Icon(
          Icons.verified_user,
          size: widget.size,
          color: Colors.green.shade700,
        );
      case 'checking':
      default:
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).colorScheme.primary.withOpacity(0.7),
            ),
          ),
        );
    }
  }

  String get statusText {
    switch (_safetyStatus) {
      case 'blocked':
        return 'BLOCKED';
      case 'dangerous':
        return 'DANGEROUS';
      case 'suspicious':
        return 'SUSPICIOUS';
      case 'caution':
        return 'CAUTION';
      case 'safe':
        return 'SAFE';
      case 'checking':
      default:
        return 'CHECKING';
    }
  }

  Color get statusColor {
    switch (_safetyStatus) {
      case 'blocked':
      case 'dangerous':
        return Colors.red;
      case 'suspicious':
        return Colors.orange.shade700;
      case 'caution':
        return Colors.yellow.shade700;
      case 'safe':
        return Colors.green.shade700;
      case 'checking':
      default:
        return Colors.grey;
    }
  }
}
