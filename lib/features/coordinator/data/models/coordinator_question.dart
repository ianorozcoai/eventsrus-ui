/// Mirrors eventsrus-backend's {@code CoordinatorQuestionResponse}
/// field-for-field - one planner question + the Events Coordinator's
/// answer, scoped to a single event (see CoordinatorController/Service).
class CoordinatorQuestion {
  final int id;
  final String question;
  final String answer;
  final DateTime createdAt;

  const CoordinatorQuestion({
    required this.id,
    required this.question,
    required this.answer,
    required this.createdAt,
  });

  factory CoordinatorQuestion.fromJson(Map<String, dynamic> json) => CoordinatorQuestion(
        id: json['id'] as int,
        question: json['question'] as String,
        answer: json['answer'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
