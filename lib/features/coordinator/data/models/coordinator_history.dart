import 'coordinator_question.dart';

/// Mirrors eventsrus-backend's {@code CoordinatorHistoryResponse}
/// field-for-field - every question asked on this event so far, plus how
/// many more the planner can ask today (see CoordinatorService, which
/// enforces SystemSettingKey.COORDINATOR_DAILY_QUESTION_LIMIT and resets at
/// midnight Asia/Manila).
class CoordinatorHistory {
  final List<CoordinatorQuestion> questions;
  final int questionsRemainingToday;
  final int dailyLimit;

  const CoordinatorHistory({
    required this.questions,
    required this.questionsRemainingToday,
    required this.dailyLimit,
  });

  factory CoordinatorHistory.fromJson(Map<String, dynamic> json) => CoordinatorHistory(
        questions: (json['questions'] as List? ?? [])
            .map((e) => CoordinatorQuestion.fromJson(e as Map<String, dynamic>))
            .toList(),
        questionsRemainingToday: json['questionsRemainingToday'] as int,
        dailyLimit: json['dailyLimit'] as int,
      );
}
