import 'parcel_size.dart';

enum TripStatus { loading, departed, arrived }

// a parcel scanned onto the trip
class TripParcel {
  const TripParcel({
    required this.trackingNo,
    required this.receiverName,
    required this.contents,
    required this.size,
    this.loadedAt,
    this.offAt,
  });

  factory TripParcel.fromJson(Map<String, dynamic> json) {
    return TripParcel(
      trackingNo: json['tracking_no'] as String,
      receiverName: json['receiver_name'] as String,
      contents: json['contents'] as String,
      size: ParcelSize.values.byName(json['size'] as String),
      loadedAt: _time(json['loaded_at']),
      offAt: _time(json['off_at']),
    );
  }

  final String trackingNo;
  final String receiverName;
  final String contents;
  final ParcelSize size;
  final DateTime? loadedAt;

  // when the clerk at the other end scanned it off, null while it is still on board
  final DateTime? offAt;
}

// booked at the office for the trip's route and not on any vehicle yet
class WaitingParcel {
  const WaitingParcel({required this.trackingNo, required this.receiverName});

  factory WaitingParcel.fromJson(Map<String, dynamic> json) {
    return WaitingParcel(
      trackingNo: json['tracking_no'] as String,
      receiverName: json['receiver_name'] as String,
    );
  }

  final String trackingNo;
  final String receiverName;
}

class Trip {
  const Trip({
    required this.id,
    required this.status,
    required this.from,
    required this.to,
    required this.toOffice,
    required this.vehicle,
    this.departedAt,
    this.expectedArrival,
    this.arrivedAt,
    required this.parcels,
    required this.waiting,
  });

  factory Trip.fromJson(Map<String, dynamic> json) {
    final parcels = json['parcels'] as List<dynamic>;
    final waiting = json['waiting'] as List<dynamic>;

    return Trip(
      id: json['trip_id'] as int,
      status: TripStatus.values.byName(json['status'] as String),
      from: json['from'] as String,
      to: json['to'] as String,
      toOffice: json['to_office'] as String,
      vehicle: json['vehicle'] as String,
      departedAt: _time(json['departed_at']),
      expectedArrival: _time(json['expected_arrival']),
      arrivedAt: _time(json['arrived_at']),
      parcels: parcels
          .map((item) => TripParcel.fromJson(item as Map<String, dynamic>))
          .toList(),
      waiting: waiting
          .map((item) => WaitingParcel.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  final int id;
  final TripStatus status;
  final String from;
  final String to;
  final String toOffice;
  final String vehicle;
  final DateTime? departedAt;
  final DateTime? expectedArrival;

  // when the first parcel was scanned off at the other end
  final DateTime? arrivedAt;

  // in the order they were scanned on
  final List<TripParcel> parcels;
  final List<WaitingParcel> waiting;

  List<TripParcel> get stillOnBoard => parcels.where((parcel) => parcel.offAt == null).toList();

  // how long the trip should take, worked out by the API at departure
  int? get minutes {
    final departedAt = this.departedAt;
    final expectedArrival = this.expectedArrival;

    if (departedAt == null || expectedArrival == null) {
      return null;
    }

    return expectedArrival.difference(departedAt).inMinutes;
  }
}

DateTime? _time(Object? value) {
  return value == null ? null : DateTime.parse(value as String).toLocal();
}