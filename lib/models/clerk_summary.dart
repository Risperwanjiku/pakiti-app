import 'parcel_status.dart';

class RecentParcel {
  const RecentParcel({
    required this.trackingNo,
    required this.status,
    required this.isLate,
    required this.isOutgoing,
    required this.otherName,
    required this.otherTown,
    required this.lastActivity,
  });

  factory RecentParcel.fromJson(Map<String, dynamic> json) {
    return RecentParcel(
      trackingNo: json['tracking_no'] as String,
      status: parcelStatusFromApi(json['status'] as String),
      isLate: json['is_late'] as bool,
      isOutgoing: json['direction'] == 'outgoing',
      otherName: json['other_name'] as String,
      otherTown: json['other_town'] as String,
      lastActivity: DateTime.parse(json['last_activity'] as String),
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

class ClerkSummary {
  const ClerkSummary({
    required this.town,
    required this.bookedToday,
    required this.onTheWay,
    required this.arrived,
    required this.recent,
  });

  factory ClerkSummary.fromJson(Map<String, dynamic> json) {
    final office = json['office'] as Map<String, dynamic>;
    final counts = json['counts'] as Map<String, dynamic>;
    final recent = json['recent'] as List<dynamic>;

    return ClerkSummary(
      town: office['town'] as String,
      bookedToday: counts['booked_today'] as int,
      onTheWay: counts['on_the_way'] as int,
      arrived: counts['arrived'] as int,
      recent: recent
          .map((item) => RecentParcel.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  final String town;
  final int bookedToday;
  final int onTheWay;
  final int arrived;
  final List<RecentParcel> recent;
}