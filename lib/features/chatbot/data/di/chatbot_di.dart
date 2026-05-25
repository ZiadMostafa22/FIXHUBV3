import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:car_maintenance_system_new/features/chatbot/data/datasources/gemini_ai_datasource.dart';
import 'package:car_maintenance_system_new/features/chatbot/data/datasources/chatbot_remote_datasource.dart';
import 'package:car_maintenance_system_new/features/chatbot/data/repositories/chatbot_repository_impl.dart';
import 'package:car_maintenance_system_new/features/chatbot/domain/repositories/chatbot_repository.dart';

// TODO: Replace with your actual Gemini API key
// You can store this in environment variables or secure storage
const String _geminiApiKey = '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';

// Debug: Verify API key is set
void _verifyApiKey() {
  if (_geminiApiKey.isEmpty || _geminiApiKey == 'YOUR_GEMINI_API_KEY_HERE') {
    throw Exception('Gemini API Key is not configured in chatbot_di.dart');
  }
  print('Gemini API Key loaded: ${_geminiApiKey.substring(0, 10)}...${_geminiApiKey.substring(_geminiApiKey.length - 5)}');
}

/// Gemini AI Datasource Provider
final geminiAIDatasourceProvider = Provider<GeminiAIDatasource>((ref) {
  // Verify API key is set
  _verifyApiKey();
  return GeminiAIDatasource(apiKey: _geminiApiKey);
});

/// Chatbot Remote Datasource Provider
final chatbotRemoteDatasourceProvider = Provider<ChatbotRemoteDatasource>((ref) {
  return ChatbotRemoteDatasource();
});

/// Chatbot Repository Provider
final chatbotRepositoryProvider = Provider<ChatbotRepository>((ref) {
  final geminiDatasource = ref.watch(geminiAIDatasourceProvider);
  final remoteDatasource = ref.watch(chatbotRemoteDatasourceProvider);
  return ChatbotRepositoryImpl(
    geminiDatasource: geminiDatasource,
    remoteDatasource: remoteDatasource,
  );
});

