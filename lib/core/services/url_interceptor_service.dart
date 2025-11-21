import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../screens/url_analysis/url_analysis_screen.dart';
import 'sms_service.dart';

class UrlInterceptorService {
  static final UrlInterceptorService _instance = UrlInterceptorService._internal();
  static UrlInterceptorService get instance => _instance;
  
  UrlInterceptorService._internal();

  /// Intercepts URL clicks and routes them through security analysis
  /// Returns true if URL was handled by the interceptor, false otherwise
  Future<bool> interceptUrl(
    BuildContext context,
    String url, {
    String? messageId,
    String? sender,
    bool forceAnalysis = false,
  }) async {
    try {
      // Check if URL is already blocked
      final isBlocked = await SmsService.instance.isUrlBlocked(url);
      
      if (isBlocked && !forceAnalysis) {
        _showBlockedUrlDialog(context, url);
        return true;
      }
      
      // Check if URL should be analyzed (from SMS messages or forced)
      if (_shouldAnalyzeUrl(url, messageId, forceAnalysis)) {
        // Navigate to analysis screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => UrlAnalysisScreen(
              url: url,
              messageId: messageId,
              sender: sender,
            ),
          ),
        );
        return true;
      }
      
      // For trusted URLs or non-SMS contexts, open directly
      return await _openUrlDirectly(url);
    } catch (e) {
      _showErrorDialog(context, 'Failed to process URL: $e');
      return true;
    }
  }

  /// Determines if a URL should go through analysis
  bool _shouldAnalyzeUrl(String url, String? messageId, bool forceAnalysis) {
    // Always analyze if forced
    if (forceAnalysis) return true;
    
    // Always analyze URLs from SMS messages
    if (messageId != null) return true;
    
    // Analyze suspicious URL patterns
    if (_hasHighRiskPatterns(url)) return true;
    
    // For other contexts, don't analyze
    return false;
  }

  /// Checks for high-risk URL patterns that should always be analyzed
  bool _hasHighRiskPatterns(String url) {
    final lowerUrl = url.toLowerCase();
    
    // URL shorteners
    final shorteners = [
      'bit.ly', 'tinyurl.com', 'goo.gl', 't.co', 'short.link',
      'ow.ly', 'buff.ly', 'adf.ly', 'tiny.cc', 'is.gd'
    ];
    
    if (shorteners.any((shortener) => lowerUrl.contains(shortener))) {
      return true;
    }
    
    // Suspicious TLDs
    final suspiciousTlds = ['.tk', '.ml', '.ga', '.cf', '.top', '.click'];
    if (suspiciousTlds.any((tld) => lowerUrl.endsWith(tld))) {
      return true;
    }
    
    // IP addresses
    final ipPattern = RegExp(r'[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}');
    if (ipPattern.hasMatch(url)) {
      return true;
    }
    
    // Phishing keywords in URL
    final phishingKeywords = [
      'paypal', 'amazon', 'apple', 'microsoft', 'google', 'facebook',
      'bank', 'secure', 'verify', 'update', 'confirm', 'login',
      'account', 'suspended', 'limited', 'urgent'
    ];
    
    if (phishingKeywords.any((keyword) => lowerUrl.contains(keyword))) {
      return true;
    }
    
    return false;
  }

  /// Opens URL directly without analysis
  Future<bool> _openUrlDirectly(String url) async {
    try {
      final uri = Uri.parse(url.startsWith('http') ? url : 'https://$url');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Shows dialog for blocked URLs
  void _showBlockedUrlDialog(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.block, color: Colors.red),
            SizedBox(width: 8),
            Text('URL Blocked'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This URL has been blocked for your security.',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Text(
                url,
                style: TextStyle(
                  color: Colors.red.shade700,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'This URL was previously identified as potentially dangerous and has been blocked to protect you from security threats.',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Force analysis even for blocked URLs
              interceptUrl(context, url, forceAnalysis: true);
            },
            child: const Text('Analyze Anyway'),
          ),
        ],
      ),
    );
  }

  /// Shows error dialog
  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  /// Quick analysis method for immediate threat assessment
  Future<Map<String, dynamic>> quickAnalyze(String url) async {
    final analysis = {
      'url': url,
      'isSuspicious': false,
      'threatLevel': 'safe',
      'confidence': 0.0,
      'quickCheck': true,
    };
    
    double suspicionScore = 0.0;
    
    // Quick pattern-based checks
    if (_hasHighRiskPatterns(url)) {
      suspicionScore += 0.6;
    }
    
    // Check for excessive subdomains
    final domainPart = url.replaceAll(RegExp(r'https?://'), '').split('/')[0];
    final subdomains = domainPart.split('.');
    if (subdomains.length > 4) {
      suspicionScore += 0.3;
    }
    
    // Check for suspicious characters
    if (url.contains('%') || url.contains('&amp;') || url.contains('<')) {
      suspicionScore += 0.2;
    }
    
    analysis['confidence'] = suspicionScore;
    analysis['isSuspicious'] = suspicionScore > 0.4;
    
    if (suspicionScore > 0.8) {
      analysis['threatLevel'] = 'high';
    } else if (suspicionScore > 0.5) {
      analysis['threatLevel'] = 'medium';
    } else if (suspicionScore > 0.2) {
      analysis['threatLevel'] = 'low';
    }
    
    return analysis;
  }

  /// Batch process URLs for analysis
  Future<List<Map<String, dynamic>>> batchAnalyze(List<String> urls) async {
    final results = <Map<String, dynamic>>[];
    
    for (final url in urls) {
      final analysis = await quickAnalyze(url);
      results.add(analysis);
    }
    
    return results;
  }

  /// Check if URL should trigger immediate warning
  Future<bool> shouldShowImmediateWarning(String url) async {
    final analysis = await quickAnalyze(url);
    return analysis['confidence'] > 0.7 && analysis['isSuspicious'];
  }

  /// Get URL safety status without full analysis
  Future<String> getUrlSafetyStatus(String url) async {
    // Check if blocked
    final isBlocked = await SmsService.instance.isUrlBlocked(url);
    if (isBlocked) return 'blocked';
    
    // Quick analysis
    final analysis = await quickAnalyze(url);
    if (analysis['confidence'] > 0.7) return 'dangerous';
    if (analysis['confidence'] > 0.4) return 'suspicious';
    if (analysis['confidence'] > 0.2) return 'caution';
    
    return 'safe';
  }
}
