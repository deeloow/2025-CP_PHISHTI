import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/services/enhanced_online_ml_service.dart';

class OnlineMLSettingsScreen extends StatefulWidget {
  const OnlineMLSettingsScreen({super.key});

  @override
  State<OnlineMLSettingsScreen> createState() => _OnlineMLSettingsScreenState();
}

class _OnlineMLSettingsScreenState extends State<OnlineMLSettingsScreen> {
  final EnhancedOnlineMLService _mlService = EnhancedOnlineMLService.instance;
  
  List<MLProvider> _enabledProviders = [];
  MLProvider _primaryProvider = MLProvider.huggingFace;
  Map<MLProvider, String> _apiKeys = {};
  Map<MLProvider, bool> _isTesting = {};
  Map<MLProvider, bool> _testResults = {};
  
  @override
  void initState() {
    super.initState();
    _loadSettings();
  }
  
  Future<void> _loadSettings() async {
    await _mlService.initialize();
    
    setState(() {
      _enabledProviders = _mlService.getEnabledProviders();
      _primaryProvider = _mlService.getPrimaryProvider();
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Online ML Services'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
                          Icons.cloud,
                          color: Theme.of(context).colorScheme.primary,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'AI-Powered Analysis',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Configure online AI services for advanced phishing detection. These services provide more accurate analysis than rule-based detection.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Service Status
            _buildServiceStatus(),
            
            const SizedBox(height: 16),
            
            // Provider Configuration
            _buildProviderConfiguration(),
            
            const SizedBox(height: 16),
            
            // Quick Setup Guide
            _buildQuickSetupGuide(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildServiceStatus() {
    final status = _mlService.getServiceStatus();
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Service Status',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            
            Row(
              children: [
                Icon(
                  status['isInitialized'] ? Icons.check_circle : Icons.error,
                  color: status['isInitialized'] ? Colors.green : Colors.red,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  status['isInitialized'] ? 'Service Active' : 'Service Inactive',
                  style: TextStyle(
                    color: status['isInitialized'] ? Colors.green : Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            Text(
              'Enabled Providers: ${_enabledProviders.length}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            
            if (_enabledProviders.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Primary: ${_primaryProvider.name}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildProviderConfiguration() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'AI Providers',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            
            ...MLProvider.values.map((provider) => _buildProviderCard(provider)),
          ],
        ),
      ),
    );
  }
  
  Widget _buildProviderCard(MLProvider provider) {
    final isEnabled = _enabledProviders.contains(provider);
    final hasApiKey = _apiKeys.containsKey(provider) && _apiKeys[provider]!.isNotEmpty;
    final isTesting = _isTesting[provider] ?? false;
    final testResult = _testResults[provider];
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        border: Border.all(
          color: isEnabled 
              ? Theme.of(context).colorScheme.primary.withOpacity(0.3)
              : Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            provider.name,
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (isEnabled)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'ENABLED',
                                style: TextStyle(
                                  color: Colors.green,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        provider.description,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Test button
                if (hasApiKey) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: isTesting ? null : () => _testProvider(provider),
                    icon: isTesting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(
                            testResult == true ? Icons.check_circle : Icons.play_arrow,
                            color: testResult == true ? Colors.green : Theme.of(context).colorScheme.primary,
                            size: 20,
                          ),
                    tooltip: 'Test Connection',
                  ),
                ],
              ],
            ),
            
            const SizedBox(height: 12),
            
            // API Key input
            TextField(
              decoration: InputDecoration(
                labelText: 'API Key',
                hintText: 'Enter your ${provider.name} API key',
                border: const OutlineInputBorder(),
                suffixIcon: hasApiKey
                    ? IconButton(
                        onPressed: () => _removeApiKey(provider),
                        icon: const Icon(Icons.delete),
                        tooltip: 'Remove API Key',
                      )
                    : null,
              ),
              obscureText: true,
              onChanged: (value) => _apiKeys[provider] = value,
              onSubmitted: (value) => _saveApiKey(provider, value),
            ),
            
            const SizedBox(height: 8),
            
            // Action buttons
            Row(
              children: [
                if (hasApiKey) ...[
                  ElevatedButton.icon(
                    onPressed: () => _saveApiKey(provider, _apiKeys[provider]!),
                    icon: const Icon(Icons.save, size: 16),
                    label: const Text('Save'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                
                if (isEnabled && _primaryProvider != provider)
                  ElevatedButton.icon(
                    onPressed: () => _setPrimaryProvider(provider),
                    icon: const Icon(Icons.star, size: 16),
                    label: const Text('Set Primary'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),
              ],
            ),
            
            // Test result
            if (testResult != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    testResult ? Icons.check_circle : Icons.error,
                    color: testResult ? Colors.green : Colors.red,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    testResult ? 'Connection successful' : 'Connection failed',
                    style: TextStyle(
                      color: testResult ? Colors.green : Colors.red,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildQuickSetupGuide() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Setup Guide',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            
            _buildSetupStep(
              '1. Hugging Face (Recommended)',
              'Free tier available. Visit huggingface.co, create account, get API token from Settings > Access Tokens.',
              Icons.free_breakfast,
              Colors.green,
            ),
            
            _buildSetupStep(
              '2. OpenAI GPT',
              'Advanced AI analysis. Visit platform.openai.com, create account, get API key from API Keys section.',
              Icons.psychology,
              Colors.blue,
            ),
            
            _buildSetupStep(
              '3. Google Cloud',
              'Enterprise-grade analysis. Requires billing account. Enable Natural Language API and create credentials.',
              Icons.cloud,
              Colors.orange,
            ),
            
            const SizedBox(height: 12),
            
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, color: Colors.blue, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Tip: Start with Hugging Face for free AI analysis, then add other providers for better accuracy.',
                      style: TextStyle(
                        color: Colors.blue.shade700,
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
  
  Widget _buildSetupStep(String title, String description, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Future<void> _saveApiKey(MLProvider provider, String apiKey) async {
    if (apiKey.isEmpty) return;
    
    try {
      await _mlService.setApiKey(provider, apiKey);
      
      setState(() {
        _enabledProviders = _mlService.getEnabledProviders();
      });
      
      _showSnackBar('API key saved for ${provider.name}');
    } catch (e) {
      _showSnackBar('Error saving API key: $e');
    }
  }
  
  Future<void> _removeApiKey(MLProvider provider) async {
    try {
      await _mlService.removeApiKey(provider);
      
      setState(() {
        _enabledProviders = _mlService.getEnabledProviders();
        _apiKeys.remove(provider);
        _testResults.remove(provider);
      });
      
      _showSnackBar('API key removed for ${provider.name}');
    } catch (e) {
      _showSnackBar('Error removing API key: $e');
    }
  }
  
  Future<void> _setPrimaryProvider(MLProvider provider) async {
    try {
      await _mlService.setPrimaryProvider(provider);
      
      setState(() {
        _primaryProvider = provider;
      });
      
      _showSnackBar('${provider.name} set as primary provider');
    } catch (e) {
      _showSnackBar('Error setting primary provider: $e');
    }
  }
  
  Future<void> _testProvider(MLProvider provider) async {
    setState(() {
      _isTesting[provider] = true;
    });
    
    try {
      final result = await _mlService.testApiConnection(provider);
      
      setState(() {
        _isTesting[provider] = false;
        _testResults[provider] = result;
      });
      
      if (result) {
        _showSnackBar('${provider.name} connection successful!');
      } else {
        _showSnackBar('${provider.name} connection failed. Check your API key.');
      }
    } catch (e) {
      setState(() {
        _isTesting[provider] = false;
        _testResults[provider] = false;
      });
      
      _showSnackBar('Error testing ${provider.name}: $e');
    }
  }
  
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
