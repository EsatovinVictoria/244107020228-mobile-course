bool isValidNoteTitle(String value) {
  final trimmed = value.trim();
  return trimmed.isNotEmpty && trimmed.length <= 100;
}

String? validateNoteTitle(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    return 'Judul catatan tidak boleh kosong';
  }
  if (trimmed.length > 100) {
    return 'Judul catatan maksimal 100 karakter';
  }
  return null;
}
