import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';

import '../services/sms_service.dart';
import '../../models/sms_message.dart';
import '../../models/phishing_detection.dart';

// SMS service provider
final smsServiceProvider = Provider<SmsService>((ref) {
  return SmsService.instance;
});

// SMS messages provider
final smsMessagesProvider = StreamProvider<List<SmsMessage>>((ref) {
  final smsService = ref.read(smsServiceProvider);
  return smsService.smsStream.asyncMap((message) async {
    // Get all messages from database
    return await smsService.getAllMessages();
  });
});

// Inbox messages provider
final inboxMessagesProvider = FutureProvider<List<SmsMessage>>((ref) async {
  final smsService = ref.read(smsServiceProvider);
  return await smsService.getInboxMessages();
});

// Archived messages provider
final archivedMessagesProvider = FutureProvider<List<SmsMessage>>((ref) async {
  final smsService = ref.read(smsServiceProvider);
  return await smsService.getArchivedMessages();
});

// Phishing detections provider
final phishingDetectionsProvider = StreamProvider<List<PhishingDetection>>((ref) {
  final smsService = ref.read(smsServiceProvider);
  return smsService.phishingStream.asyncMap((detection) async {
    // Get all detections from database
    return await smsService.getStatistics().then((_) => <PhishingDetection>[]);
  });
});

// SMS statistics provider
final smsStatisticsProvider = FutureProvider<Map<String, int>>((ref) async {
  final smsService = ref.read(smsServiceProvider);
  return await smsService.getStatistics();
});

// SMS actions provider
final smsActionsProvider = StateNotifierProvider<SmsActionsNotifier, SmsActionsState>((ref) {
  return SmsActionsNotifier(ref.read(smsServiceProvider));
});

// SMS actions state
class SmsActionsState {
  final bool isLoading;
  final String? errorMessage;
  final bool isSuccess;
  
  const SmsActionsState({
    this.isLoading = false,
    this.errorMessage,
    this.isSuccess = false,
  });
  
  SmsActionsState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool? isSuccess,
  }) {
    return SmsActionsState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }
}

class SmsActionsNotifier extends StateNotifier<SmsActionsState> {
  final SmsService _smsService;
  
  SmsActionsNotifier(this._smsService) : super(const SmsActionsState());
  
  Future<void> restoreMessage(String messageId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    
    try {
      await _smsService.restoreMessage(messageId);
      state = state.copyWith(isLoading: false, isSuccess: true);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to restore message: $e',
      );
    }
  }
  
  Future<void> whitelistSender(String sender) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    
    try {
      await _smsService.whitelistSender(sender);
      state = state.copyWith(isLoading: false, isSuccess: true);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to whitelist sender: $e',
      );
    }
  }
  
  Future<void> whitelistUrl(String url) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    
    try {
      await _smsService.whitelistUrl(url);
      state = state.copyWith(isLoading: false, isSuccess: true);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to whitelist URL: $e',
      );
    }
  }
  
  Future<void> reportFalsePositive(String messageId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    
    try {
      await _smsService.reportFalsePositive(messageId);
      state = state.copyWith(isLoading: false, isSuccess: true);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to report false positive: $e',
      );
    }
  }
  
  Future<void> reportFalseNegative(String messageId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    
    try {
      await _smsService.reportFalseNegative(messageId);
      state = state.copyWith(isLoading: false, isSuccess: true);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to report false negative: $e',
      );
    }
  }
  
  Future<void> deleteMessage(String messageId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    
    try {
      await _smsService.deleteMessage(messageId);
      state = state.copyWith(isLoading: false, isSuccess: true);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to delete message: $e',
      );
    }
  }
  
  
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
  
  void clearSuccess() {
    state = state.copyWith(isSuccess: false);
  }
}
