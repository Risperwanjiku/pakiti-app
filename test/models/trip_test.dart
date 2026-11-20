import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:pakiti_app/models/load_result.dart';
import 'package:pakiti_app/models/parcel_size.dart';
import 'package:pakiti_app/models/parcel_status.dart';
import 'package:pakiti_app/models/trip.dart';

import '../support/fakes.dart';

LoadResult readReply() {
  final body = jsonDecode(realLoadReply) as Map<String, dynamic>;

  return LoadResult.fromJson(body['data'] as Map<String, dynamic>);
}

void main() {
  test('reads a scan and the trip as it is afterwards', () {
    final result = readReply();
    final trip = result.trip;
    final parcel = trip.parcels.single;

    expect(result.outcome, LoadOutcome.loaded);
    expect(result.parcel.trackingNo, 'PKT-282420');
    expect(result.parcel.status, ParcelStatus.loaded);
    expect(result.parcel.vehicle, 'KDG 117T');
    expect(trip.id, 3);
    expect(trip.status, TripStatus.loading);
    expect(trip.toOffice, 'Nairobi office');
    expect(trip.departedAt, isNull);
    expect(trip.expectedMinutes, isNull);
    expect(parcel.receiverName, 'Paul Kamau');
    expect(parcel.size, ParcelSize.small);
    expect(parcel.loadedAt!.toUtc(), DateTime.utc(2026, 11, 17, 19, 11, 59));
    expect(parcel.offAt, isNull);
    expect(trip.waiting, isEmpty);
  });

  test('knows how long a trip on the way should take', () {
    final trip = onTheWayTrip();

    expect(trip.status, TripStatus.departed);
    expect(trip.expectedMinutes, 180);
    expect(trip.stillOnBoard, hasLength(3));
  });

  test('knows which parcels are still on board at the other end', () {
    expect(inNairobiTrip().stillOnBoard.map((parcel) => parcel.trackingNo), ['PKT-461215']);
    expect(inNairobiTrip(allOff: true).stillOnBoard, isEmpty);
  });

  test('reads the choices and the route and vehicle to start with', () {
    final choices = nyeriChoices();

    expect(choices.routes, hasLength(3));
    expect(choices.suggestedRoute!.name, 'Nyeri to Nairobi');
    expect(choices.suggestedRoute!.waiting, 2);
    expect(choices.suggestedVehicle!.regNumber, 'KDG 117T');
    expect(choices.vehicles.where((vehicle) => vehicle.busy).single.regNumber, 'KDA 482M');
  });

  test('suggests nothing before the first trip', () {
    final choices = nyeriChoices(suggestedRouteId: null, suggestedVehicleId: null);

    expect(choices.suggestedRoute, isNull);
    expect(choices.suggestedVehicle, isNull);
  });

  test('reads every answer the API can give to a scan', () {
    expect(loadOutcomeFromApi('loaded'), LoadOutcome.loaded);
    expect(loadOutcomeFromApi('already_on_board'), LoadOutcome.alreadyOnBoard);
    expect(loadOutcomeFromApi('wrong_route'), LoadOutcome.wrongRoute);
    expect(loadOutcomeFromApi('other_vehicle'), LoadOutcome.otherVehicle);
    expect(loadOutcomeFromApi('already_left'), LoadOutcome.alreadyLeft);
    expect(() => loadOutcomeFromApi('lost'), throwsFormatException);
  });
}