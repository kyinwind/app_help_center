class HelpFaqItem {
  HelpFaqItem({
    String? id,
    required this.question,
    required this.answer,
  }) : id = id ?? question;

  final String id;
  final String question;
  final String answer;
}
