// test/unit/chatbot_entity_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:car_maintenance_system_new/features/chatbot/domain/entities/chat_message_entity.dart';
import 'package:car_maintenance_system_new/features/chatbot/domain/entities/chat_conversation_entity.dart';

void main() {
  final now = DateTime(2025, 6, 1, 10, 0);

  // ─── ChatMessageEntity ───────────────────────────────────────────────────

  group('ChatMessageEntity — Construction', () {
    test('creates user message', () {
      final msg = ChatMessageEntity(
        id: 'msg-001', text: 'How much is an oil change?',
        type: MessageType.user, timestamp: now,
      );
      expect(msg.id, equals('msg-001'));
      expect(msg.type, equals(MessageType.user));
      expect(msg.text, equals('How much is an oil change?'));
    });

    test('creates assistant message', () {
      final msg = ChatMessageEntity(
        id: 'msg-002', text: 'An oil change starts from 250 EGP.',
        type: MessageType.assistant, timestamp: now,
      );
      expect(msg.type, equals(MessageType.assistant));
    });
  });

  group('ChatMessageEntity — copyWith', () {
    test('copyWith updates text', () {
      final original = ChatMessageEntity(
        id: 'msg-001', text: 'Hello', type: MessageType.user, timestamp: now,
      );
      final updated = original.copyWith(text: 'Updated text');
      expect(updated.text, equals('Updated text'));
      expect(updated.id, equals('msg-001'));
      expect(original.text, equals('Hello'));
    });

    test('copyWith changes type', () {
      final original = ChatMessageEntity(
        id: 'msg-001', text: 'Test', type: MessageType.user, timestamp: now,
      );
      final updated = original.copyWith(type: MessageType.assistant);
      expect(updated.type, equals(MessageType.assistant));
    });
  });

  group('MessageType enum', () {
    test('has user and assistant types', () {
      expect(MessageType.values.length, equals(2));
      expect(MessageType.values, contains(MessageType.user));
      expect(MessageType.values, contains(MessageType.assistant));
    });
  });

  // ─── ChatConversationEntity ──────────────────────────────────────────────

  group('ChatConversationEntity — Construction', () {
    test('creates empty conversation', () {
      final conv = ChatConversationEntity(
        id: 'conv-001', userId: 'user-001', messages: [],
        createdAt: now, updatedAt: now,
      );
      expect(conv.id, equals('conv-001'));
      expect(conv.messages, isEmpty);
    });

    test('creates conversation with messages', () {
      final msgs = [
        ChatMessageEntity(id: 'm1', text: 'Hi', type: MessageType.user, timestamp: now),
        ChatMessageEntity(id: 'm2', text: 'Hello!', type: MessageType.assistant, timestamp: now),
      ];
      final conv = ChatConversationEntity(
        id: 'conv-002', userId: 'user-001', messages: msgs,
        createdAt: now, updatedAt: now,
      );
      expect(conv.messages.length, equals(2));
      expect(conv.messages.first.text, equals('Hi'));
    });
  });

  group('ChatConversationEntity — copyWith', () {
    test('copyWith adds new message', () {
      final original = ChatConversationEntity(
        id: 'conv-001', userId: 'user-001',
        messages: [
          ChatMessageEntity(id: 'm1', text: 'Hi', type: MessageType.user, timestamp: now),
        ],
        createdAt: now, updatedAt: now,
      );
      final newMessages = [
        ...original.messages,
        ChatMessageEntity(id: 'm2', text: 'Reply', type: MessageType.assistant, timestamp: now),
      ];
      final updated = original.copyWith(messages: newMessages);
      expect(updated.messages.length, equals(2));
      expect(original.messages.length, equals(1));
    });

    test('copyWith preserves userId', () {
      final original = ChatConversationEntity(
        id: 'conv-001', userId: 'user-001', messages: [],
        createdAt: now, updatedAt: now,
      );
      final updated = original.copyWith(updatedAt: DateTime(2025, 7, 1));
      expect(updated.userId, equals('user-001'));
    });
  });
}
