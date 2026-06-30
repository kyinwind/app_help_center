/// FAQ item displayed in the help center.
class HelpFaqItem {
  /// Creates an FAQ entry.
  const HelpFaqItem({
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

  /// Creates an FAQ item from JSON.
  factory HelpFaqItem.fromJson(Map<String, dynamic> json) {
    return HelpFaqItem(
      id: json['id'] as String?,
      question: json['question'] as String? ?? json['title'] as String? ?? '',
      answer: json['answer'] as String? ?? json['content'] as String? ?? '',
    );
  }

  /// Converts this FAQ item to JSON.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question': question,
      'answer': answer,
    };
  }
}
