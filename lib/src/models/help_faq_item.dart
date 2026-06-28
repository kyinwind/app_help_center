/// FAQ item displayed in the help center.
class HelpFaqItem {
  /// Creates an FAQ entry.
  HelpFaqItem({
    String? id,
    required this.question,
    required this.answer,
  }) : id = id ?? question;

  /// Stable identifier for this FAQ item.
  final String id;

  /// Question shown in the FAQ list.
  final String question;

  /// Answer shown when the FAQ item expands.
  final String answer;
}
