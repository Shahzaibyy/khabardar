/// Removes secrets from message text before it is stored or reported.
///
/// Must stay in step with `Masking.kt`.
String maskSensitive(String text) {
  var out = text;
  // CNIC: 12345-1234567-1 or 13 digits in a row.
  out = out.replaceAll(RegExp(r'\b\d{5}-?\d{7}-?\d\b'), '•••••-•••••••-•');
  // IBAN and long account / card numbers.
  out = out.replaceAll(
    RegExp(r'\bPK\d{2}[A-Z]{4}\d{16}\b', caseSensitive: false),
    'PK•• •••• ••••',
  );
  out = out.replaceAllMapped(
    RegExp(r'\b\d{10,19}\b'),
    (m) => '•' * m[0]!.length,
  );
  // OTPs and PINs: 4 to 8 digit codes.
  out = out.replaceAllMapped(
    RegExp(r'\b\d{4,8}\b'),
    (m) => m[0] == '8171' ? m[0]! : '•' * m[0]!.length,
  );
  return out;
}
