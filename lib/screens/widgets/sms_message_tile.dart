import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../models/sms_message.dart';
import '../../core/services/sms_service.dart';
import '../../core/services/ml_service.dart';
import '../../core/services/url_interceptor_service.dart';
import 'url_safety_indicator.dart';

class SmsMessageTile extends StatelessWidget {
  final SmsMessage message;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const SmsMessageTile({
    super.key,
    required this.message,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar
              CircleAvatar(
                radius: 20,
                backgroundColor: _getAvatarColor(message.sender),
                child: Text(
                  _getInitials(message.sender),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Message Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Sender and Time
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            message.sender,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Text(
                          _formatTime(message.timestamp),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 4),
                    
                    // Message Body with URL handling
                    _buildMessageBody(context),
                    
                    // Status indicators
                    if (message.isPhishing) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.error.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'PHISHING',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.error,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${(message.phishingScore * 100).toStringAsFixed(0)}% Risk',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.error,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              
              // Status Icon
              if (message.isPhishing)
                Icon(
                  Icons.block,
                  color: Theme.of(context).colorScheme.error,
                  size: 20,
                )
              else
                Icon(
                  Icons.check_circle,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getAvatarColor(String sender) {
    final hash = sender.hashCode;
    final colors = [
      const Color(0xFF00FF88),
      const Color(0xFF00D4FF),
      const Color(0xFFFF6B6B),
      const Color(0xFFFFB347),
      const Color(0xFF9C27B0),
      const Color(0xFF3F51B5),
    ];
    return colors[hash.abs() % colors.length];
  }

  String _getInitials(String sender) {
    if (sender.isEmpty) return '?';
    
    final words = sender.split(' ');
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    } else {
      return sender.substring(0, 1).toUpperCase();
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 0) {
      return DateFormat('MMM d').format(dateTime);
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'Now';
    }
  }

  Widget _buildMessageBody(BuildContext context) {
    if (message.extractedUrls.isEmpty) {
      return Text(
        message.body,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          message.body,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        if (message.extractedUrls.isNotEmpty) ...[
          const SizedBox(height: 8),
          ...message.extractedUrls.map((url) => _buildUrlChip(context, url)),
        ],
      ],
    );
  }

  Widget _buildUrlChip(BuildContext context, String url) {
    return FutureBuilder<bool>(
      future: SmsService.instance.isUrlBlocked(url),
      builder: (context, snapshot) {
        final isBlocked = snapshot.data ?? false;
        
        return Container(
          margin: const EdgeInsets.only(bottom: 4),
          child: InkWell(
            onTap: () => _handleUrlTap(context, url, isBlocked),
            onLongPress: () => _showUrlOptions(context, url, isBlocked),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isBlocked 
                    ? Theme.of(context).colorScheme.error.withOpacity(0.1)
                    : Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isBlocked 
                      ? Theme.of(context).colorScheme.error.withOpacity(0.3)
                      : Theme.of(context).colorScheme.primary.withOpacity(0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isBlocked ? Icons.block : Icons.link,
                    size: 16,
                    color: isBlocked 
                        ? Theme.of(context).colorScheme.error
                        : Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      _truncateUrl(url),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isBlocked 
                            ? Theme.of(context).colorScheme.error
                            : Theme.of(context).colorScheme.primary,
                        decoration: isBlocked ? TextDecoration.lineThrough : null,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isBlocked) ...[
                    const SizedBox(width: 4),
                    Text(
                      'BLOCKED',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.error,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ] else ...[
                    const SizedBox(width: 4),
                    UrlSafetyIndicator(
                      url: url,
                      size: 12,
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _truncateUrl(String url) {
    if (url.length <= 30) return url;
    return '${url.substring(0, 27)}...';
  }

  void _handleUrlTap(BuildContext context, String url, bool isBlocked) async {
    // Always intercept URL clicks and route through security analysis
    final handled = await UrlInterceptorService.instance.interceptUrl(
      context,
      url,
      messageId: message.id,
      sender: message.sender,
      forceAnalysis: isBlocked, // Force analysis even for blocked URLs if user clicks
    );
    
    if (!handled) {
      _showSnackBar(context, 'Failed to process URL: $url');
    }
  }

  void _showUrlOptions(BuildContext context, String url, bool isBlocked) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'URL Options',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Text(
              url,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            if (!isBlocked) ...[
              ListTile(
                leading: const Icon(Icons.security),
                title: const Text('Analyze & Open URL'),
                subtitle: const Text('Security check before opening'),
                onTap: () {
                  Navigator.pop(context);
                  _handleUrlTap(context, url, false);
                },
              ),
              ListTile(
                leading: const Icon(Icons.block),
                title: const Text('Block URL'),
                onTap: () async {
                  Navigator.pop(context);
                  await SmsService.instance.blockUrl(url, reason: 'Blocked by user');
                  _showSnackBar(context, 'URL blocked successfully');
                },
              ),
            ] else ...[
              ListTile(
                leading: const Icon(Icons.security),
                title: const Text('Analyze Blocked URL'),
                subtitle: const Text('Review security assessment'),
                onTap: () {
                  Navigator.pop(context);
                  _handleUrlTap(context, url, true);
                },
              ),
              ListTile(
                leading: const Icon(Icons.check_circle),
                title: const Text('Unblock URL'),
                onTap: () async {
                  Navigator.pop(context);
                  await SmsService.instance.unblockUrl(url);
                  _showSnackBar(context, 'URL unblocked successfully');
                },
              ),
            ],
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Copy URL'),
              onTap: () {
                Navigator.pop(context);
                Clipboard.setData(ClipboardData(text: url));
                _showSnackBar(context, 'URL copied to clipboard');
              },
            ),
            ListTile(
              leading: const Icon(Icons.info),
              title: const Text('Analyze URL'),
              onTap: () async {
                Navigator.pop(context);
                final analysis = await MLService.instance.analyzeUrl(url);
                _showUrlAnalysis(context, url, analysis);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showUrlAnalysis(BuildContext context, String url, Map<String, dynamic> analysis) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('URL Analysis'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('URL: $url'),
            const SizedBox(height: 8),
            Text('Threat Level: ${analysis['threatLevel']}'),
            Text('Confidence: ${(analysis['confidence'] * 100).toStringAsFixed(1)}%'),
            const SizedBox(height: 8),
            if (analysis['indicators'].isNotEmpty) ...[
              const Text('Indicators:', style: TextStyle(fontWeight: FontWeight.bold)),
              ...analysis['indicators'].map<Widget>((indicator) => Text('• $indicator')),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
