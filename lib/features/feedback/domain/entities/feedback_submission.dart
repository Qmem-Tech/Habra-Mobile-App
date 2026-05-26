import 'package:equatable/equatable.dart';

enum FeedbackType {
  positive,
  negative,
  bugReport,
  suggestion,
}

extension FeedbackTypeExtension on FeedbackType {
  String get displayName {
    switch (this) {
      case FeedbackType.positive:
        return 'Positive';
      case FeedbackType.negative:
        return 'Negative';
      case FeedbackType.bugReport:
        return 'Bug Report';
      case FeedbackType.suggestion:
        return 'Suggestion';
    }
  }
}

/// Represents a feedback submission (for sending to backend).
class FeedbackSubmission extends Equatable {
  final FeedbackType type;
  final String text;

  const FeedbackSubmission({
    required this.type,
    required this.text,
  });

  @override
  List<Object> get props => [type, text];
}
