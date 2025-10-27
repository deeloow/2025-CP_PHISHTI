import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/services/sms_integration_service.dart';
import '../../core/services/database_service.dart';
import '../../models/sms_message.dart';
import '../widgets/sms_message_tile.dart';
import '../widgets/critical_connectivity_warning.dart';

class SmsScreen extends ConsumerStatefulWidget {
  const SmsScreen({super.key});

  @override
  ConsumerState<SmsScreen> createState() => _SmsScreenState();
}

class _SmsScreenState extends ConsumerState<SmsScreen> with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isLoading = true;
  bool _hasSmsPermissions = false;
  late TabController _tabController;
  
  List<SmsMessage> _allSmsMessages = [];
  List<SmsMessage> _safeMessages = [];
  List<SmsMessage> _maliciousMessages = [];
  List<SmsMessage> _dangerousMessages = [];
  
  // Pagination variables
  static const int _pageSize = 20;
  bool _isLoadingMore = false;
  bool _hasMoreData = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
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
    try {
      // Load analyzed messages from database (both phishing and safe)
      final messages = await DatabaseService.instance.getRecentAnalyzedMessages(limit: 100);
      
      // Categorize messages based on analysis results
      final safeMessages = <SmsMessage>[];
      final maliciousMessages = <SmsMessage>[];
      final dangerousMessages = <SmsMessage>[];
      
      for (final message in messages) {
        if (message.isPhishing) {
          if (message.phishingScore >= 0.8) {
            dangerousMessages.add(message);
          } else {
            maliciousMessages.add(message);
          }
        } else {
          safeMessages.add(message);
        }
      }
      
      setState(() {
        _allSmsMessages = messages;
        _safeMessages = safeMessages;
        _maliciousMessages = maliciousMessages;
        _dangerousMessages = dangerousMessages;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Failed to load analyzed messages: $e');
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

  Future<void> _refreshMessages() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Refresh analyzed messages from database
      await _loadSmsMessages();
      _showSuccessSnackBar('Messages refreshed successfully!');
    } catch (e) {
      _showErrorSnackBar('Error refreshing messages: $e');
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
      body: Column(
        children: [
          // Critical connectivity warning for ML analysis
          const CriticalConnectivityWarning(
            customMessage: 'Internet required for ML analysis',
            showRetryButton: true,
          ),
          // Main content
          Expanded(
            child: CustomScrollView(
              slivers: [
          // App Bar
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            backgroundColor: Theme.of(context).colorScheme.surface,
            actions: [
              IconButton(
                onPressed: _refreshMessages,
                icon: _isLoading 
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh),
                tooltip: 'Refresh Messages',
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

          // Tab Bar
          if (_hasSmsPermissions)
            SliverToBoxAdapter(
              child: Container(
                color: Theme.of(context).colorScheme.surface,
                child: TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  indicatorColor: Theme.of(context).colorScheme.primary,
                  labelColor: Theme.of(context).colorScheme.primary,
                  unselectedLabelColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  tabs: [
                    Tab(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.message_outlined, size: 18),
                          const SizedBox(width: 8),
                          Text('All (${_allSmsMessages.length})'),
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.check_circle_outline, size: 18, color: Colors.green),
                          const SizedBox(width: 8),
                          Text('Safe (${_safeMessages.length})'),
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.warning_outlined, size: 18, color: Colors.orange),
                          const SizedBox(width: 8),
                          Text('Malicious (${_maliciousMessages.length})'),
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.dangerous_outlined, size: 18, color: Colors.red),
                          const SizedBox(width: 8),
                          Text('Dangerous (${_dangerousMessages.length})'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Content
          if (!_hasSmsPermissions)
            _buildPermissionDeniedWidget()
          else
            _buildTabContent(),
              ],
            ),
          ),
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


  Widget _buildTabContent() {
    return SliverFillRemaining(
      child: TabBarView(
        controller: _tabController,
        children: [
          _buildMessageList(_allSmsMessages, 'All Messages'),
          _buildMessageList(_safeMessages, 'Safe Messages'),
          _buildMessageList(_maliciousMessages, 'Malicious Messages'),
          _buildMessageList(_dangerousMessages, 'Dangerous Messages'),
        ],
      ),
    );
  }

  Widget _buildMessageList(List<SmsMessage> messages, String emptyTitle) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (messages.isEmpty) {
      return _EmptyStateWidget(
        icon: Icons.message_outlined,
        title: 'No $emptyTitle',
        message: 'No messages found in this category.',
        actionText: 'Refresh Messages',
        onAction: _refreshMessages,
      );
    }
    
    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification scrollInfo) {
        if (!_isLoadingMore && 
            scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent &&
            _hasMoreData) {
          _loadMoreMessages();
        }
        return false;
      },
      child: ListView.builder(
        itemCount: messages.length + (_isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == messages.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ),
            );
          }
          
          final message = messages[index];
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

  Future<void> _loadMoreMessages() async {
    if (_isLoadingMore || !_hasMoreData) return;
    
    setState(() {
      _isLoadingMore = true;
    });
    
    try {
      final moreMessages = await DatabaseService.instance.getRecentAnalyzedMessages(
        limit: _pageSize,
      );
      
      if (moreMessages.isEmpty) {
        _hasMoreData = false;
      } else {
        // Categorize new messages
        for (final message in moreMessages) {
          if (!_allSmsMessages.any((m) => m.id == message.id)) {
            _allSmsMessages.add(message);
            
            if (message.isPhishing) {
              if (message.phishingScore >= 0.8) {
                _dangerousMessages.add(message);
              } else {
                _maliciousMessages.add(message);
              }
            } else {
              _safeMessages.add(message);
            }
          }
        }
      }
    } catch (e) {
      print('Error loading more messages: $e');
    } finally {
      setState(() {
        _isLoadingMore = false;
      });
    }
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
