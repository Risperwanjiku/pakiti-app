// same rule as Phone::normalize in the API:
// 0712 345 678, 712 345 678 or +254 712 345 678 all become +254712345678
String? normalizePhone(String input) {
  final phone = input.replaceAll(RegExp(r'[\s-]'), '');
  final match = RegExp(r'^(?:\+?254|0)?([17]\d{8})$').firstMatch(phone);

  return match == null ? null : '+254${match.group(1)}';
}