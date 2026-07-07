bool isValidEmail(String value) {
  final normalized = value.trim();
  if (normalized.isEmpty) return false;

  final regex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  return regex.hasMatch(normalized);
}
