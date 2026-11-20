import 'package:pakiti_app/models/parcel_size.dart';
import 'package:pakiti_app/utils/phone.dart';

final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

// "  Esther   Wambui " -> "Esther Wambui"
String tidySpaces(String text) => text.trim().replaceAll(RegExp(r'\s+'), ' ');

// The same checks the API makes, so most mistakes are caught before sending.
// Gives back a message for each field that is wrong, keyed by the API's field names.
Map<String, String> checkBooking({
  required ParcelSize? size,
  required String contents,
  required String declaredValue,
  required String senderName,
  required String senderPhone,
  required String senderEmail,
  required String receiverName,
  required String receiverPhone,
  required bool hasPhoto,
}) {
  final errors = <String, String>{};
  final email = senderEmail.trim();

  if (size == null) {
    errors['size'] = 'Choose the size of the parcel.';
  }
  if (tidySpaces(contents).length < 2) {
    errors['contents'] = "Say what's inside the parcel.";
  }
  if (int.tryParse(declaredValue.replaceAll(',', '')) == null) {
    errors['declared_value'] = 'Enter the value in shillings.';
  }
  if (tidySpaces(senderName).length < 2) {
    errors['sender_name'] = "Enter the sender's name.";
  }
  if (senderPhone.isEmpty) {
    errors['sender_phone'] = "Enter the sender's phone number.";
  } else if (normalizePhone(senderPhone) == null) {
    errors['sender_phone'] = "Check the sender's phone number.";
  }
  if (email.isNotEmpty && !_emailPattern.hasMatch(email)) {
    errors['sender_email'] = 'Check the email address.';
  }
  if (tidySpaces(receiverName).length < 2) {
    errors['receiver_name'] = "Enter the receiver's name.";
  }
  if (receiverPhone.isEmpty) {
    errors['receiver_phone'] = "Enter the receiver's phone number.";
  } else if (normalizePhone(receiverPhone) == null) {
    errors['receiver_phone'] = "Check the receiver's phone number.";
  }
  if (!hasPhoto) {
    errors['photo'] = 'Take a photo of the parcel before booking.';
  }

  return errors;
}
