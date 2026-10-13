/// Phone number normalisation to E.164 for Pakistan.
///
/// Must stay identical to `PhoneNormalizer.kt` so hashes match on both sides.
String normalizePhone(String raw) {
  final trimmed = raw.trim();
  final digits = trimmed.replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.isEmpty) return '';
  if (digits.startsWith('0092')) return '+92${digits.substring(4)}';
  if (digits.startsWith('92') && digits.length == 12) return '+$digits';
  if (digits.startsWith('03') && digits.length == 11) {
    return '+92${digits.substring(1)}';
  }
  if (digits.startsWith('3') && digits.length == 10) return '+92$digits';
  // Short codes (8171) and foreign numbers keep their digits.
  return trimmed.startsWith('+') ? '+$digits' : digits;
}

/// Shows a Pakistani mobile number as 0300 1234567.
String formatPhone(String raw) {
  final n = normalizePhone(raw);
  if (n.startsWith('+92') && n.length == 13) {
    final local = '0${n.substring(3)}';
    return '${local.substring(0, 4)} ${local.substring(4)}';
  }
  return raw;
}
