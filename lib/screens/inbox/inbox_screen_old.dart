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
      });

      if (hasPermissions) {
        await _loadSmsData();
      }
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error initializing SMS integration: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadSmsData() async {
    try {
      // Load SMS threads (conversations)
      final threads = await SmsIntegrationService.instance.getAllSmsThreads();
      
      // Load all messages for the "All Messages" tab
      final messages = await SmsIntegrationService.instance.getAllSmsMessages();
      
      setState(() {
        _smsThreads = threads;
        _allMessages = messages;
      });
    } catch (e) {
      print('Error loading SMS data: $e');
    }
  }

  Future<void> _requestSmsPermissions() async {
    try {
      await SmsIntegrationService.instance.initialize();
      await _initializeSmsIntegration();
    } catch (e) {
      print('Error requesting SMS permissions: $e');
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
            actions: [
              IconButton(
                onPressed: () => _showSettingsDialog(),
                icon: const Icon(Icons.settings),
              ),
            ],
          ),
          
          // Content
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Permission Status Banner
                if (!_hasSmsPermissions) ...[
                  _PermissionBanner(
                    title: 'SMS Access Required',
                    message: 'Grant SMS permissions to view and send messages',
                    actionText: 'Grant Permissions',
                    onAction: _requestSmsPermissions,
                    icon: Icons.security,
                    color: Colors.orange,
                  ),
                  const SizedBox(height: 16),
                ],
                
                // Default SMS App Banner
                if (_hasSmsPermissions && !_isDefaultSmsApp) ...[
                  _PermissionBanner(
                    title: 'Set as Default SMS App',
                    message: 'Set PhishTi as your default SMS app for full functionality',
                    actionText: 'Set as Default',
                    onAction: _requestSetAsDefaultSmsApp,
                    icon: Icons.message,
                    color: Colors.blue,
                  ),
                  const SizedBox(height: 16),
                ],
                
                // Tab Bar
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                    ),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    ),
                    labelColor: Theme.of(context).colorScheme.primary,
                    unselectedLabelColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    tabs: const [
                      Tab(text: 'Conversations'),
                      Tab(text: 'All Messages'),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Tab Content
                SizedBox(
                  height: MediaQuery.of(context).size.height - 300,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // Conversations Tab
                      _buildConversationsTab(),
                      
                      // All Messages Tab
                      _buildAllMessagesTab(),
                    ],
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
      floatingActionButton: _hasSmsPermissions
          ? FloatingActionButton.extended(
              onPressed: () => _navigateToComposer(),
              icon: const Icon(Icons.message),
              label: const Text('New Message'),
            )
          : null,
    );
  }

  Widget _buildConversationsTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_smsThreads.isEmpty) {
      return _EmptyState(
        icon: Icons.message_outlined,
        title: 'No Conversations',
        message: 'Start a conversation by sending a message',
        actionText: 'New Message',
        onAction: _navigateToComposer,
      );
    }

    return ListView.builder(
      itemCount: _smsThreads.length,
      itemBuilder: (context, index) {
        final thread = _smsThreads[index];
        return SmsThreadTile(
          thread: thread,
          onTap: () => _navigateToConversation(thread),
        );
      },
    );
  }

  Widget _buildAllMessagesTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_allMessages.isEmpty) {
      return _EmptyState(
        icon: Icons.inbox_outlined,
        title: 'No Messages',
        message: 'No SMS messages found',
        actionText: 'Refresh',
        onAction: _loadSmsData,
      );
    }

    // Filter messages based on search query
    final filteredMessages = _searchQuery.isEmpty
        ? _allMessages
        : _allMessages.where((message) {
            return message.sender.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                   message.body.toLowerCase().contains(_searchQuery.toLowerCase());
          }).toList();

    return Column(
      children: [
        // Search Bar
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search messages...',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _searchQuery = '';
                      });
                    },
                    icon: const Icon(Icons.clear),
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
            });
          },
        ),
        
        const SizedBox(height: 16),
        
        // Messages List
        Expanded(
          child: ListView.builder(
            itemCount: filteredMessages.length,
            itemBuilder: (context, index) {
              final message = filteredMessages[index];
              return SmsMessageTile(
                message: message,
                onTap: () => _navigateToMessageDetails(message),
              );
            },
          ),
        ),
      ],
    );
  }

  void _navigateToComposer() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const SmsComposerScreen(),
      ),
    );
  }

  void _navigateToConversation(SmsThread thread) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SmsConversationScreen(thread: thread),
      ),
    );
  }

  void _navigateToMessageDetails(SmsMessage message) {
    // Show message details dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Message Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('From: ${message.sender}'),
            Text('Time: ${message.timestamp.toString()}'),
            Text('Type: ${message.messageType.name.toUpperCase()}'),
            if (message.isPhishing) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '⚠️ Phishing Detected',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text('Score: ${(message.phishingScore * 100).toStringAsFixed(1)}%'),
                    if (message.reason != null) Text('Reason: ${message.reason}'),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 8),
            Text('Message: ${message.body}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('SMS Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Permissions: ${_hasSmsPermissions ? "Granted" : "Not Granted"}'),
            Text('Default SMS App: ${_isDefaultSmsApp ? "Yes" : "No"}'),
            const SizedBox(height: 16),
            if (!_hasSmsPermissions)
              ElevatedButton(
                onPressed: _requestSmsPermissions,
                child: const Text('Grant Permissions'),
              ),
            if (_hasSmsPermissions && !_isDefaultSmsApp)
              ElevatedButton(
                onPressed: _requestSetAsDefaultSmsApp,
                child: const Text('Set as Default SMS App'),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _PermissionBanner extends StatelessWidget {
  final String title;
  final String message;
  final String actionText;
  final VoidCallback onAction;
  final IconData icon;
  final Color color;

  const _PermissionBanner({
    required this.title,
    required this.message,
    required this.actionText,
    required this.onAction,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: onAction,
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
            ),
            child: Text(actionText),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String actionText;
  final VoidCallback onAction;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
    required this.actionText,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
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
    );
  }
}