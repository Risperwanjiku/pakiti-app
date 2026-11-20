import 'package:pakiti_app/models/parcel_status.dart';

// a parcel in a list, seen from the clerk's office: going out of it or coming in to it
class ParcelCard {
  const ParcelCard({
    required this.trackingNo,
    required this.status,
    required this.isLate,
    required this.isOutgoing,
    required this.otherName,
    required this.otherTown,
    required this.lastActivity,
  });

  factory ParcelCard.fromJson(Map<String, dynamic> json) {
    return ParcelCard(
      trackingNo: json['tracking_no'] as String,
      status: parcelStatusFromApi(json['status'] as String),
      isLate: json['is_late'] as bool,
      isOutgoing: json['direction'] == 'outgoing',
      otherName: json['other_name'] as String,
      otherTown: json['other_town'] as String,
      lastActivity: DateTime.parse(json['last_activity'] as String).toLocal(),
    );
  }

  final String trackingNo;
  final ParcelStatus status;
  final bool isLate;
  final bool isOutgoing;
  final String otherName;
  final String otherTown;
  final DateTime lastActivity;
}