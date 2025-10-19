import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/ml_service.dart';

class MLSettingsScreen extends ConsumerStatefulWidget {
  const MLSettingsScreen({super.key});

  @override
  ConsumerState<MLSettingsScreen> createState() => _MLSettingsScreenState();
}

class _MLSettingsScreenState extends ConsumerState<MLSettingsScreen> {
  final _huggingFaceController = TextEditingController();
  final _googleCloudController = TextEditingController();
  final _customApiController = TextEditingController();
  
  MLServiceMode _selectedMode = MLServiceMode.hybrid;
  ModelType _selectedModel = ModelType.lstm;
  bool _isLoading = false;
  Map<String, dynamic>? _serviceStats;
  Map<String, bool>? _capabilities;

  @override
  void initState() {
    super.initState();
    _loadCurrentSettings();
  }

  Future<void> _loadCurrentSettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final mlService = MLService.instance;
      _selectedMode = mlService.serviceMode;
      _selectedModel = mlService.currentModelType;
      _serviceStats = mlService.getModelStats();
      _capabilities = mlService.getServiceCapabilities();
    } catch (e) {
      _showErrorSnackBar('Failed to load settings: $e');
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _saveSettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final mlService = MLService.instance;
      
      // Switch service mode
      await mlService.switchServiceMode(_selectedMode);
      
      // Switch model type
      await mlService.switchModel(_selectedModel);
      
      // Re-initialize with API keys if provided
      if (_huggingFaceController.text.isNotEmpty ||
          _googleCloudController.text.isNotEmpty ||
          _customApiController.text.isNotEmpty) {
        await mlService.initialize(
          serviceMode: _selectedMode,
          modelType: _selectedModel,
          huggingFaceApiKey: _huggingFaceController.text.isNotEmpty 
              ? _huggingFaceController.text 
              : null,
          googleCloudApiKey: _googleCloudController.text.isNotEmpty 
              ? _googleCloudController.text 
              : null,
          customApiKey: _customApiController.text.isNotEmpty 
              ? _customApiController.text 
              : null,
        );
      }
      
      await _loadCurrentSettings();
      _showSuccessSnackBar('Settings saved successfully!');
    } catch (e) {
      _showErrorSnackBar('Failed to save settings: $e');
    }

    setState(() {
      _isLoading = false;
    });
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ML Settings'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildServiceModeSection(),
                  const SizedBox(height: 24),
                  _buildModelTypeSection(),
                  const SizedBox(height: 24),
                  _buildApiKeysSection(),
                  const SizedBox(height: 24),
                  _buildStatusSection(),
                  const SizedBox(height: 24),
                  _buildCapabilitiesSection(),
                  const SizedBox(height: 32),
                  _buildSaveButton(),
                ],
              ),
            ),
    );
  }

  Widget _buildServiceModeSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Service Mode',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            RadioListTile<MLServiceMode>(
              title: const Text('Online Only'),
              subtitle: const Text('Uses cloud APIs for analysis'),
              value: MLServiceMode.online,
              groupValue: _selectedMode,
              onChanged: (value) {
                setState(() {
                  _selectedMode = value!;
                });
              },
            ),
            RadioListTile<MLServiceMode>(
              title: const Text('Offline Only'),
              subtitle: const Text('Uses local models for analysis'),
              value: MLServiceMode.offline,
              groupValue: _selectedMode,
              onChanged: (value) {
                setState(() {
                  _selectedMode = value!;
                });
              },
            ),
            RadioListTile<MLServiceMode>(
              title: const Text('Hybrid (Recommended)'),
              subtitle: const Text('Online when available, offline fallback'),
              value: MLServiceMode.hybrid,
              groupValue: _selectedMode,
              onChanged: (value) {
                setState(() {
                  _selectedMode = value!;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModelTypeSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Model Type (Offline)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<ModelType>(
              initialValue: _selectedModel,
              decoration: const InputDecoration(
                labelText: 'Select Model',
                border: OutlineInputBorder(),
              ),
              items: ModelType.values.map((type) {
                String description;
                switch (type) {
                  case ModelType.lstm:
                    description = 'LSTM - Fast, lightweight (10MB)';
                    break;
                  case ModelType.bert:
                    description = 'BERT - High accuracy (95MB)';
                    break;
                  case ModelType.distilbert:
                    description = 'DistilBERT - Balanced (30MB)';
                    break;
                  case ModelType.ensemble:
                    description = 'Ensemble - Maximum accuracy';
                    break;
                }
                return DropdownMenuItem(
                  value: type,
                  child: Text(description),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedModel = value!;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApiKeysSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'API Keys (Online Mode)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _huggingFaceController,
              decoration: const InputDecoration(
                labelText: 'Hugging Face API Key',
                hintText: 'hf_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _googleCloudController,
              decoration: const InputDecoration(
                labelText: 'Google Cloud API Key',
                hintText: 'AIzaSyxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _customApiController,
              decoration: const InputDecoration(
                labelText: 'Custom API Key',
                hintText: 'your-custom-api-key',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 8),
            const Text(
              'API keys are stored securely and only used for ML analysis.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusSection() {
    if (_serviceStats == null) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Service Status',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildStatusItem('Service Mode', _serviceStats!['serviceMode']),
            _buildStatusItem('Current Model', _serviceStats!['currentModel']),
            _buildStatusItem('Connectivity', _serviceStats!['connectivity']),
            _buildStatusItem('Initialized', _serviceStats!['isInitialized'].toString()),
            _buildStatusItem('Vocabulary Loaded', _serviceStats!['vocabLoaded'].toString()),
          ],
        ),
      ),
    );
  }

  Widget _buildCapabilitiesSection() {
    if (_capabilities == null) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Capabilities',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildCapabilityItem('Can Work Offline', _capabilities!['canWorkOffline']!),
            _buildCapabilityItem('Can Work Online', _capabilities!['canWorkOnline']!),
            _buildCapabilityItem('Internet Connection', _capabilities!['hasInternetConnection']!),
            _buildCapabilityItem('Offline Models', _capabilities!['hasOfflineModels']!),
            _buildCapabilityItem('Online API Keys', _capabilities!['hasOnlineApiKeys']!),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildCapabilityItem(String label, bool isAvailable) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Icon(
            isAvailable ? Icons.check_circle : Icons.cancel,
            color: isAvailable ? Colors.green : Colors.red,
            size: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _saveSettings,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: _isLoading
            ? const CircularProgressIndicator()
            : const Text('Save Settings'),
      ),
    );
  }

  @override
  void dispose() {
    _huggingFaceController.dispose();
    _googleCloudController.dispose();
    _customApiController.dispose();
    super.dispose();
  }
}
