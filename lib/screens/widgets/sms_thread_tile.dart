import 'package:flutter/material.dart';
import '../../core/services/sms_integration_service.dart';
import '../../models/sms_message.dart';

class SmsThreadTile extends StatelessWidget {
  final SmsThread thread;
  final VoidCallback onTap;

  const SmsThreadTile({
    super.key,
    required this.thread,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: thread.isPhishing 
              ? Colors.red.withOpacity(0.1)
              : Theme.of(context).colorScheme.primary.withOpacity(0.1),
          child: Icon(
            thread.isPhishing ? Icons.warning : Icons.person,
            color: thread.isPhishing 
                ? Colors.red
                : Theme.of(context).colorScheme.primary,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                thread.contactName.isNotEmpty ? thread.contactName : thread.phoneNumber,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: thread.unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
            if (thread.unreadCount > 0) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  thread.unreadCount.toString(),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    thread.lastMessage,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: thread.unreadCount > 0 ? FontWeight.w500 : FontWeight.normal,
                      color: thread.isPhishing 
                          ? Colors.red
                          : Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _formatTime(thread.lastMessageTime),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
            if (thread.isPhishing) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.warning,
                      size: 12,
                      color: Colors.red,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Phishing Detected',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        trailing: thread.isPhishing
            ? Icon(
                Icons.warning,
                color: Colors.red,
                size: 20,
              )
            : Icon(
                Icons.chevron_right,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
              ),
        onTap: onTap,
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Now';
    }
  }
}
