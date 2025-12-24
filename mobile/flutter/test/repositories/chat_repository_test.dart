import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ai_fitness_coach/data/repositories/chat_repository.dart';
import 'package:ai_fitness_coach/data/models/chat_message.dart';
import '../helpers/test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockApiClient mockApiClient;
  late ChatRepository repository;

  setUp(() {
    setUpMocks();
    mockApiClient = MockApiClient();
    repository = ChatRepository(mockApiClient);
  });

  group('ChatRepository', () {
    group('getChatHistory', () {
      test('should return list of messages on success', () async {
        final messagesJson = [
          {
            'id': 'msg-1',
            'role': 'user',
            'content': 'Hello!',
            'timestamp': '2025-01-15T10:00:00Z',
          },
          {
            'id': 'msg-2',
            'role': 'assistant',
            'content': 'Hi! How can I help?',
            'timestamp': '2025-01-15T10:01:00Z',
            'agent_type': 'coach',
          },
        ];

        when(() => mockApiClient.get(
          any(),
          queryParameters: any(named: 'queryParameters'),
        )).thenAnswer((_) async => Response(
          requestOptions: RequestOptions(path: '/chat/history/user-123'),
          statusCode: 200,
          data: messagesJson,
        ));

        final messages = await repository.getChatHistory('user-123');

        expect(messages.length, 2);
        expect(messages[0].role, 'user');
        expect(messages[0].content, 'Hello!');
        expect(messages[1].role, 'assistant');
        expect(messages[1].content, 'Hi! How can I help?');
        expect(messages[1].agentType, AgentType.coach);
      });

      test('should return list with correct limit parameter', () async {
        when(() => mockApiClient.get(
          any(),
          queryParameters: any(named: 'queryParameters'),
        )).thenAnswer((_) async => Response(
          requestOptions: RequestOptions(path: '/chat/history/user-123'),
          statusCode: 200,
          data: [],
        ));

        await repository.getChatHistory('user-123', limit: 50);

        verify(() => mockApiClient.get(
          any(),
          queryParameters: {'limit': 50},
        )).called(1);
      });

      test('should default limit to 100', () async {
        when(() => mockApiClient.get(
          any(),
          queryParameters: any(named: 'queryParameters'),
        )).thenAnswer((_) async => Response(
          requestOptions: RequestOptions(path: '/chat/history/user-123'),
          statusCode: 200,
          data: [],
        ));

        await repository.getChatHistory('user-123');

        verify(() => mockApiClient.get(
          any(),
          queryParameters: {'limit': 100},
        )).called(1);
      });

      test('should return empty list on non-200 status', () async {
        when(() => mockApiClient.get(
          any(),
          queryParameters: any(named: 'queryParameters'),
        )).thenAnswer((_) async => Response(
          requestOptions: RequestOptions(path: '/chat/history/user-123'),
          statusCode: 404,
          data: null,
        ));

        final messages = await repository.getChatHistory('user-123');

        expect(messages, isEmpty);
      });

      test('should rethrow on error', () async {
        when(() => mockApiClient.get(
          any(),
          queryParameters: any(named: 'queryParameters'),
        )).thenThrow(DioException(
          requestOptions: RequestOptions(path: '/chat/history/user-123'),
          error: 'Network error',
        ));

        expect(
          () => repository.getChatHistory('user-123'),
          throwsA(isA<DioException>()),
        );
      });
    });

    group('sendMessage', () {
      test('should return ChatResponse on success', () async {
        final responseJson = {
          'message': 'I can help you with that!',
          'intent': 'assistance',
          'agent_type': 'coach',
          'action_data': null,
        };

        when(() => mockApiClient.post(
          any(),
          data: any(named: 'data'),
        )).thenAnswer((_) async => Response(
          requestOptions: RequestOptions(path: '/chat/send'),
          statusCode: 200,
          data: responseJson,
        ));

        final response = await repository.sendMessage(
          message: 'Help me!',
          userId: 'user-123',
        );

        expect(response.message, 'I can help you with that!');
        expect(response.intent, 'assistance');
        expect(response.agentType, AgentType.coach);
        expect(response.actionData, isNull);
      });

      test('should send user profile and workout context', () async {
        when(() => mockApiClient.post(
          any(),
          data: any(named: 'data'),
        )).thenAnswer((_) async => Response(
          requestOptions: RequestOptions(path: '/chat/send'),
          statusCode: 200,
          data: JsonFixtures.chatResponseJson(),
        ));

        await repository.sendMessage(
          message: 'How should I train?',
          userId: 'user-123',
          userProfile: {'fitness_level': 'intermediate'},
          currentWorkout: {'name': 'Upper Body', 'type': 'strength'},
          aiSettings: {'coaching_style': 'encouraging'},
        );

        final captured = verify(() => mockApiClient.post(
          any(),
          data: captureAny(named: 'data'),
        )).captured.single as Map<String, dynamic>;

        expect(captured['message'], 'How should I train?');
        expect(captured['user_id'], 'user-123');
        expect(captured['user_profile'], {'fitness_level': 'intermediate'});
        expect(captured['current_workout'], {'name': 'Upper Body', 'type': 'strength'});
        expect(captured['ai_settings'], {'coaching_style': 'encouraging'});
      });

      test('should include conversation history', () async {
        when(() => mockApiClient.post(
          any(),
          data: any(named: 'data'),
        )).thenAnswer((_) async => Response(
          requestOptions: RequestOptions(path: '/chat/send'),
          statusCode: 200,
          data: JsonFixtures.chatResponseJson(),
        ));

        final history = [
          {'role': 'user', 'content': 'Hi'},
          {'role': 'assistant', 'content': 'Hello!'},
        ];

        await repository.sendMessage(
          message: 'What should I do today?',
          userId: 'user-123',
          conversationHistory: history,
        );

        final captured = verify(() => mockApiClient.post(
          any(),
          data: captureAny(named: 'data'),
        )).captured.single as Map<String, dynamic>;

        expect(captured['conversation_history'], history);
      });

      test('should return response with action_data', () async {
        final responseJson = {
          'message': 'Enabling dark mode...',
          'intent': 'settings_change',
          'action_data': {
            'action': 'change_setting',
            'setting_name': 'dark_mode',
            'setting_value': true,
          },
        };

        when(() => mockApiClient.post(
          any(),
          data: any(named: 'data'),
        )).thenAnswer((_) async => Response(
          requestOptions: RequestOptions(path: '/chat/send'),
          statusCode: 200,
          data: responseJson,
        ));

        final response = await repository.sendMessage(
          message: 'Enable dark mode',
          userId: 'user-123',
        );

        expect(response.actionData, isNotNull);
        expect(response.actionData!['action'], 'change_setting');
        expect(response.actionData!['setting_name'], 'dark_mode');
        expect(response.actionData!['setting_value'], true);
      });

      test('should throw on non-200 status', () async {
        when(() => mockApiClient.post(
          any(),
          data: any(named: 'data'),
        )).thenAnswer((_) async => Response(
          requestOptions: RequestOptions(path: '/chat/send'),
          statusCode: 500,
          data: {'error': 'Server error'},
        ));

        expect(
          () => repository.sendMessage(
            message: 'Test',
            userId: 'user-123',
          ),
          throwsA(isA<Exception>()),
        );
      });

      test('should rethrow DioException', () async {
        when(() => mockApiClient.post(
          any(),
          data: any(named: 'data'),
        )).thenThrow(DioException(
          requestOptions: RequestOptions(path: '/chat/send'),
          error: 'Connection timeout',
        ));

        expect(
          () => repository.sendMessage(
            message: 'Test',
            userId: 'user-123',
          ),
          throwsA(isA<DioException>()),
        );
      });
    });
  });

  group('ChatRequest', () {
    test('should serialize to JSON correctly', () {
      const request = ChatRequest(
        message: 'Hello',
        userId: 'user-123',
        userProfile: {'fitness_level': 'beginner'},
        currentWorkout: {'name': 'Test Workout'},
        workoutSchedule: {'today': {'name': 'Leg Day'}},
        conversationHistory: [
          {'role': 'user', 'content': 'Hi'}
        ],
        aiSettings: {'coaching_style': 'strict'},
      );

      final json = request.toJson();

      expect(json['message'], 'Hello');
      expect(json['user_id'], 'user-123');
      expect(json['user_profile'], {'fitness_level': 'beginner'});
      expect(json['current_workout'], {'name': 'Test Workout'});
      expect(json['workout_schedule'], {'today': {'name': 'Leg Day'}});
      expect(json['conversation_history'], [{'role': 'user', 'content': 'Hi'}]);
      expect(json['ai_settings'], {'coaching_style': 'strict'});
    });

    test('should create from JSON correctly', () {
      final json = {
        'message': 'Help me',
        'user_id': 'user-456',
        'user_profile': {'goals': ['lose weight']},
      };

      final request = ChatRequest.fromJson(json);

      expect(request.message, 'Help me');
      expect(request.userId, 'user-456');
      expect(request.userProfile, {'goals': ['lose weight']});
      expect(request.currentWorkout, isNull);
    });
  });
}
