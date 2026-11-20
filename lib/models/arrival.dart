import 'package:pakiti_app/models/parcel_size.dart';
import 'package:pakiti_app/models/parcel_status.dart';

// what a label scanned at this office means, before anything is saved
enum ArrivalVerdict { arriving, arrived, collected, notLoaded, notDeparted, outgoing, notHere }

ArrivalVerdict arrivalVerdictFromApi(String value) {
  return switch (value) {
    'arriving' => ArrivalVerdict.arriving,
    'arrived' => ArrivalVerdict.arrived,
    'collected' => ArrivalVerdict.collected,
    'not_loaded' => ArrivalVerdict.notLoaded,
    'not_departed' => ArrivalVerdict.notDeparted,
    'outgoing' => ArrivalVerdict.outgoing,
    'not_here' => ArrivalVerdict.notHere,
    _ => throw FormatException('Unknown arrival check: $value'),
  };
}

// a parcel scanned at the office it was booked to
class IncomingParcel {
  const IncomingParcel({
    required this.trackingNo,
    required this.status,
    required this.from,
    required this.to,
    required this.contents,
    required this.size,
    required this.receiverName,
    required this.receiverPhone,
    this.vehicle,
    this.departedAt,
  });

  factory IncomingParcel.fromJson(Map<String, dynamic> json) {
    final receiver = json['receiver'] as Map<String, dynamic>;
    final departedAt = json['departed_at'] as String?;

    return IncomingParcel(
      trackingNo: json['tracking_no'] as String,
      status: parcelStatusFromApi(json['status'] as String),
      from: json['from'] as String,
      to: json['to'] as String,
      contents: json['contents'] as String,
      size: ParcelSize.values.byName(json['size'] as String),
      receiverName: receiver['name'] as String,
      receiverPhone: receiver['phone'] as String,
      vehicle: json['vehicle'] as String?,
      departedAt: departedAt == null ? null : DateTime.parse(departedAt).toLocal(),
    );
  }

  final String trackingNo;
  final ParcelStatus status;
  final String from;
  final String to;
  final String contents;
  final ParcelSize size;
  final String receiverName;
  final String receiverPhone;

  // null when it was never put on a vehicle
  final String? vehicle;
  final DateTime? departedAt;
}

class ArrivalCheck {
  const ArrivalCheck({
    required this.verdict,
    required this.here,
    required this.trackingNo,
    required this.to,
    this.parcel,
  });

  factory ArrivalCheck.fromJson(Map<String, dynamic> json) {
    final verdict = arrivalVerdictFromApi(json['verdict'] as String);
    final parcel = json['parcel'] as Map<String, dynamic>;

    return ArrivalCheck(
      verdict: verdict,
      here: json['here'] as String,
      trackingNo: parcel['tracking_no'] as String,
      to: parcel['to'] as String,
      // a parcel for another office only comes with where it is going
      parcel: verdict == ArrivalVerdict.notHere ? null : IncomingParcel.fromJson(parcel),
    );
  }

  final ArrivalVerdict verdict;

  // the town of the clerk's own office
  final String here;
  final String trackingNo;
  final String to;
  final IncomingParcel? parcel;
}

// a parcel in the Marked as arrived today list
class ArrivedParcel {
  const ArrivedParcel({
    required this.trackingNo,
    required this.from,
    required this.at,
    this.vehicle,
  });

  factory ArrivedParcel.fromJson(Map<String, dynamic> json) {
    return ArrivedParcel(
      trackingNo: json['tracking_no'] as String,
      from: json['from'] as String,
      vehicle: json['vehicle'] as String?,
      at: DateTime.parse(json['at'] as String).toLocal(),
    );
  }

  final String trackingNo;
  final String from;
  final String? vehicle;
  final DateTime at;
}

List<ArrivedParcel> arrivedParcelsFromJson(Object? value) {
  return (value as List<dynamic>)
      .map((item) => ArrivedParcel.fromJson(item as Map<String, dynamic>))
      .toList();
}

// what marking a parcel as arrived gives back
class ArrivalResult {
  const ArrivalResult({
    required this.trackingNo,
    required this.receiverName,
    required this.arrivals,
  });

  factory ArrivalResult.fromJson(Map<String, dynamic> json) {
    final parcel = json['parcel'] as Map<String, dynamic>;

    return ArrivalResult(
      trackingNo: parcel['tracking_no'] as String,
      receiverName: parcel['receiver_name'] as String,
      arrivals: arrivedParcelsFromJson(json['arrivals']),
    );
  }

  final String trackingNo;
  final String receiverName;

  // the Marked as arrived today list again, with this parcel at the top
  final List<ArrivedParcel> arrivals;
}
