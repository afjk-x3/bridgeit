/// One line of the live checklist under the Level 2 writing box.
class ChecklistItem {
  const ChecklistItem(this.label, this.met);

  final String label;
  final bool met;
}

/// What a sentence with [word] needs, checked as the student types.
List<ChecklistItem> sentenceChecklist(String text, String word) {
  final trimmed = text.trim();
  final escaped = RegExp.escape(word);
  final first = trimmed.isEmpty ? '' : trimmed[0];
  return [
    ChecklistItem(
      'Starts with a capital',
      first != first.toLowerCase() && first == first.toUpperCase(),
    ),
    ChecklistItem(
      "Uses '$word'",
      RegExp('\\b$escaped\\b', caseSensitive: false).hasMatch(text),
    ),
    ChecklistItem(
      "Comma right before '$word'",
      RegExp(',\\s*\\b$escaped\\b', caseSensitive: false).hasMatch(text),
    ),
    ChecklistItem('Ends with . ! or ?', RegExp(r'[.!?]$').hasMatch(trimmed)),
  ];
}
