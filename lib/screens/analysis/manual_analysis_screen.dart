import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/services/ml_service.dart';
import '../../core/services/sms_service.dart';
import '../../models/sms_message.dart';
import '../../models/phishing_detection.dart';
import '../widgets/url_safety_indicator.dart';

class ManualAnalysisScreen extends ConsumerStatefulWidget {
  const ManualAnalysisScreen({super.key});

  @override
  ConsumerState<ManualAnalysisScreen> createState() => _ManualAnalysisScreenState();
}

class _ManualAnalysisScreenState extends ConsumerState<ManualAnalysisScreen> {
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _senderController = TextEditingController();
  bool _isAnalyzing = false;
  PhishingDetection? _lastDetection;
  SmsMessage? _lastMessage;

  @override
  void dispose() {
    _messageController.dispose();
    _senderController.dispose();
    super.dispose();
  }

  Future<void> _analyzeMessage() async {
    if (_messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a message to analyze')),
      );
      return;
    }

    setState(() {
      _isAnalyzing = true;
      _lastDetection = null;
      _lastMessage = null;
    });

    try {
      // Create SMS message object
      final message = SmsMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        sender: _senderController.text.trim().isEmpty ? 'Unknown' : _senderController.text.trim(),
        body: _messageController.text.trim(),
        timestamp: DateTime.now(),
      );

      // Analyze the message using SMS service
      final detection = await SmsService.instance.analyzeMessage(
        message.body,
        sender: message.sender,
      );
      
      setState(() {
        _lastDetection = detection;
        _lastMessage = message;
        _isAnalyzing = false;
      });

      // Show result
      _showAnalysisResult(detection, message);
      
    } catch (e) {
      setState(() {
        _isAnalyzing = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Analysis failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showAnalysisResult(PhishingDetection detection, SmsMessage message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              detection.confidence > 0.5 ? Icons.warning : Icons.check_circle,
              color: detection.confidence > 0.5 ? Colors.red : Colors.green,
            ),
            const SizedBox(width: 8),
            Text(
              detection.confidence > 0.5 ? 'Phishing Detected!' : 'Message Safe',
              style: TextStyle(
                color: detection.confidence > 0.5 ? Colors.red : Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Message: ${message.body}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Sender: ${message.sender}'),
            const SizedBox(height: 8),
            Text('Confidence: ${(detection.confidence * 100).toStringAsFixed(1)}%'),
            const SizedBox(height: 8),
            Text('Reason: ${detection.reason}'),
            if (detection.indicators.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text('Indicators:', style: TextStyle(fontWeight: FontWeight.bold)),
              ...detection.indicators.map((indicator) => 
                Padding(
                  padding: const EdgeInsets.only(left: 16, top: 4),
                  child: Text('• $indicator'),
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          if (detection.confidence > 0.5)
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _savePhishingMessage(message, detection);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Save as Phishing'),
            ),
        ],
      ),
    );
  }

  Future<void> _savePhishingMessage(SmsMessage message, PhishingDetection detection) async {
    try {
      // Save to database
      await SmsService.instance.blockSender(message.sender, reason: 'Manual analysis - phishing detected');
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Message saved as phishing and sender blocked'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Clear form
      _messageController.clear();
      _senderController.clear();
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Manual Analysis'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => context.go('/settings'),
            icon: const Icon(Icons.settings),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.analytics,
                        color: Theme.of(context).colorScheme.primary,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Manual Phishing Analysis',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Enter any SMS message to check if it\'s a phishing attempt. Our AI will analyze the content, URLs, and patterns.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Input Form
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Message Details',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Sender Input
                    TextFormField(
                      controller: _senderController,
                      decoration: InputDecoration(
                        labelText: 'Sender (Optional)',
                        hintText: 'e.g., +1234567890 or Bank Name',
                        prefixIcon: const Icon(Icons.person),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Message Input
                    TextFormField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        labelText: 'SMS Message *',
                        hintText: 'Paste the suspicious SMS message here...',
                        prefixIcon: const Icon(Icons.message),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      maxLines: 4,
                      maxLength: 1000,
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Analyze Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isAnalyzing ? null : _analyzeMessage,
                        icon: _isAnalyzing 
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.analytics),
                        label: Text(_isAnalyzing ? 'Analyzing...' : 'Analyze Message'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Last Analysis Result
            if (_lastDetection != null && _lastMessage != null) ...[
              Card(
                color: _lastDetection!.confidence > 0.5 
                  ? Colors.red.withOpacity(0.1)
                  : Colors.green.withOpacity(0.1),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _lastDetection!.confidence > 0.5 ? Icons.warning : Icons.check_circle,
                            color: _lastDetection!.confidence > 0.5 ? Colors.red : Colors.green,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _lastDetection!.confidence > 0.5 ? 'Phishing Detected' : 'Message Safe',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _lastDetection!.confidence > 0.5 ? Colors.red : Colors.green,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('Confidence: ${(_lastDetection!.confidence * 100).toStringAsFixed(1)}%'),
                      Text('Reason: ${_lastDetection!.reason}'),
                    ],
                  ),
                ),
              ),
            ],
            
            const SizedBox(height: 24),
            
            // Tips Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.lightbulb,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Analysis Tips',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text('• Include the full message text for best results'),
                    const Text('• Add sender information if available'),
                    const Text('• Our AI analyzes URLs, keywords, and patterns'),
                    const Text('• High confidence results are automatically saved'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
