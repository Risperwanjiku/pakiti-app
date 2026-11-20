import 'package:pakiti_app/models/parcel_card.dart';

class ClerkSummary {
  const ClerkSummary({
    required this.town,
    required this.booked,
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
      booked: counts['booked'] as int,
      onTheWay: counts['on_the_way'] as int,
      arrived: counts['arrived'] as int,
      recent: recent
          .map((item) => ParcelCard.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  final String town;
  // booked here and still waiting to be loaded, the same parcels as the Booked filter
  final int booked;
  final int onTheWay;
  final int arrived;
  final List<ParcelCard> recent;
}