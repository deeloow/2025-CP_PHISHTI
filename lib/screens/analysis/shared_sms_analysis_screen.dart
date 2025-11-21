import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/services/sms_share_service.dart';
import '../../models/phishing_detection.dart';

class SharedSmsAnalysisScreen extends ConsumerStatefulWidget {
  final String sharedText;
  final String? sender;
  
  const SharedSmsAnalysisScreen({
    super.key,
    required this.sharedText,
    this.sender,
  });

  @override
  ConsumerState<SharedSmsAnalysisScreen> createState() => _SharedSmsAnalysisScreenState();
}

class _SharedSmsAnalysisScreenState extends ConsumerState<SharedSmsAnalysisScreen> {
  PhishingDetection? _detection;
  bool _isAnalyzing = false;
  String? _error;
  
  @override
  void initState() {
    super.initState();
    _analyzeSharedText();
  }
  
  Future<void> _analyzeSharedText() async {
    setState(() {
      _isAnalyzing = true;
      _error = null;
    });
    
    try {
      final detection = await SmsShareService.instance.analyzeSharedText(
        widget.sharedText,
        sender: widget.sender,
      );
      
      setState(() {
        _detection = detection;
        _isAnalyzing = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isAnalyzing = false;
      });
    }
  }
  
  Future<void> _saveAnalysis() async {
    if (_detection == null) return;
    
    try {
      final sharedData = SharedSmsData(
        text: widget.sharedText,
        timestamp: DateTime.now(),
        sender: widget.sender ?? 'Shared from SMS app',
      );
      
      await SmsShareService.instance.storeSharedAnalysis(sharedData, _detection!);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_detection!.confidence > 0.5 
              ? 'Phishing detected and auto-archived!' 
              : 'Message appears to be legitimate'),
            backgroundColor: _detection!.confidence > 0.5 
              ? Colors.red 
              : Colors.green,
          ),
        );
        
        // Navigate back
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving analysis: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SMS Analysis'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        elevation: 0,
        actions: [
          if (_detection != null)
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveAnalysis,
              tooltip: 'Save Analysis',
            ),
        ],
      ),
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Shared text display
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Shared SMS Content',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.sharedText,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      if (widget.sender != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          'From: ${widget.sender}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Analysis results
              if (_isAnalyzing)
                const Center(
                  child: Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Analyzing message...'),
                    ],
                  ),
                )
              else if (_error != null)
                Card(
                  color: Colors.red.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.error, color: Colors.red.shade700),
                            const SizedBox(width: 8),
                            Text(
                              'Analysis Error',
                              style: TextStyle(
                                color: Colors.red.shade700,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _error!,
                          style: TextStyle(color: Colors.red.shade700),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _analyzeSharedText,
                          child: const Text('Retry Analysis'),
                        ),
                      ],
                    ),
                  ),
                )
              else if (_detection != null)
                _buildAnalysisResults()
              else
                const Center(
                  child: Text('No analysis results available'),
                ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildAnalysisResults() {
    final isPhishing = _detection!.confidence > 0.5;
    final confidence = _detection!.confidence;
    
    return Card(
      color: isPhishing ? Colors.red.shade50 : Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isPhishing ? Icons.warning : Icons.check_circle,
                  color: isPhishing ? Colors.red.shade700 : Colors.green.shade700,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isPhishing ? 'Phishing Detected!' : 'Message Appears Safe',
                        style: TextStyle(
                          color: isPhishing ? Colors.red.shade700 : Colors.green.shade700,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        'Confidence: ${(confidence * 100).toStringAsFixed(1)}%',
                        style: TextStyle(
                          color: isPhishing ? Colors.red.shade600 : Colors.green.shade600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            Text(
              'Analysis Details:',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _detection!.reason,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            
            if (_detection!.indicators.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Indicators:',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ...(_detection!.indicators.map((indicator) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.circle,
                      size: 8,
                      color: isPhishing ? Colors.red.shade600 : Colors.green.shade600,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        indicator,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ))),
            ],
            
            const SizedBox(height: 16),
            
            if (isPhishing)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade300),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info, color: Colors.red.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This message will be automatically archived to protect you from potential scams.',
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
