import 'package:pakiti_app/models/booked_parcel.dart';
import 'package:pakiti_app/models/parcel_status.dart';

// The hand-offs in the order they happen. notOffloaded is when the conductor
// ended the trip with the parcel still on the vehicle.
enum CustodyStep { booked, loaded, departed, notOffloaded, arrived, collected }

CustodyStep custodyStepFromApi(String value) {
  return switch (value) {
    'booked' => CustodyStep.booked,
    'loaded' => CustodyStep.loaded,
    'departed' => CustodyStep.departed,
    'not_offloaded' => CustodyStep.notOffloaded,
    'arrived' => CustodyStep.arrived,
    'collected' => CustodyStep.collected,
    _ => throw FormatException('Unknown hand-off: $value'),
  };
}

class ParcelEvent {
  const ParcelEvent({
    required this.step,
    required this.time,
    required this.staffName,
    required this.staffRole,
    this.office,
    this.vehicle,
    required this.hasPhoto,
    this.note,
  });

  factory ParcelEvent.fromJson(Map<String, dynamic> json) {
    return ParcelEvent(
      step: custodyStepFromApi(json['type'] as String),
      time: DateTime.parse(json['at'] as String).toLocal(),
      staffName: json['by'] as String,
      staffRole: json['by_role'] as String,
      office: json['office'] as String?,
      vehicle: json['vehicle'] as String?,
      hasPhoto: json['has_photo'] as bool,
      note: json['note'] as String?,
    );
  }

  final CustodyStep step;
  final DateTime time;
  final String staffName;
  final String staffRole;
  final String? office;
  final String? vehicle;
  final bool hasPhoto;
  final String? note;
}

class Vehicle {
  const Vehicle({
    required this.regNumber,
    required this.conductor,
    required this.conductorPhone,
  });

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      regNumber: json['reg_number'] as String,
      conductor: json['conductor'] as String,
      conductorPhone: json['conductor_phone'] as String,
    );
  }

  final String regNumber;
  final String conductor;
  final String conductorPhone;
}

// Only sent for a parcel waiting at the clerk's own office, which is when it can be handed over.
class HandOverState {
  const HandOverState({required this.codeSent, required this.triesLeft});

  factory HandOverState.fromJson(Map<String, dynamic> json) {
    return HandOverState(
      codeSent: json['code_sent'] as bool,
      triesLeft: json['tries_left'] as int,
    );
  }

  // false for a parcel that arrived before codes were sent
  final bool codeSent;
  final int triesLeft;

  // the code was wrong five times, so only the admin can let it go now
  bool get isLocked => triesLeft == 0;
}

class ParcelDetails {
  const ParcelDetails({
    required this.booking,
    required this.status,
    required this.isLate,
    required this.fromOffice,
    required this.toOffice,
    required this.travelMinutes,
    this.expectedArrival,
    this.vehicle,
    required this.events,
    required this.recordChecked,
    this.handOver,
  });

  factory ParcelDetails.fromJson(Map<String, dynamic> json) {
    final parcel = json['parcel'] as Map<String, dynamic>;
    final expectedArrival = parcel['expected_arrival'] as String?;
    final vehicle = parcel['vehicle'] as Map<String, dynamic>?;
    final events = json['events'] as List<dynamic>;
    final handOver = json['hand_over'] as Map<String, dynamic>?;

    return ParcelDetails(
      booking: BookedParcel.fromJson(parcel),
      status: parcelStatusFromApi(parcel['status'] as String),
      isLate: parcel['is_late'] as bool,
      fromOffice: parcel['from_office'] as String,
      toOffice: parcel['to_office'] as String,
      travelMinutes: parcel['travel_minutes'] as int,
      expectedArrival: expectedArrival == null ? null : DateTime.parse(expectedArrival).toLocal(),
      vehicle: vehicle == null ? null : Vehicle.fromJson(vehicle),
      events: events
          .map((item) => ParcelEvent.fromJson(item as Map<String, dynamic>))
          .toList(),
      recordChecked: json['record_checked'] as bool,
      handOver: handOver == null ? null : HandOverState.fromJson(handOver),
    );
  }

  // what was given at booking, the same details the label shows
  final BookedParcel booking;
  final ParcelStatus status;
  final bool isLate;
  final String fromOffice;
  final String toOffice;
  final int travelMinutes;
  final DateTime? expectedArrival;
  final Vehicle? vehicle;
  final List<ParcelEvent> events;

  // false when the API found something in the custody record changed after it was saved
  final bool recordChecked;

  // null unless the parcel is waiting here for the receiver
  final HandOverState? handOver;

  bool get hasBookingPhoto => events.isNotEmpty && events.first.hasPhoto;

  bool get hasHandoverPhoto =>
      events.any((event) => event.step == CustodyStep.collected && event.hasPhoto);

  // the hand-offs still to come after the last one recorded
  List<CustodyStep> get stepsLeft {
    final lastStep = events.isEmpty ? CustodyStep.booked : events.last.step;

    return CustodyStep.values
        .where((step) => step.index > lastStep.index && step != CustodyStep.notOffloaded)
        .toList();
  }

  DateTime? timeOf(CustodyStep step) {
    for (final event in events.reversed) {
      if (event.step == step) {
        return event.time;
      }
    }

    return null;
  }
}