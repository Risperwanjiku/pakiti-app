import 'package:flutter_test/flutter_test.dart';
import 'package:pakiti_app/utils/phone.dart';

// the same cases as PhoneTest.php in the API, so the app and the server agree
void main() {
  test('saves every way of typing a number in one format', () {
    for (final typed in [
      '0712345678',
      '0712 345 678',
      '712345678',
      '254712345678',
      '+254712345678',
      '+254-712-345-678',
    ]) {
      expect(normalizePhone(typed), '+254712345678', reason: typed);
    }
  });

  test('accepts numbers starting with 01', () {
    expect(normalizePhone('0112 345 678'), '+254112345678');
  });

  test('rejects numbers that are not Kenyan mobiles', () {
    for (final typed in [
      '',
      '071234567',
      '07123456789',
      '0201234567',
      '07123abc78',
      '+2540712345678',
    ]) {
      expect(normalizePhone(typed), isNull, reason: typed);
    }
  });
}
