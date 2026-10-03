class NoteValidator {
  static const int titleMaxLength = 100;
  static const int maxLength = 1000; // description

  /// Title is required. Returns an error message, or null when valid.
  static String? validateTitle(String? text) {
    final value = text?.trim() ?? '';
    if (value.isEmpty) return 'Title cannot be empty';
    if (value.length > titleMaxLength) {
      return 'Title is too long (max $titleMaxLength characters)';
    }
    return null;
  }

  /// Description is optional, but limited in length.
  static String? validateDescription(String? text) {
    final value = text?.trim() ?? '';
    if (value.length > maxLength) {
      return 'Description is too long (max $maxLength characters)';
    }
    return null;
  }
}

