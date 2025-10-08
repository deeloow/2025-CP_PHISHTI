import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/ml_service.dart';
import '../../models/phishing_detection.dart';
import '../../models/sms_message.dart';

// ML service provider
final mlServiceProvider = Provider<MLService>((ref) {
  return MLService.instance;
});

// ML initialization provider
final mlInitializationProvider = FutureProvider<bool>((ref) async {
  final mlService = ref.read(mlServiceProvider);
  await mlService.initialize();
  return true;
});

// Threat meter provider
final threatMeterProvider = StateNotifierProvider<ThreatMeterNotifier, ThreatMeterState>((ref) {
  return ThreatMeterNotifier();
});

// Threat meter state
class ThreatMeterState {
  final int totalDetections;
  final int weeklyDetections;
  final int monthlyDetections;
  final ThreatLevel currentLevel;
  final bool isLoading;
  final String? errorMessage;
  
  const ThreatMeterState({
    this.totalDetections = 0,
    this.weeklyDetections = 0,
    this.monthlyDetections = 0,
    this.currentLevel = ThreatLevel.low,
    this.isLoading = false,
    this.errorMessage,
  });
  
  ThreatMeterState copyWith({
    int? totalDetections,
    int? weeklyDetections,
    int? monthlyDetections,
    ThreatLevel? currentLevel,
    bool? isLoading,
    String? errorMessage,
  }) {
    return ThreatMeterState(
      totalDetections: totalDetections ?? this.totalDetections,
      weeklyDetections: weeklyDetections ?? this.weeklyDetections,
      monthlyDetections: monthlyDetections ?? this.monthlyDetections,
      currentLevel: currentLevel ?? this.currentLevel,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class ThreatMeterNotifier extends StateNotifier<ThreatMeterState> {
  ThreatMeterNotifier() : super(const ThreatMeterState()) {
    _loadThreatMeter();
  }
  
  Future<void> _loadThreatMeter() async {
    state = state.copyWith(isLoading: true);
    
    try {
      // This would typically load from database or API
      // For now, we'll use mock data
      await Future.delayed(const Duration(seconds: 1));
      
      state = state.copyWith(
        isLoading: false,
        totalDetections: 15,
        weeklyDetections: 3,
        monthlyDetections: 8,
        currentLevel: ThreatLevel.medium,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load threat meter: $e',
      );
    }
  }
  
  void updateThreatLevel() {
    final weeklyDetections = state.weeklyDetections;
    ThreatLevel newLevel;
    
    if (weeklyDetections >= 10) {
      newLevel = ThreatLevel.critical;
    } else if (weeklyDetections >= 5) {
      newLevel = ThreatLevel.high;
    } else if (weeklyDetections >= 2) {
      newLevel = ThreatLevel.medium;
    } else {
      newLevel = ThreatLevel.low;
    }
    
    state = state.copyWith(currentLevel: newLevel);
  }
  
  void incrementWeeklyDetections() {
    final newWeekly = state.weeklyDetections + 1;
    final newTotal = state.totalDetections + 1;
    
    state = state.copyWith(
      weeklyDetections: newWeekly,
      totalDetections: newTotal,
    );
    
    updateThreatLevel();
  }
  
  void resetWeeklyDetections() {
    state = state.copyWith(
      weeklyDetections: 0,
      currentLevel: ThreatLevel.low,
    );
  }
}

// ML analysis provider
final mlAnalysisProvider = StateNotifierProvider<MLAnalysisNotifier, MLAnalysisState>((ref) {
  return MLAnalysisNotifier(ref.read(mlServiceProvider));
});

// ML analysis state
class MLAnalysisState {
  final bool isAnalyzing;
  final String? errorMessage;
  final PhishingDetection? lastDetection;
  final List<PhishingDetection> recentDetections;
  
  const MLAnalysisState({
    this.isAnalyzing = false,
    this.errorMessage,
    this.lastDetection,
    this.recentDetections = const [],
  });
  
  MLAnalysisState copyWith({
    bool? isAnalyzing,
    String? errorMessage,
    PhishingDetection? lastDetection,
    List<PhishingDetection>? recentDetections,
  }) {
    return MLAnalysisState(
      isAnalyzing: isAnalyzing ?? this.isAnalyzing,
      errorMessage: errorMessage,
      lastDetection: lastDetection ?? this.lastDetection,
      recentDetections: recentDetections ?? this.recentDetections,
    );
  }
}

class MLAnalysisNotifier extends StateNotifier<MLAnalysisState> {
  final MLService _mlService;
  
  MLAnalysisNotifier(this._mlService) : super(const MLAnalysisState());
  
  Future<void> analyzeMessage(String messageId, String sender, String body) async {
    state = state.copyWith(isAnalyzing: true, errorMessage: null);
    
    try {
      // Create a mock SMS message for analysis
      final smsMessage = SmsMessage(
        id: messageId,
        sender: sender,
        body: body,
        timestamp: DateTime.now(),
      );
      
      final detection = await _mlService.analyzeSms(smsMessage);
      
      state = state.copyWith(
        isAnalyzing: false,
        lastDetection: detection,
        recentDetections: [detection, ...state.recentDetections.take(9)],
      );
    } catch (e) {
      state = state.copyWith(
        isAnalyzing: false,
        errorMessage: 'Analysis failed: $e',
      );
    }
  }
  
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
  
  void clearRecentDetections() {
    state = state.copyWith(recentDetections: []);
  }
}

// Model status provider
final modelStatusProvider = StateNotifierProvider<ModelStatusNotifier, ModelStatusState>((ref) {
  return ModelStatusNotifier(ref.read(mlServiceProvider));
});

// Model status state
class ModelStatusState {
  final bool isLoaded;
  final bool isLoading;
  final String? errorMessage;
  final DateTime? lastUpdated;
  
  const ModelStatusState({
    this.isLoaded = false,
    this.isLoading = false,
    this.errorMessage,
    this.lastUpdated,
  });
  
  ModelStatusState copyWith({
    bool? isLoaded,
    bool? isLoading,
    String? errorMessage,
    DateTime? lastUpdated,
  }) {
    return ModelStatusState(
      isLoaded: isLoaded ?? this.isLoaded,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

class ModelStatusNotifier extends StateNotifier<ModelStatusState> {
  final MLService _mlService;
  
  ModelStatusNotifier(this._mlService) : super(const ModelStatusState()) {
    _checkModelStatus();
  }
  
  Future<void> _checkModelStatus() async {
    state = state.copyWith(isLoading: true);
    
    try {
      await _mlService.initialize();
      state = state.copyWith(
        isLoading: false,
        isLoaded: true,
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load models: $e',
      );
    }
  }
  
  Future<void> reloadModels() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    
    try {
      await _mlService.dispose();
      await _mlService.initialize();
      state = state.copyWith(
        isLoading: false,
        isLoaded: true,
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to reload models: $e',
      );
    }
  }
}
