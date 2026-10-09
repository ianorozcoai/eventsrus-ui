import 'package:eventsrus_ui/features/coordinator/data/models/coordinator_question.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('CoordinatorQuestion.fromJson parses a full response', () {
    final question = CoordinatorQuestion.fromJson({
      'id': 7,
      'question': 'What theme works for a beach wedding?',
      'answer': 'Consider a tropical minimalist theme with neutral tones...',
      'createdAt': '2026-09-01T10:00:00Z',
    });

    expect(question.id, 7);
    expect(question.question, 'What theme works for a beach wedding?');
    expect(question.answer, 'Consider a tropical minimalist theme with neutral tones...');
    expect(question.createdAt, DateTime.parse('2026-09-01T10:00:00Z'));
  });
}
