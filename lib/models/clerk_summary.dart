import 'parcel_card.dart';

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
          .map((item) => ParcelCard.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  final String town;
  final int bookedToday;
  final int onTheWay;
  final int arrived;
  final List<ParcelCard> recent;
}