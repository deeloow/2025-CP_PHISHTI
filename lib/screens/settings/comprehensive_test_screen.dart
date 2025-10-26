import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/feature_test_service.dart';
import '../../core/services/supabase_auth_service.dart';
import '../../core/services/connectivity_service.dart';
import '../../core/services/ml_service.dart';

class ComprehensiveTestScreen extends ConsumerStatefulWidget {
  const ComprehensiveTestScreen({super.key});

  @override
  ConsumerState<ComprehensiveTestScreen> createState() => _ComprehensiveTestScreenState();
}

class _ComprehensiveTestScreenState extends ConsumerState<ComprehensiveTestScreen> {
  bool _isRunningTests = false;
  Map<String, dynamic>? _testResults;
  String _currentTest = '';
  final List<String> _testLog = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Comprehensive Feature Test'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        actions: [
          if (_testResults != null)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _isRunningTests ? null : _runAllTests,
              tooltip: 'Run Tests Again',
            ),
        ],
      ),
      body: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.science,
                      color: Theme.of(context).colorScheme.primary,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Comprehensive Feature Test',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Test all app features to ensure everything works correctly',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _isRunningTests ? null : _runAllTests,
                  icon: _isRunningTests
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.play_arrow),
                  label: Text(_isRunningTests ? 'Running Tests...' : 'Run All Tests'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                  ),
                ),
              ],
            ),
          ),
          
          // Current Test Status
          if (_isRunningTests && _currentTest.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: Colors.blue.withOpacity(0.1),
              child: Row(
                children: [
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Testing: $_currentTest',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          
          // Test Results
          Expanded(
            child: _testResults == null
                ? _buildWelcomeView()
                : _buildResultsView(),
          ),
        ],
      ),
    );
  }
  
  Widget _buildWelcomeView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'What This Test Covers',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildTestItem('🔧 Basic Services', 'Service initialization and setup'),
                  _buildTestItem('🌐 Connectivity', 'Internet connection and quality'),
                  _buildTestItem('👤 Guest Mode', 'Guest mode functionality and persistence'),
                  _buildTestItem('🤖 ML Service', 'Machine learning service initialization'),
                  _buildTestItem('📱 SMS Analysis', 'SMS analysis with different message types'),
                  _buildTestItem('🔐 Authentication', 'Authentication flow and guest mode'),
                  _buildTestItem('⚙️ Settings', 'Settings persistence and functionality'),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Current App Status',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildStatusRow('Guest Mode', SupabaseAuthService.instance.isGuestMode ? 'Enabled' : 'Disabled'),
                  _buildStatusRow('Internet', ConnectivityService.instance.isOnline ? 'Connected' : 'Offline'),
                  _buildStatusRow('ML Service', MLService.instance.serviceMode.toString()),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          Card(
            color: Colors.blue.withOpacity(0.1),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info,
                        color: Colors.blue.shade700,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Ready to Test',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Click "Run All Tests" to verify that all features are working correctly. This will test guest mode, online ML services, connectivity, and more.',
                    style: TextStyle(color: Colors.blue.shade700),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildResultsView() {
    final overall = _testResults!['overall'] as Map<String, dynamic>;
    final status = overall['status'] as String;
    final successRate = overall['successRate'] as int;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Overall Status
          Card(
            color: status == 'SUCCESS' 
                ? Colors.green.withOpacity(0.1)
                : status == 'PARTIAL'
                    ? Colors.orange.withOpacity(0.1)
                    : Colors.red.withOpacity(0.1),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        status == 'SUCCESS' 
                            ? Icons.check_circle
                            : status == 'PARTIAL'
                                ? Icons.warning
                                : Icons.error,
                        color: status == 'SUCCESS' 
                            ? Colors.green
                            : status == 'PARTIAL'
                                ? Colors.orange
                                : Colors.red,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Test Results: $status',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: status == 'SUCCESS' 
                                    ? Colors.green.shade700
                                    : status == 'PARTIAL'
                                        ? Colors.orange.shade700
                                        : Colors.red.shade700,
                              ),
                            ),
                            Text(
                              '${overall['successfulTests']}/${overall['totalTests']} tests passed ($successRate%)',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    overall['message'] as String,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Detailed Results
          Text(
            'Detailed Results',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          
          ..._buildDetailedResults(),
          
          const SizedBox(height: 16),
          
          // Test Log
          if (_testLog.isNotEmpty) ...[
            Text(
              'Test Log',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _testLog.map((log) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text(
                      log,
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                    ),
                  )).toList(),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  List<Widget> _buildDetailedResults() {
    final widgets = <Widget>[];
    
    _testResults!.forEach((key, value) {
      if (key != 'overall' && value is Map<String, dynamic>) {
        final status = value['status'] as String? ?? 'UNKNOWN';
        final message = value['message'] as String? ?? 'No message';
        
        widgets.add(
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        status == 'SUCCESS' 
                            ? Icons.check_circle
                            : Icons.error,
                        color: status == 'SUCCESS' 
                            ? Colors.green
                            : Colors.red,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _formatTestName(key),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Text(
                        status,
                        style: TextStyle(
                          color: status == 'SUCCESS' 
                              ? Colors.green
                              : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(message),
                ],
              ),
            ),
          ),
        );
      }
    });
    
    return widgets;
  }
  
  Widget _buildTestItem(String title, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatusRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: value == 'Enabled' || value == 'Connected' 
                  ? Colors.green 
                  : Colors.orange,
            ),
          ),
        ],
      ),
    );
  }
  
  String _formatTestName(String key) {
    switch (key) {
      case 'basicServices': return 'Basic Services';
      case 'connectivity': return 'Connectivity';
      case 'guestMode': return 'Guest Mode';
      case 'mlService': return 'ML Service';
      case 'smsAnalysis': return 'SMS Analysis';
      case 'authentication': return 'Authentication';
      case 'settings': return 'Settings';
      default: return key;
    }
  }
  
  Future<void> _runAllTests() async {
    setState(() {
      _isRunningTests = true;
      _testResults = null;
      _currentTest = '';
      _testLog.clear();
    });
    
    try {
      _addLog('Starting comprehensive feature tests...');
      
      final results = await FeatureTestService.instance.runAllTests();
      
      setState(() {
        _testResults = results;
        _isRunningTests = false;
        _currentTest = '';
      });
      
      _addLog('All tests completed successfully!');
      
      // Print results to console for debugging
      FeatureTestService.instance.printTestResults(results);
      
    } catch (e) {
      setState(() {
        _isRunningTests = false;
        _currentTest = '';
      });
      
      _addLog('Test failed: $e');
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Test failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  void _addLog(String message) {
    setState(() {
      _testLog.add('${DateTime.now().toIso8601String()}: $message');
    });
  }
}
