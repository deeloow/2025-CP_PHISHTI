import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/sms_provider.dart';
import '../../core/services/sms_integration_service.dart';
import '../../core/services/auth_service.dart';
import '../../models/sms_message.dart';
import '../widgets/sms_message_tile.dart';
import '../widgets/sms_thread_tile.dart';
import 'sms_composer_screen.dart';
import 'sms_conversation_screen.dart';

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
  bool _isDefaultSmsApp = false;
  
  late TabController _tabController;
  List<SmsThread> _smsThreads = [];
  List<SmsMessage> _allMessages = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initializeSmsIntegration();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _initializeSmsIntegration() async {
    try {
      // Check SMS permissions
      final hasPermissions = await SmsIntegrationService.instance.hasSmsPermissions();
      final isDefault = await SmsIntegrationService.instance.isDefaultSmsApp();
      
      setState(() {
        _hasSmsPermissions = hasPermissions;
        _isDefaultSmsApp = isDefault;
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
        final messages = await SmsIntegrationService.instance.getAllSmsMessages();
        final threads = await SmsIntegrationService.instance.getSmsThreads();
        
        setState(() {
          _allMessages = messages;
          _smsThreads = threads;
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

  Future<void> _requestSetAsDefaultSmsApp() async {
    try {
      final success = await SmsIntegrationService.instance.requestSetAsDefaultSmsApp();
      if (success) {
        setState(() {
          _isDefaultSmsApp = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please set PhishTi as your default SMS app in device settings'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      print('Error requesting to set as default SMS app: $e');
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
              IconButton(
                onPressed: () => context.go('/inbox/compose'),
                icon: const Icon(Icons.add_comment),
                tooltip: 'New Message',
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'Messages',
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
                  fillColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
            ),
          ),

          // Tab Bar
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Theme.of(context).colorScheme.primary,
                ),
                labelColor: Theme.of(context).colorScheme.onPrimary,
                unselectedLabelColor: Theme.of(context).colorScheme.onSurface,
                tabs: const [
                  Tab(text: 'Conversations'),
                  Tab(text: 'All Messages'),
                ],
              ),
            ),
          ),

          // Content
          if (!_hasSmsPermissions)
            _buildPermissionDeniedWidget()
          else if (!_isDefaultSmsApp)
            _buildDefaultSmsAppPrompt()
          else
            _buildMessagesContent(),
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

  Widget _buildDefaultSmsAppPrompt() {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Set as Default SMS App',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'To enable full SMS functionality, including receiving new messages, please set PhishTi as your default SMS app in your device settings.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _requestSetAsDefaultSmsApp,
              icon: const Icon(Icons.app_settings_alt),
              label: const Text('Open Settings'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessagesContent() {
    return SliverFillRemaining(
      child: TabBarView(
        controller: _tabController,
        children: [
          // Conversations Tab
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _smsThreads.isEmpty
                  ? _EmptyStateWidget(
                      icon: Icons.chat_bubble_outline,
                      title: 'No Conversations',
                      message: 'Start a conversation by sending a message.',
                      actionText: 'New Message',
                      onAction: () => context.go('/inbox/compose'),
                    )
                  : ListView.builder(
                      itemCount: _smsThreads.length,
                      itemBuilder: (context, index) {
                        final thread = _smsThreads[index];
                        if (_searchQuery.isNotEmpty) {
                          if (!thread.contactName.toLowerCase().contains(_searchQuery.toLowerCase()) &&
                              !thread.snippet.toLowerCase().contains(_searchQuery.toLowerCase())) {
                            return const SizedBox.shrink();
                          }
                        }
                        return SmsThreadTile(
                          thread: thread,
                          onTap: () {
                            context.go('/inbox/conversation/${thread.id}', extra: thread);
                          },
                        );
                      },
                    ),

          // All Messages Tab
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _allMessages.isEmpty
                  ? _EmptyStateWidget(
                      icon: Icons.message_outlined,
                      title: 'No Messages',
                      message: 'No SMS messages found on your device.',
                      actionText: 'Sync Messages',
                      onAction: _syncSmsMessages,
                    )
                  : ListView.builder(
                      itemCount: _allMessages.length,
                      itemBuilder: (context, index) {
                        final message = _allMessages[index];
                        if (_searchQuery.isNotEmpty) {
                          if (!message.sender.toLowerCase().contains(_searchQuery.toLowerCase()) &&
                              !message.body.toLowerCase().contains(_searchQuery.toLowerCase())) {
                            return const SizedBox.shrink();
                          }
                        }
                        return SmsMessageTile(
                          message: message,
                          onTap: () {
                            if (message.threadId != null) {
                              context.go('/inbox/conversation/${message.threadId}');
                            }
                          },
                        );
                      },
                    ),
        ],
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
