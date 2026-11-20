import 'package:pakiti_app/models/parcel_status.dart';
import 'package:pakiti_app/models/trip.dart';

// what happened to a parcel scanned while loading
enum LoadOutcome { loaded, alreadyOnBoard, wrongRoute, otherVehicle, alreadyLeft }

LoadOutcome loadOutcomeFromApi(String value) {
  return switch (value) {
    'loaded' => LoadOutcome.loaded,
    'already_on_board' => LoadOutcome.alreadyOnBoard,
    'wrong_route' => LoadOutcome.wrongRoute,
    'other_vehicle' => LoadOutcome.otherVehicle,
    'already_left' => LoadOutcome.alreadyLeft,
    _ => throw FormatException('Unknown scan result: $value'),
  };
}

// only what the conductor needs to know about the scanned parcel
class ScannedParcel {
  const ScannedParcel({
    required this.trackingNo,
    required this.status,
    required this.from,
    required this.to,
    this.vehicle,
  });

  factory ScannedParcel.fromJson(Map<String, dynamic> json) {
    return ScannedParcel(
      trackingNo: json['tracking_no'] as String,
      status: parcelStatusFromApi(json['status'] as String),
      from: json['from'] as String,
      to: json['to'] as String,
      vehicle: json['vehicle'] as String?,
    );
  }

  final String trackingNo;
  final ParcelStatus status;
  final String from;
  final String to;

  // the vehicle it is on, or the one it left on
  final String? vehicle;
}

class LoadResult {
  const LoadResult({
    required this.outcome,
    required this.parcel,
    required this.trip,
  });

  factory LoadResult.fromJson(Map<String, dynamic> json) {
    return LoadResult(
      outcome: loadOutcomeFromApi(json['result'] as String),
      parcel: ScannedParcel.fromJson(json['parcel'] as Map<String, dynamic>),
      trip: Trip.fromJson(json['trip'] as Map<String, dynamic>),
    );
  }

  final LoadOutcome outcome;
  final ScannedParcel parcel;

  // the trip as it is now, with the lists up to date
  final Trip trip;
}