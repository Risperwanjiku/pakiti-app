import 'parcel_size.dart';

class BookedParcel {
  const BookedParcel({
    required this.trackingNo,
    required this.from,
    required this.to,
    required this.senderName,
    required this.senderPhone,
    this.senderEmail,
    required this.receiverName,
    required this.receiverPhone,
    required this.contents,
    required this.value,
    required this.size,
    required this.fee,
    required this.bookedAt,
    required this.bookedBy,
  });

  factory BookedParcel.fromJson(Map<String, dynamic> json) {
    final sender = json['sender'] as Map<String, dynamic>;
    final receiver = json['receiver'] as Map<String, dynamic>;

    return BookedParcel(
      trackingNo: json['tracking_no'] as String,
      from: json['from'] as String,
      to: json['to'] as String,
      senderName: sender['name'] as String,
      senderPhone: sender['phone'] as String,
      senderEmail: sender['email'] as String?,
      receiverName: receiver['name'] as String,
      receiverPhone: receiver['phone'] as String,
      contents: json['contents'] as String,
      value: json['declared_value'] as num,
      size: ParcelSize.values.byName(json['size'] as String),
      fee: json['fee'] as num,
      bookedAt: DateTime.parse(json['booked_at'] as String).toLocal(),
      bookedBy: json['booked_by'] as String,
    );
  }

  final String trackingNo;
  final String from;
  final String to;
  final String senderName;
  final String senderPhone;
  final String? senderEmail;
  final String receiverName;
  final String receiverPhone;
  final String contents;
  final num value;
  final ParcelSize size;
  final num fee;
  final DateTime bookedAt;
  final String bookedBy;
}