import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/guest_mode_test.dart';
import '../../core/services/supabase_auth_service.dart';
import '../../core/services/connectivity_service.dart';
import '../../core/services/ml_service.dart';

class GuestModeTestScreen extends ConsumerStatefulWidget {
  const GuestModeTestScreen({super.key});

  @override
  ConsumerState<GuestModeTestScreen> createState() => _GuestModeTestScreenState();
}

class _GuestModeTestScreenState extends ConsumerState<GuestModeTestScreen> {
  bool _isTesting = false;
  Map<String, dynamic>? _testResults;
  String _statusMessage = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Guest Mode Test'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.science,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Guest Mode & Online ML Test',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'This test verifies that guest mode works properly with online ML services and internet connectivity.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Current Status
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current Status',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildStatusRow('Guest Mode', SupabaseAuthService.instance.isGuestMode ? 'Enabled' : 'Disabled'),
                    _buildStatusRow('Internet', ConnectivityService.instance.isOnline ? 'Connected' : 'Offline'),
                    _buildStatusRow('ML Service', MLService.instance.serviceMode.toString()),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Test Button
            ElevatedButton(
              onPressed: _isTesting ? null : _runTest,
              child: _isTesting
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 8),
                        Text('Testing...'),
                      ],
                    )
                  : const Text('Run Guest Mode Test'),
            ),
            
            const SizedBox(height: 16),
            
            // Status Message
            if (_statusMessage.isNotEmpty)
              Card(
                color: _statusMessage.contains('SUCCESS') 
                    ? Colors.green.withOpacity(0.1)
                    : _statusMessage.contains('ERROR')
                        ? Colors.red.withOpacity(0.1)
                        : Colors.orange.withOpacity(0.1),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    _statusMessage,
                    style: TextStyle(
                      color: _statusMessage.contains('SUCCESS') 
                          ? Colors.green.shade700
                          : _statusMessage.contains('ERROR')
                              ? Colors.red.shade700
                              : Colors.orange.shade700,
                    ),
                  ),
                ),
              ),
            
            const SizedBox(height: 16),
            
            // Test Results
            if (_testResults != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Test Results',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildTestResult('Connectivity', _testResults!['connectivity']),
                      _buildTestResult('Guest Mode', _testResults!['guestMode']),
                      _buildTestResult('ML Service', _testResults!['mlService']),
                      _buildTestResult('Analysis', _testResults!['analysis']),
                    ],
                  ),
                ),
              ),
            
            const SizedBox(height: 16),
            
            // Instructions
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'What This Test Does',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text('1. Checks internet connectivity'),
                    const Text('2. Enables guest mode'),
                    const Text('3. Initializes ML service in hybrid mode'),
                    const Text('4. Tests SMS analysis with online ML services'),
                    const Text('5. Verifies everything works in guest mode'),
                  ],
                ),
              ),
            ),
          ],
        ),
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
  
  Widget _buildTestResult(String label, dynamic data) {
    if (data == null) return const SizedBox.shrink();
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          if (data is Map)
            ...data.entries.map((entry) => Padding(
              padding: const EdgeInsets.only(left: 16, top: 2),
              child: Text('${entry.key}: ${entry.value}'),
            )),
        ],
      ),
    );
  }
  
  Future<void> _runTest() async {
    setState(() {
      _isTesting = true;
      _testResults = null;
      _statusMessage = 'Running test...';
    });
    
    try {
      final results = await GuestModeTest.instance.testGuestModeWithOnlineML();
      
      setState(() {
        _testResults = results;
        _statusMessage = results['overall']?['message'] ?? 'Test completed';
        _isTesting = false;
      });
      
      // Print results to console for debugging
      GuestModeTest.instance.printTestResults(results);
      
    } catch (e) {
      setState(() {
        _statusMessage = 'Test failed: $e';
        _isTesting = false;
      });
    }
  }
}
