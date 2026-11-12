import 'destination.dart';
import 'parcel_size.dart';

// what the clerk filled in, already checked and tidied
class NewParcel {
  const NewParcel({
    required this.destination,
    required this.size,
    required this.contents,
    required this.value,
    required this.senderName,
    required this.senderPhone,
    this.senderEmail,
    required this.receiverName,
    required this.receiverPhone,
    required this.photoPath,
  });

  final Destination destination;
  final ParcelSize size;
  final String contents;
  final int value;
  final String senderName;
  final String senderPhone;
  final String? senderEmail;
  final String receiverName;
  final String receiverPhone;
  final String photoPath;

  num get fee => destination.fees[size]!;
}