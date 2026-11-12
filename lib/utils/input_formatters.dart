import 'package:flutter/services.dart';

// the field already shows +254, so a leading 0 is dropped and the rest reads 722 418 305
class PhoneInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var digits = newValue.text.replaceAll(RegExp(r'\D'), '');

    if (digits.startsWith('254') && digits.length > 9) {
      digits = digits.substring(3);
    }
    if (digits.startsWith('0')) {
      digits = digits.substring(1);
    }
    if (digits.length > 9) {
      digits = digits.substring(0, 9);
    }

    final text = [
      for (var i = 0; i < digits.length; i += 3)
        digits.substring(i, i + 3 < digits.length ? i + 3 : digits.length),
    ].join(' ');

    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

// whole shillings with commas, like 1,800
class AmountInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var digits = newValue.text.replaceAll(RegExp(r'\D'), '');

    if (digits.length > 8) {
      digits = digits.substring(0, 8);
    }
    digits = digits.replaceFirst(RegExp(r'^0+(?=\d)'), '');

    final text = digits.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',');

    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}