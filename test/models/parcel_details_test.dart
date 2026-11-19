import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:pakiti_app/models/parcel_details.dart';
import 'package:pakiti_app/models/parcel_size.dart';
import 'package:pakiti_app/models/parcel_status.dart';

import '../support/fakes.dart';

ParcelDetails readReply() {
  final body = jsonDecode(realDetailsReply) as Map<String, dynamic>;

  return ParcelDetails.fromJson(body['data'] as Map<String, dynamic>);
}

void main() {
  test('reads a parcel that is still at the office', () {
    final details = readReply();

    expect(details.booking.trackingNo, 'PKT-460048');
    expect(details.booking.receiverName, 'Kevin Maina');
    expect(details.booking.size, ParcelSize.medium);
    expect(details.status, ParcelStatus.booked);
    expect(details.fromOffice, 'Nyeri office');
    expect(details.toOffice, 'Nairobi office');
    expect(details.travelMinutes, 180);
    expect(details.expectedArrival, isNull);
    expect(details.vehicle, isNull);
    expect(details.hasBookingPhoto, isTrue);
    expect(details.recordChecked, isTrue);
  });

  test('reads each hand-off, keeping its exact time', () {
    final event = readReply().events.single;

    expect(event.step, CustodyStep.booked);
    expect(event.by, 'Peter Mwangi');
    expect(event.byRole, 'clerk');
    expect(event.office, 'Nyeri office');
    expect(event.at.toUtc(), DateTime.utc(2026, 11, 12, 20, 12, 37));
  });

  test('knows which hand-offs are still to come', () {
    expect(readReply().stepsLeft, [
      CustodyStep.loaded,
      CustodyStep.departed,
      CustodyStep.arrived,
      CustodyStep.collected,
    ]);
    expect(onTheWay().stepsLeft, [CustodyStep.arrived, CustodyStep.collected]);
    expect(collectedNextDay().stepsLeft, isEmpty);
  });

  test('a parcel left on the vehicle can still arrive', () {
    final details = leftOnBoard();

    expect(details.events.last.step, CustodyStep.notOffloaded);
    expect(details.stepsLeft, [CustodyStep.arrived, CustodyStep.collected]);
    expect(onTheWay().stepsLeft, isNot(contains(CustodyStep.notOffloaded)));
  });

  test('reads the vehicle and when the parcel should arrive', () {
    final details = onTheWay();

    expect(details.vehicle!.regNumber, 'KDG 117T');
    expect(details.vehicle!.conductor, 'John Otieno');
    expect(details.vehicle!.conductorPhone, '+254723456789');
    expect(details.expectedArrival, DateTime(2026, 11, 12, 20, 30));
    expect(details.timeOf(CustodyStep.departed), DateTime(2026, 11, 12, 17, 25));
    expect(details.timeOf(CustodyStep.arrived), isNull);
  });
}