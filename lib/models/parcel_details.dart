import 'booked_parcel.dart';
import 'parcel_status.dart';

// the hand-offs in the order they happen
enum CustodyStep { booked, loaded, departed, arrived, collected }

class ParcelEvent {
  const ParcelEvent({
    required this.step,
    required this.at,
    required this.by,
    required this.byRole,
    this.office,
    this.vehicle,
    required this.hasPhoto,
    this.note,
  });

  factory ParcelEvent.fromJson(Map<String, dynamic> json) {
    return ParcelEvent(
      step: CustodyStep.values.byName(json['type'] as String),
      at: DateTime.parse(json['at'] as String).toLocal(),
      by: json['by'] as String,
      byRole: json['by_role'] as String,
      office: json['office'] as String?,
      vehicle: json['vehicle'] as String?,
      hasPhoto: json['has_photo'] as bool,
      note: json['note'] as String?,
    );
  }

  final CustodyStep step;
  final DateTime at;
  final String by;
  final String byRole;
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
  });

  factory ParcelDetails.fromJson(Map<String, dynamic> json) {
    final parcel = json['parcel'] as Map<String, dynamic>;
    final expected = parcel['expected_arrival'] as String?;
    final vehicle = parcel['vehicle'] as Map<String, dynamic>?;
    final events = json['events'] as List<dynamic>;

    return ParcelDetails(
      booking: BookedParcel.fromJson(parcel),
      status: parcelStatusFromApi(parcel['status'] as String),
      isLate: parcel['is_late'] as bool,
      fromOffice: parcel['from_office'] as String,
      toOffice: parcel['to_office'] as String,
      travelMinutes: parcel['travel_minutes'] as int,
      expectedArrival: expected == null ? null : DateTime.parse(expected).toLocal(),
      vehicle: vehicle == null ? null : Vehicle.fromJson(vehicle),
      events: events
          .map((item) => ParcelEvent.fromJson(item as Map<String, dynamic>))
          .toList(),
      recordChecked: json['record_checked'] as bool,
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

  bool get hasBookingPhoto => events.isNotEmpty && events.first.hasPhoto;

  // the hand-offs still to come after the last one recorded
  List<CustodyStep> get stepsLeft {
    final last = events.isEmpty ? CustodyStep.booked : events.last.step;

    return CustodyStep.values.where((step) => step.index > last.index).toList();
  }

  DateTime? timeOf(CustodyStep step) {
    for (final event in events.reversed) {
      if (event.step == step) {
        return event.at;
      }
    }

    return null;
  }
}