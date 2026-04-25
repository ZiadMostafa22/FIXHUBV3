import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:car_maintenance_system_new/features/chatbot/domain/entities/chat_message_entity.dart';

class GeminiAIDatasource {
  final String apiKey;
  static const String _openRouterUrl = 'https://openrouter.ai/api/v1/chat/completions';
  static const String _model = 'google/gemini-2.5-flash';

  GeminiAIDatasource({required this.apiKey}) {
    // Trim API key to remove any whitespace
    final trimmedApiKey = apiKey.trim();
    
    if (trimmedApiKey.isEmpty || trimmedApiKey == 'YOUR_GEMINI_API_KEY_HERE') {
      throw Exception('OpenRouter API Key is not configured. Please set your API key in chatbot_di.dart');
    }
    
    // Debug: Print first and last few characters of API key (for debugging, remove in production)
    print('🔑 GeminiAIDatasource initialized with OpenRouter API key: ${trimmedApiKey.substring(0, 10)}...${trimmedApiKey.substring(trimmedApiKey.length - 5)}');
  }

  /// Get AI response for a message using OpenRouter API
  Future<String> getResponse(String message, List<ChatMessageEntity> conversationHistory) async {
    try {
      print('📤 Sending request to OpenRouter API with model: $_model');
      
      // Build messages array in OpenAI format
      final List<Map<String, dynamic>> messages = [];
      
      // Add system message (only once, contains all context)
      messages.add({
        'role': 'system',
        'content': _getSystemPrompt(),
      });
      
      // Only add last 2-3 messages from conversation history to keep context short
      // This reduces token usage and improves response speed
      final recentHistory = conversationHistory.length > 4 
          ? conversationHistory.sublist(conversationHistory.length - 4)
          : conversationHistory;
      
      // Add recent conversation history (last 2-3 exchanges)
      for (var msg in recentHistory) {
        messages.add({
          'role': msg.type == MessageType.user ? 'user' : 'assistant',
          'content': msg.text,
        });
      }
      
      // Add current user message
      messages.add({
        'role': 'user',
        'content': message,
      });

      // Prepare request body
      // Set max_tokens to 12000 to stay well within free tier limit
      final requestBody = {
        'model': _model,
        'messages': messages,
        'max_tokens': 12000, // Limit tokens to stay within free tier (safe margin)
      };

      print('📝 Request body: ${jsonEncode(requestBody)}');

      // Make HTTP POST request to OpenRouter API
      final response = await http.post(
        Uri.parse(_openRouterUrl),
        headers: {
          'Authorization': 'Bearer ${apiKey.trim()}',
          'Content-Type': 'application/json',
          'HTTP-Referer': 'https://car-maintenance-system.com', // Optional
          'X-Title': 'Car Maintenance System', // Optional
        },
        body: jsonEncode(requestBody),
      );

      print('📥 Received response from OpenRouter API');
      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode != 200) {
        final errorBody = jsonDecode(response.body);
        final errorMessage = errorBody['error']?['message'] ?? response.body;
        throw Exception('OpenRouter API Error: $errorMessage');
      }

      final responseData = jsonDecode(response.body);
      
      // Extract the response text from OpenAI-compatible format
      final choices = responseData['choices'] as List?;
      if (choices == null || choices.isEmpty) {
        throw Exception('Empty response from AI model');
      }

      final messageContent = choices[0]['message']?['content'];
      if (messageContent == null || messageContent.toString().isEmpty) {
        throw Exception('Empty response content from AI model');
      }

      return messageContent.toString();
    } catch (e) {
      // Log the full error for debugging
      print('OpenRouter API Error Details: $e');
      print('Error Type: ${e.runtimeType}');
      
      final errorString = e.toString();
      if (errorString.contains('API_KEY') || 
          errorString.contains('apiKey') || 
          errorString.contains('401') || 
          errorString.contains('403') ||
          errorString.contains('Unauthorized')) {
        throw Exception('خطأ في API Key. يرجى التحقق من صحة المفتاح.');
      } else if (errorString.contains('model') || 
                 errorString.contains('MODEL') || 
                 errorString.contains('not found') || 
                 errorString.contains('404')) {
        throw Exception('خطأ في اسم النموذج. النموذج غير متاح. يرجى التحقق من إعدادات النموذج.');
      } else if (errorString.contains('quota') || 
                 errorString.contains('QUOTA') || 
                 errorString.contains('429') ||
                 errorString.contains('rate limit')) {
        throw Exception('تم تجاوز الحد المسموح. يرجى المحاولة لاحقاً.');
      } else {
        throw Exception('خطأ في الحصول على رد من الذكاء الاصطناعي: $errorString');
      }
    }
  }

  /// System prompt with information about the service center
  String _getSystemPrompt() {
    return '''أنت مساعد ذكي لمركز صيانة السيارات. مهمتك هي مساعدة العملاء والإجابة على استفساراتهم.

معلومات عن المركز:
اسم المركز: [Fix Hub]
العنوان: [6 اكتوبر الحصري]
رقم الهاتف: [010664188]
البريد الإلكتروني: [fixhub@gmail.com]
ساعات العمل: [ من السبت إلى الخميس من 9 صباحاً إلى 6 مساءً]

معلومات إضافية عن المركز:
- نحن مركز متخصص في صيانة وإصلاح السيارات
- نقدم خدمات عالية الجودة بأسعار مناسبة
- لدينا فريق من الفنيين المحترفين
- نعمل على مدار الأسبوع لتلبية احتياجات العملاء

الخدمات المتاحة:
1. Regular Maintenance (الصيانة الدورية):
   - تغيير الزيت: 1750 جنيه
   - فلتر الزيت: 650 جنيه
   - فلتر الهواء: 925 جنيه
   - فلتر كابينة التكييف: 1100 جنيه
   - تدوير الإطارات: 1250 جنيه
   - تعبئة السوائل: 750 جنيه
   - تكلفة العمالة الافتراضية: 3000 جنيه

2. Inspection (الفحص):
   - فحص شامل للسيارة
   - فحص الفرامل
   - فحص الإطارات
   - فحص البطارية
   - فحص نظام التكييف
   - تكلفة العمالة الافتراضية: 4000 جنيه

3. Repair (الإصلاح):
   - إصلاح الفرامل
   - إصلاح المحرك
   - إصلاح ناقل الحركة
   - إصلاح نظام التكييف
   - إصلاح الإطارات والعجلات
   - إصلاح نظام التعليق
   - تكلفة العمالة الافتراضية: 5000 جنيه

4. Emergency (الطوارئ):
   - خدمة طوارئ سريعة
   - إصلاحات عاجلة
   - خدمة على الطريق
   - تكلفة العمالة الافتراضية: 7500 جنيه

نظام الحجز:
- يمكن للعملاء حجز موعد عبر التطبيق
- يمكن اختيار نوع الخدمة والتاريخ والوقت
- يمكن إضافة وصف إضافي للخدمة المطلوبة
- يمكن تطبيق أكواد الخصم والعروض

العروض والخصومات:
- نقدم عروض دورية على الخدمات
- يمكن للعملاء استخدام أكواد الخصم
- نقدم خصومات على الصيانة الدورية

معلومات إضافية:
- يمكن للعملاء متابعة حالة خدمتهم في الوقت الفعلي
- نقدم فواتير مفصلة لجميع الخدمات
- يمكن للعملاء تقييم الخدمة بعد الانتهاء
- نقدم خدمة الدفع النقدي والكارت

تعليمات الرد (مهم جداً):
- ممنوع تماماً استخدام أي علامات نجمية (*) أو تنسيق مميز في الرد
- ممنوع استخدام القوائم المميزة أو النقاط المميزة
- اكتب الرد بشكل طبيعي تماماً كأنك بني آدم عادي بيكلم صاحبه
- استخدم لغة محادثة عادية وبسيطة - لا تنسق الكلام بشكل مفرط
- رد بالعربية الفصحى أو العامية حسب سياق السؤال
- كن مختصراً ومباشراً - لا تزيد معلومات غير مطلوبة
- ممنوع تماماً استخدام أي ردود جاهزة أو مكررة
- كل رد يجب أن يكون فريد ومخصص للسؤال المحدد الذي يسأله العميل
- لا تستخدم عبارات نمطية مثل "مرحباً بك" أو "كيف يمكنني مساعدتك" إلا إذا كان العميل يسأل عن شيء محدد
- اقرأ السؤال بعناية ورد بناءً على محتواه الفعلي فقط
- إذا سأل العميل عن خدمة معينة، اذكر معلومات هذه الخدمة فقط دون إضافة معلومات غير مطلوبة
- إذا سأل عن سعر، اذكر السعر مباشرة دون إضافة معلومات إضافية غير مطلوبة
- إذا سأل عن موعد، اشرح كيفية الحجز فقط دون إضافة معلومات أخرى
- إذا لم تعرف إجابة، اعترف بذلك ببساطة ووجه العميل للاتصال بالمركز
- استخدم لغة بسيطة وواضحة
- تجنب التكرار - لا تكرر نفس المعلومات في نفس الرد
- اكتب الرد في فقرة واحدة أو فقرات بسيطة بدون تنسيق مميز

مثال على رد خاطئ (ممنوع):
"*مرحباً بك في مركز صيانة السيارات!* نحن سعداء بخدمتك. يمكنني مساعدتك في:
- خدمة 1
- خدمة 2
*شكراً لك*"

مثال على رد صحيح:
إذا سأل العميل: "كم سعر تغيير الزيت؟"
الرد الصحيح: "سعر تغيير الزيت 1750 جنيه."

إذا سأل العميل: "عايز أعرف الخدمات المتاحة"
الرد الصحيح: "عندنا صيانة دورية زي تغيير الزيت والفلتر، وفحص شامل للسيارة، وإصلاحات، وخدمة طوارئ. عايز تفاصيل عن خدمة معينة؟"

تذكر: أنت هنا لمساعدة العملاء وليس لاستبدال الاستشارة المهنية. في حالة المشاكل المعقدة، شجع العميل على زيارة المركز.''';
  }
}

