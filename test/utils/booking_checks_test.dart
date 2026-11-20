import 'package:flutter_test/flutter_test.dart';
import 'package:pakiti_app/models/parcel_size.dart';
import 'package:pakiti_app/utils/booking_checks.dart';

Map<String, String> check({
  ParcelSize? size = ParcelSize.small,
  String contents = 'Shoes',
  String declaredValue = '1,800',
  String senderName = 'Esther Wambui',
  String senderPhone = '722 418 305',
  String senderEmail = '',
  String receiverName = 'Brian Kamau',
  String receiverPhone = '712 345 678',
  bool hasPhoto = true,
}) {
  return checkBooking(
    size: size,
    contents: contents,
    declaredValue: declaredValue,
    senderName: senderName,
    senderPhone: senderPhone,
    senderEmail: senderEmail,
    receiverName: receiverName,
    receiverPhone: receiverPhone,
    hasPhoto: hasPhoto,
  );
}

void main() {
  test('tidySpaces trims and joins spaces', () {
    expect(tidySpaces('  Esther   Wambui '), 'Esther Wambui');
  });

  test('a filled form has no errors', () {
    expect(check(), isEmpty);
  });

  test('an empty form has a message for each part', () {
    final errors = check(
      size: null,
      contents: '',
      declaredValue: '',
      senderName: '',
      senderPhone: '',
      receiverName: '',
      receiverPhone: '',
      hasPhoto: false,
    );

    expect(errors.keys, [
      'size',
      'contents',
      'declared_value',
      'sender_name',
      'sender_phone',
      'receiver_name',
      'receiver_phone',
      'photo',
    ]);
    expect(errors['sender_phone'], "Enter the sender's phone number.");
  });

  test('a name of spaces only does not count', () {
    expect(check(senderName: '   ').keys, ['sender_name']);
  });

  test('a phone number that is too short is flagged', () {
    expect(check(receiverPhone: '712 34').values, ["Check the receiver's phone number."]);
  });

  test('the email is optional but has to look like one', () {
    expect(check(senderEmail: ''), isEmpty);
    expect(check(senderEmail: 'esther@example.com'), isEmpty);
    expect(check(senderEmail: 'esther@').values, ['Check the email address.']);
  });
}
