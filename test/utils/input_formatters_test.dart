import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pakiti_app/utils/input_formatters.dart';

String typeInto(TextInputFormatter formatter, String typed) {
  return formatter.formatEditUpdate(TextEditingValue.empty, TextEditingValue(text: typed)).text;
}

void main() {
  group('PhoneInputFormatter', () {
    test('drops the leading 0, since +254 is already shown', () {
      expect(typeInto(PhoneInputFormatter(), '0722418305'), '722 418 305');
    });

    test('drops 254 when a whole number is pasted', () {
      expect(typeInto(PhoneInputFormatter(), '+254722418305'), '722 418 305');
    });

    test('groups the digits while they are typed', () {
      expect(typeInto(PhoneInputFormatter(), '7224'), '722 4');
    });

    test('stops at 9 digits and ignores anything that is not a digit', () {
      expect(typeInto(PhoneInputFormatter(), '7224183059999'), '722 418 305');
      expect(typeInto(PhoneInputFormatter(), '72a2-41'), '722 41');
    });
  });

  group('AmountInputFormatter', () {
    test('adds commas', () {
      expect(typeInto(AmountInputFormatter(), '1800'), '1,800');
      expect(typeInto(AmountInputFormatter(), '1234567'), '1,234,567');
    });

    test('drops leading zeros but keeps a single 0', () {
      expect(typeInto(AmountInputFormatter(), '0050'), '50');
      expect(typeInto(AmountInputFormatter(), '0'), '0');
    });

    test('allows at most 8 digits', () {
      expect(typeInto(AmountInputFormatter(), '123456789'), '12,345,678');
    });
  });
}
