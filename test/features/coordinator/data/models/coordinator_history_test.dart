import 'package:eventsrus_ui/features/coordinator/data/models/coordinator_history.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('CoordinatorHistory.fromJson parses questions and quota fields', () {
    final history = CoordinatorHistory.fromJson({
      'questions': [
        {
          'id': 1,
          'question': 'Any theme ideas?',
          'answer': 'A garden party theme could work well.',
          'createdAt': '2026-09-01T10:00:00Z',
        },
      ],
      'questionsRemainingToday': 4,
      'dailyLimit': 5,
    });

    expect(history.questions, hasLength(1));
    expect(history.questions.single.question, 'Any theme ideas?');
    expect(history.questionsRemainingToday, 4);
    expect(history.dailyLimit, 5);
  });

  test('CoordinatorHistory.fromJson defaults questions to an empty list when absent', () {
    final history = CoordinatorHistory.fromJson({
      'questionsRemainingToday': 5,
      'dailyLimit': 5,
    });

    expect(history.questions, isEmpty);
  });
}
