import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/services/ml_service.dart';
import '../../core/services/sms_service.dart';

class UrlAnalysisScreen extends StatefulWidget {
  final String url;
  final String? messageId;
  final String? sender;

  const UrlAnalysisScreen({
    super.key,
    required this.url,
    this.messageId,
    this.sender,
  });

  @override
  State<UrlAnalysisScreen> createState() => _UrlAnalysisScreenState();
}

class _UrlAnalysisScreenState extends State<UrlAnalysisScreen>
    with TickerProviderStateMixin {
  bool _isAnalyzing = true;
  Map<String, dynamic>? _analysis;
  late AnimationController _scanAnimationController;
  late Animation<double> _scanAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _analyzeUrl();
  }

  void _setupAnimations() {
    _scanAnimationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _scanAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scanAnimationController,
      curve: Curves.easeInOut,
    ));
    _scanAnimationController.repeat();
  }

  Future<void> _analyzeUrl() async {
    try {
      // Add a small delay for better UX
      await Future.delayed(const Duration(milliseconds: 1500));
      
      final analysis = await MLService.instance.analyzeUrl(widget.url);
      
      setState(() {
        _analysis = analysis;
        _isAnalyzing = false;
      });
      
      _scanAnimationController.stop();
      
      // If URL is highly suspicious, auto-block it
      if (analysis['confidence'] > 0.8) {
        await SmsService.instance.blockUrl(
          widget.url,
          reason: 'Auto-blocked: High threat URL detected during analysis',
          threatLevel: analysis['threatLevel'],
        );
      }
    } catch (e) {
      setState(() {
        _analysis = {
          'url': widget.url,
          'isSuspicious': false,
          'threatLevel': 'unknown',
          'indicators': ['Analysis failed: $e'],
          'confidence': 0.0,
        };
        _isAnalyzing = false;
      });
      _scanAnimationController.stop();
    }
  }

  @override
  void dispose() {
    _scanAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('URL Security Check'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isAnalyzing ? _buildAnalyzingView() : _buildResultsView(),
    );
  }

  Widget _buildAnalyzingView() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Scanning animation
          AnimatedBuilder(
            animation: _scanAnimation,
            builder: (context, child) {
              return Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Icon(
                        Icons.security,
                        size: 48,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    Positioned.fill(
                      child: CircularProgressIndicator(
                        value: _scanAnimation.value,
                        strokeWidth: 3,
                        backgroundColor: Colors.transparent,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          
          const SizedBox(height: 32),
          
          Text(
            'Analyzing URL Security',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 16),
          
          Text(
            'Please wait while we check this URL for potential threats...',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 24),
          
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.link,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.url,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsView() {
    if (_analysis == null) return const SizedBox();
    
    final isSuspicious = _analysis!['isSuspicious'] as bool;
    final confidence = _analysis!['confidence'] as double;
    final threatLevel = _analysis!['threatLevel'] as String;
    final indicators = _analysis!['indicators'] as List<dynamic>;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Threat level indicator
          _buildThreatLevelCard(isSuspicious, confidence, threatLevel),
          
          const SizedBox(height: 24),
          
          // URL display
          _buildUrlCard(),
          
          const SizedBox(height: 24),
          
          // Analysis details
          if (indicators.isNotEmpty) _buildAnalysisDetails(indicators),
          
          const SizedBox(height: 32),
          
          // Action buttons
          _buildActionButtons(isSuspicious, confidence),
        ],
      ),
    );
  }

  Widget _buildThreatLevelCard(bool isSuspicious, double confidence, String threatLevel) {
    Color cardColor;
    Color textColor;
    IconData icon;
    String title;
    String subtitle;
    
    if (confidence > 0.8) {
      cardColor = Colors.red.shade50;
      textColor = Colors.red.shade700;
      icon = Icons.dangerous;
      title = 'HIGH RISK';
      subtitle = 'This URL appears to be malicious';
    } else if (confidence > 0.5) {
      cardColor = Colors.orange.shade50;
      textColor = Colors.orange.shade700;
      icon = Icons.warning;
      title = 'MEDIUM RISK';
      subtitle = 'This URL has suspicious characteristics';
    } else if (confidence > 0.2) {
      cardColor = Colors.yellow.shade50;
      textColor = Colors.yellow.shade700;
      icon = Icons.info;
      title = 'LOW RISK';
      subtitle = 'This URL has minor concerns';
    } else {
      cardColor = Colors.green.shade50;
      textColor = Colors.green.shade700;
      icon = Icons.verified_user;
      title = 'SAFE';
      subtitle = 'This URL appears to be legitimate';
    }
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: textColor.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 48, color: textColor),
          const SizedBox(height: 12),
          Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: textColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: textColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            '${(confidence * 100).toStringAsFixed(1)}% Confidence',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: textColor.withOpacity(0.8),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUrlCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.link,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'URL',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SelectableText(
            widget.url,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisDetails(List<dynamic> indicators) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Analysis Details',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: indicators.map<Widget>((indicator) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.fiber_manual_record,
                      size: 8,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        indicator.toString(),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(bool isSuspicious, double confidence) {
    return Column(
      children: [
        if (isSuspicious && confidence > 0.5) ...[
          // High risk - show warning and block option
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _blockUrl(),
              icon: const Icon(Icons.block),
              label: const Text('Block This URL'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showRiskWarning(),
              icon: const Icon(Icons.warning),
              label: const Text('Continue Anyway (Not Recommended)'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ] else ...[
          // Low risk or safe - allow opening
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _openUrl(),
              icon: const Icon(Icons.open_in_browser),
              label: const Text('Open in Browser'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (confidence > 0.2) ...[
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _blockUrl(),
                icon: const Icon(Icons.block),
                label: const Text('Block This URL'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ],
        
        // Common actions
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _copyUrl(),
                icon: const Icon(Icons.copy),
                label: const Text('Copy URL'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
                label: const Text('Close'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _openUrl() async {
    try {
      final uri = Uri.parse(widget.url.startsWith('http') ? widget.url : 'https://${widget.url}');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        Navigator.pop(context);
      } else {
        _showSnackBar('Cannot open URL: ${widget.url}');
      }
    } catch (e) {
      _showSnackBar('Invalid URL: ${widget.url}');
    }
  }

  void _blockUrl() async {
    try {
      await SmsService.instance.blockUrl(
        widget.url,
        reason: 'Blocked by user during security analysis',
        threatLevel: _analysis!['threatLevel'],
      );
      _showSnackBar('URL has been blocked successfully');
      Navigator.pop(context);
    } catch (e) {
      _showSnackBar('Failed to block URL: $e');
    }
  }

  void _copyUrl() {
    Clipboard.setData(ClipboardData(text: widget.url));
    _showSnackBar('URL copied to clipboard');
  }

  void _showRiskWarning() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⚠️ Security Warning'),
        content: const Text(
          'This URL has been identified as potentially dangerous. '
          'Visiting it may expose you to phishing, malware, or other security threats.\n\n'
          'Are you sure you want to continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _openUrl();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Continue Anyway'),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
