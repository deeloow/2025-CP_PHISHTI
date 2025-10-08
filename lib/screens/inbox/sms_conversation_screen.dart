import 'package:flutter/material.dart';
import '../../core/services/sms_integration_service.dart';
import '../../models/sms_message.dart';
import '../widgets/sms_message_tile.dart';

class SmsConversationScreen extends StatefulWidget {
  final SmsThread thread;

  const SmsConversationScreen({
    super.key,
    required this.thread,
  });

  @override
  State<SmsConversationScreen> createState() => _SmsConversationScreenState();
}

class _SmsConversationScreenState extends State<SmsConversationScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  List<SmsMessage> _messages = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    try {
      final messages = await SmsIntegrationService.instance.getSmsByThread(widget.thread.id);
      setState(() {
        _messages = messages;
        _isLoading = false;
      });
      
      // Scroll to bottom
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      print('Error loading messages: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) {
      return;
    }

    final message = _messageController.text.trim();
    _messageController.clear();

    try {
      final success = await SmsIntegrationService.instance.sendSms(
        widget.thread.phoneNumber,
        message,
      );

      if (success) {
        // Reload messages to show the new one
        await _loadMessages();
      } else {
        _showSnackBar('Failed to send message', Colors.red);
      }
    } catch (e) {
      _showSnackBar('Error sending message: $e', Colors.red);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.thread.contactName.isNotEmpty 
                  ? widget.thread.contactName 
                  : widget.thread.phoneNumber,
              style: const TextStyle(fontSize: 16),
            ),
            if (widget.thread.contactName.isNotEmpty)
              Text(
                widget.thread.phoneNumber,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        actions: [
          if (widget.thread.isPhishing)
            IconButton(
              onPressed: () => _showPhishingWarning(),
              icon: const Icon(Icons.warning, color: Colors.red),
            ),
          PopupMenuButton(
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'mark_read',
                child: const Text('Mark as Read'),
              ),
              PopupMenuItem(
                value: 'delete',
                child: const Text('Delete Conversation'),
              ),
            ],
            onSelected: (value) {
              switch (value) {
                case 'mark_read':
                  _markAsRead();
                  break;
                case 'delete':
                  _deleteConversation();
                  break;
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Phishing Warning Banner
          if (widget.thread.isPhishing)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: Colors.red.withOpacity(0.1),
              child: Row(
                children: [
                  const Icon(Icons.warning, color: Colors.red),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This conversation contains phishing messages. Be cautious!',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          
          // Messages List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? _EmptyConversationState(
                        contactName: widget.thread.contactName.isNotEmpty 
                            ? widget.thread.contactName 
                            : widget.thread.phoneNumber,
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final message = _messages[index];
                          return _MessageBubble(
                            message: message,
                            isFromMe: message.sender == 'Me', // Assuming 'Me' indicates sent messages
                          );
                        },
                      ),
          ),
          
          // Message Input
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(
                top: BorderSide(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                FloatingActionButton.small(
                  onPressed: _sendMessage,
                  child: const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showPhishingWarning() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            const SizedBox(width: 8),
            const Text('Phishing Warning'),
          ],
        ),
        content: const Text(
          'This conversation contains messages that have been flagged as potential phishing attempts. '
          'Be very careful with any links, requests for personal information, or urgent actions. '
          'Never share sensitive information through SMS.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('I Understand'),
          ),
        ],
      ),
    );
  }

  void _markAsRead() {
    // TODO: Implement mark as read functionality
    _showSnackBar('Marked as read', Colors.green);
  }

  void _deleteConversation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Conversation'),
        content: const Text('Are you sure you want to delete this conversation? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
              _showSnackBar('Conversation deleted', Colors.green);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final SmsMessage message;
  final bool isFromMe;

  const _MessageBubble({
    required this.message,
    required this.isFromMe,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: isFromMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isFromMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: message.isPhishing 
                  ? Colors.red.withOpacity(0.1)
                  : Theme.of(context).colorScheme.primary.withOpacity(0.1),
              child: Icon(
                message.isPhishing ? Icons.warning : Icons.person,
                size: 16,
                color: message.isPhishing 
                    ? Colors.red
                    : Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isFromMe
                    ? Theme.of(context).colorScheme.primary
                    : message.isPhishing
                        ? Colors.red.withOpacity(0.1)
                        : Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(18),
                border: message.isPhishing
                    ? Border.all(color: Colors.red.withOpacity(0.3))
                    : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (message.isPhishing) ...[
                    Row(
                      children: [
                        Icon(
                          Icons.warning,
                          size: 16,
                          color: Colors.red,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Phishing Detected',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                  ],
                  Text(
                    message.body,
                    style: TextStyle(
                      color: isFromMe
                          ? Colors.white
                          : Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(message.timestamp),
                    style: TextStyle(
                      color: isFromMe
                          ? Colors.white.withOpacity(0.7)
                          : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isFromMe) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: const Icon(
                Icons.person,
                size: 16,
                color: Colors.white,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays > 0) {
      return '${time.day}/${time.month} ${time.hour}:${time.minute.toString().padLeft(2, '0')}';
    } else if (difference.inHours > 0) {
      return '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Now';
    }
  }
}

class _EmptyConversationState extends StatelessWidget {
  final String contactName;

  const _EmptyConversationState({
    required this.contactName,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.message_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No messages yet',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start a conversation with $contactName',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
