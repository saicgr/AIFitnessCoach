import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitwiz/data/models/chat_message.dart';
import '../helpers/test_helpers.dart';

void main() {
  group('AgentType', () {
    test('should have all expected values', () {
      expect(AgentType.values.length, 5);
      expect(AgentType.values, contains(AgentType.coach));
      expect(AgentType.values, contains(AgentType.nutrition));
      expect(AgentType.values, contains(AgentType.workout));
      expect(AgentType.values, contains(AgentType.injury));
      expect(AgentType.values, contains(AgentType.hydration));
    });
  });

  group('AgentConfig', () {
    test('should return correct config for each agent type', () {
      final coachConfig = AgentConfig.forType(AgentType.coach);
      expect(coachConfig.name, 'coach');
      expect(coachConfig.displayName, 'AI Coach');
      expect(coachConfig.icon, Icons.smart_toy);

      final nutritionConfig = AgentConfig.forType(AgentType.nutrition);
      expect(nutritionConfig.name, 'nutrition');
      expect(nutritionConfig.displayName, 'Nutrition Expert');
      expect(nutritionConfig.icon, Icons.restaurant_menu);

      final workoutConfig = AgentConfig.forType(AgentType.workout);
      expect(workoutConfig.name, 'workout');
      expect(workoutConfig.displayName, 'Workout Specialist');
      expect(workoutConfig.icon, Icons.fitness_center);

      final injuryConfig = AgentConfig.forType(AgentType.injury);
      expect(injuryConfig.name, 'injury');
      expect(injuryConfig.displayName, 'Recovery Advisor');
      expect(injuryConfig.icon, Icons.healing);

      final hydrationConfig = AgentConfig.forType(AgentType.hydration);
      expect(hydrationConfig.name, 'hydration');
      expect(hydrationConfig.displayName, 'Hydration Tracker');
      expect(hydrationConfig.icon, Icons.water_drop);
    });

    test('should return all available agents', () {
      final agents = AgentConfig.allAgents;
      expect(agents.length, 5);
    });

    test('should return correct background color based on brightness', () {
      final config = AgentConfig.forType(AgentType.coach);

      final darkColor = config.getBackgroundColor(Brightness.dark);
      final lightColor = config.getBackgroundColor(Brightness.light);

      expect(darkColor, config.backgroundColorDark);
      expect(lightColor, config.backgroundColorLight);
    });

    test('backgroundColor getter should return dark mode color', () {
      final config = AgentConfig.forType(AgentType.coach);
      expect(config.backgroundColor, config.backgroundColorDark);
    });
  });

  group('ChatMessage', () {
    group('fromJson', () {
      test('should create ChatMessage from valid JSON', () {
        final json = JsonFixtures.chatMessageJson();
        final message = ChatMessage.fromJson(json);

        expect(message.id, 'test-message-id');
        expect(message.userId, 'test-user-id');
        expect(message.role, 'assistant');
        expect(message.content, 'Hello! I am your AI fitness coach.');
        expect(message.intent, 'greeting');
        expect(message.agentType, AgentType.coach);
      });

      test('should handle missing optional fields', () {
        final json = {
          'role': 'user',
          'content': 'Hello',
        };
        final message = ChatMessage.fromJson(json);

        expect(message.id, isNull);
        expect(message.userId, isNull);
        expect(message.role, 'user');
        expect(message.content, 'Hello');
        expect(message.intent, isNull);
        expect(message.agentType, isNull);
      });
    });

    group('toJson', () {
      test('should serialize ChatMessage to JSON', () {
        final message = TestFixtures.createChatMessage(
          role: 'assistant',
          content: 'Test content',
          agentType: AgentType.coach,
        );
        final json = message.toJson();

        expect(json['role'], 'assistant');
        expect(json['content'], 'Test content');
        expect(json['agent_type'], 'coach');
      });
    });

    group('isUser', () {
      test('should return true for user role', () {
        final message = TestFixtures.createChatMessage(role: 'user');
        expect(message.isUser, true);
      });

      test('should return false for assistant role', () {
        final message = TestFixtures.createChatMessage(role: 'assistant');
        expect(message.isUser, false);
      });
    });

    group('isAssistant', () {
      test('should return true for assistant role', () {
        final message = TestFixtures.createChatMessage(role: 'assistant');
        expect(message.isAssistant, true);
      });

      test('should return false for user role', () {
        final message = TestFixtures.createChatMessage(role: 'user');
        expect(message.isAssistant, false);
      });
    });

    group('agentConfig', () {
      test('should return config for message agent type', () {
        final message = TestFixtures.createChatMessage(agentType: AgentType.nutrition);
        expect(message.agentConfig.name, 'nutrition');
      });

      test('should default to coach when agent type is null', () {
        final message = TestFixtures.createChatMessage(agentType: null);
        expect(message.agentConfig.name, 'coach');
      });
    });

    group('timestamp', () {
      test('should parse ISO8601 timestamp', () {
        final isoDate = '2025-12-24T10:30:00.000Z';
        final message = TestFixtures.createChatMessage(createdAt: isoDate);

        expect(message.timestamp, isNotNull);
        expect(message.timestamp!.year, 2025);
        expect(message.timestamp!.month, 12);
        expect(message.timestamp!.day, 24);
      });

      test('should parse PostgreSQL timestamp format', () {
        final pgDate = '2025-12-24 10:30:00+00';
        final message = TestFixtures.createChatMessage(createdAt: pgDate);

        expect(message.timestamp, isNotNull);
      });

      test('should return null for null createdAt', () {
        final message = TestFixtures.createChatMessage(createdAt: null);
        expect(message.timestamp, isNull);
      });

      test('should return null for empty createdAt', () {
        final message = ChatMessage(
          role: 'user',
          content: 'test',
          createdAt: '',
        );
        expect(message.timestamp, isNull);
      });
    });

    group('hasGeneratedWorkout', () {
      test('should return true when action is generate_quick_workout with workout_id', () {
        final message = ChatMessage(
          role: 'assistant',
          content: 'Here is your workout',
          actionData: {
            'action': 'generate_quick_workout',
            'workout_id': 'workout-123',
          },
        );
        expect(message.hasGeneratedWorkout, true);
      });

      test('should return false when action is different', () {
        final message = ChatMessage(
          role: 'assistant',
          content: 'Navigating',
          actionData: {
            'action': 'navigate',
            'destination': 'home',
          },
        );
        expect(message.hasGeneratedWorkout, false);
      });

      test('should return false when workout_id is null', () {
        final message = ChatMessage(
          role: 'assistant',
          content: 'Generating...',
          actionData: {
            'action': 'generate_quick_workout',
            'workout_id': null,
          },
        );
        expect(message.hasGeneratedWorkout, false);
      });

      test('should return false when actionData is null', () {
        final message = TestFixtures.createChatMessage();
        expect(message.hasGeneratedWorkout, false);
      });
    });

    group('workoutId', () {
      test('should return workout_id from actionData', () {
        final message = ChatMessage(
          role: 'assistant',
          content: 'Workout ready',
          actionData: {'workout_id': 'workout-456'},
        );
        expect(message.workoutId, 'workout-456');
      });

      test('should return null when not present', () {
        final message = TestFixtures.createChatMessage();
        expect(message.workoutId, isNull);
      });
    });

    group('workoutName', () {
      test('should return workout_name from actionData', () {
        final message = ChatMessage(
          role: 'assistant',
          content: 'Workout ready',
          actionData: {'workout_name': 'Quick HIIT Session'},
        );
        expect(message.workoutName, 'Quick HIIT Session');
      });

      test('should return null when not present', () {
        final message = TestFixtures.createChatMessage();
        expect(message.workoutName, isNull);
      });
    });

    group('Equatable', () {
      test('should be equal when all properties match', () {
        final m1 = ChatMessage(
          id: '1',
          role: 'user',
          content: 'Hello',
          createdAt: '2025-01-01T00:00:00Z',
        );
        final m2 = ChatMessage(
          id: '1',
          role: 'user',
          content: 'Hello',
          createdAt: '2025-01-01T00:00:00Z',
        );
        expect(m1, equals(m2));
      });

      test('should not be equal when content differs', () {
        final m1 = ChatMessage(id: '1', role: 'user', content: 'Hello');
        final m2 = ChatMessage(id: '1', role: 'user', content: 'Hi');
        expect(m1, isNot(equals(m2)));
      });
    });
  });

  group('ChatRequest', () {
    test('should create from JSON', () {
      final json = {
        'message': 'Hello',
        'user_id': 'user-123',
        'user_profile': {'fitness_level': 'intermediate'},
      };
      final request = ChatRequest.fromJson(json);

      expect(request.message, 'Hello');
      expect(request.userId, 'user-123');
      expect(request.userProfile, {'fitness_level': 'intermediate'});
    });

    test('should serialize to JSON', () {
      const request = ChatRequest(
        message: 'Hello',
        userId: 'user-123',
        userProfile: {'fitness_level': 'beginner'},
      );
      final json = request.toJson();

      expect(json['message'], 'Hello');
      expect(json['user_id'], 'user-123');
      expect(json['user_profile'], {'fitness_level': 'beginner'});
    });
  });

  group('ChatResponse', () {
    test('should create from JSON', () {
      final json = JsonFixtures.chatResponseJson();
      final response = ChatResponse.fromJson(json);

      expect(response.message, 'Hello! How can I help you today?');
      expect(response.intent, 'greeting');
      expect(response.agentType, AgentType.coach);
      expect(response.actionData, isNull);
    });

    test('should handle action_data', () {
      final json = {
        'message': 'Dark mode enabled',
        'intent': 'settings_change',
        'action_data': {
          'action': 'change_setting',
          'setting_name': 'dark_mode',
          'setting_value': true,
        },
      };
      final response = ChatResponse.fromJson(json);

      expect(response.actionData, isNotNull);
      expect(response.actionData!['action'], 'change_setting');
      expect(response.actionData!['setting_name'], 'dark_mode');
      expect(response.actionData!['setting_value'], true);
    });

    test('should serialize to JSON', () {
      const response = ChatResponse(
        message: 'Test response',
        intent: 'test',
        agentType: AgentType.workout,
      );
      final json = response.toJson();

      expect(json['message'], 'Test response');
      expect(json['intent'], 'test');
      expect(json['agent_type'], 'workout');
    });
  });

  group('ChatHistoryItem', () {
    test('should create from JSON', () {
      final json = {
        'id': 'history-id',
        'role': 'assistant',
        'content': 'History message',
        'timestamp': '2025-01-01T00:00:00Z',
        'agent_type': 'nutrition',
      };
      final item = ChatHistoryItem.fromJson(json);

      expect(item.id, 'history-id');
      expect(item.role, 'assistant');
      expect(item.content, 'History message');
      expect(item.timestamp, '2025-01-01T00:00:00Z');
      expect(item.agentType, AgentType.nutrition);
    });

    test('should convert to ChatMessage', () {
      final item = ChatHistoryItem(
        id: 'item-id',
        role: 'user',
        content: 'Test content',
        timestamp: '2025-01-01T00:00:00Z',
        agentType: AgentType.coach,
      );
      final message = item.toChatMessage();

      expect(message.id, 'item-id');
      expect(message.role, 'user');
      expect(message.content, 'Test content');
      expect(message.createdAt, '2025-01-01T00:00:00Z');
      expect(message.agentType, AgentType.coach);
    });

    test('should serialize to JSON', () {
      const item = ChatHistoryItem(
        id: 'item-id',
        role: 'assistant',
        content: 'Content',
      );
      final json = item.toJson();

      expect(json['id'], 'item-id');
      expect(json['role'], 'assistant');
      expect(json['content'], 'Content');
    });
  });
}
