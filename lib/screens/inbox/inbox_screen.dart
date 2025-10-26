import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/services/sms_integration_service.dart';
import '../../models/sms_message.dart';
import '../widgets/sms_message_tile.dart';

class InboxScreen extends ConsumerStatefulWidget {
  const InboxScreen({super.key});

  @override
  ConsumerState<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends ConsumerState<InboxScreen> with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isLoading = true;
  bool _hasSmsPermissions = false;
  
  List<SmsMessage> _allSmsMessages = [];

  @override
  void initState() {
    super.initState();
    _initializeSmsIntegration();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initializeSmsIntegration() async {
    try {
      // Check SMS permissions
      final hasPermissions = await SmsIntegrationService.instance.hasSmsPermissions();
      
      setState(() {
        _hasSmsPermissions = hasPermissions;
        _isLoading = false;
      });

      if (hasPermissions) {
        await _loadSmsMessages();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Error initializing SMS integration: $e');
    }
  }

  Future<void> _loadSmsMessages() async {
    if (_hasSmsPermissions) {
      try {
        // Load all SMS messages from device with sender details
        final messages = await SmsIntegrationService.instance.getAnalyzedSmsMessages();
        
        setState(() {
          _allSmsMessages = messages;
          _isLoading = false;
        });
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        _showErrorSnackBar('Failed to load SMS messages: $e');
      }
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _requestSmsPermissions() async {
    try {
      final granted = await SmsIntegrationService.instance.requestSmsPermissions();
      if (granted) {
        setState(() {
          _hasSmsPermissions = true;
        });
        await _loadSmsMessages();
        _showSuccessSnackBar('SMS permissions granted!');
      } else {
        _showErrorSnackBar('SMS permissions denied');
      }
    } catch (e) {
      _showErrorSnackBar('Error requesting SMS permissions: $e');
    }
  }


  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _syncSmsMessages() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final success = await SmsIntegrationService.instance.syncSmsMessages();
      if (success) {
        _showSuccessSnackBar('SMS messages synced successfully!');
        await _initializeSmsIntegration();
      } else {
        _showErrorSnackBar('Failed to sync SMS messages');
      }
    } catch (e) {
      _showErrorSnackBar('Error syncing messages: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            backgroundColor: Theme.of(context).colorScheme.surface,
            actions: [
              IconButton(
                onPressed: _syncSmsMessages,
                icon: _isLoading 
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.sync),
                tooltip: 'Sync SMS Messages',
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'SMS Messages',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Search Bar
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search messages...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
            ),
          ),

          // Content
          if (!_hasSmsPermissions)
            _buildPermissionDeniedWidget()
          else
            _buildAllSmsMessagesContent(),
        ],
      ),
    );
  }

  Widget _buildPermissionDeniedWidget() {
    return SliverFillRemaining(
      child: _EmptyStateWidget(
        icon: Icons.sms_failed,
        title: 'SMS Permissions Required',
        message: 'To view and send SMS messages, please grant the necessary permissions.',
        actionText: 'Grant Permissions',
        onAction: _requestSmsPermissions,
      ),
    );
  }


  Widget _buildAllSmsMessagesContent() {
    return SliverFillRemaining(
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _allSmsMessages.isEmpty
              ? _EmptyStateWidget(
                  icon: Icons.message_outlined,
                  title: 'No SMS Messages',
                  message: 'No SMS messages found on your device. Grant permissions to view messages.',
                  actionText: 'Grant Permissions',
                  onAction: _requestSmsPermissions,
                )
              : ListView.builder(
                  itemCount: _allSmsMessages.length,
                  itemBuilder: (context, index) {
                    final message = _allSmsMessages[index];
                    if (_searchQuery.isNotEmpty) {
                      if (!message.sender.toLowerCase().contains(_searchQuery.toLowerCase()) &&
                          !message.body.toLowerCase().contains(_searchQuery.toLowerCase())) {
                        return const SizedBox.shrink();
                      }
                    }
                    return SmsMessageTile(
                      message: message,
                      onTap: () {
                        // Navigate to message details or analysis results
                        context.go('/analysis/message/${message.id}', extra: message);
                      },
                    );
                  },
                ),
    );
  }
}

class _EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String actionText;
  final VoidCallback onAction;

  const _EmptyStateWidget({
    required this.icon,
    required this.title,
    required this.message,
    required this.actionText,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onAction,
              icon: Icon(icon),
              label: Text(actionText),
            ),
          ],
        ),
      ),
    );
  }
}
