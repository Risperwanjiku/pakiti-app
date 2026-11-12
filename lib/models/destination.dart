import 'parcel_size.dart';

class Destination {
  const Destination({
    required this.routeId,
    required this.town,
    required this.county,
    required this.minutes,
    required this.fees,
  });

  factory Destination.fromJson(Map<String, dynamic> json) {
    final fees = json['fees'] as Map<String, dynamic>;

    return Destination(
      routeId: json['route_id'] as int,
      town: json['town'] as String,
      county: json['county'] as String,
      minutes: json['minutes'] as int,
      fees: {
        for (final size in ParcelSize.values) size: fees[size.name] as num,
      },
    );
  }

  final int routeId;
  final String town;
  final String county;
  final int minutes;
  final Map<ParcelSize, num> fees;
}