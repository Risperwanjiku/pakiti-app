import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:pakiti_app/models/arrival.dart';
import 'package:pakiti_app/models/parcel_size.dart';
import 'package:pakiti_app/models/parcel_status.dart';

// the way GET /parcels/{trackingNo}/arrival answers for a parcel coming in
const comingInReply = '{"verdict":"arriving","here":"Nairobi","parcel":{"tracking_no":"PKT-460048",'
    '"status":"in_transit","from":"Nyeri","to":"Nairobi","contents":"Maize flour and beans",'
    '"size":"medium","receiver":{"name":"Kevin Maina","phone":"+254745902117"},"vehicle":"KDG 117T",'
    '"departed_at":"2026-11-19T14:15:00+03:00","arrived_at":null,"collected_at":null}}';

Map<String, dynamic> read(String json) => jsonDecode(json) as Map<String, dynamic>;

void main() {
  test('reads a parcel coming in to this office', () {
    final check = ArrivalCheck.fromJson(read(comingInReply));
    final parcel = check.parcel!;

    expect(check.verdict, ArrivalVerdict.arriving);
    expect(check.here, 'Nairobi');
    expect(check.trackingNo, 'PKT-460048');
    expect(parcel.status, ParcelStatus.inTransit);
    expect(parcel.size, ParcelSize.medium);
    expect(parcel.receiverName, 'Kevin Maina');
    expect(parcel.vehicle, 'KDG 117T');
    expect(parcel.departedAt!.toUtc(), DateTime.utc(2026, 11, 19, 11, 15));
  });

  test('a parcel for another office only says where it is going', () {
    final check = ArrivalCheck.fromJson(read(
      '{"verdict":"not_here","here":"Nairobi","parcel":{"tracking_no":"PKT-461144","to":"Nakuru"}}',
    ));

    expect(check.verdict, ArrivalVerdict.notHere);
    expect(check.to, 'Nakuru');
    expect(check.parcel, isNull);
  });

  test('marking a parcel gives back the list with it at the top', () {
    final result = ArrivalResult.fromJson(read(
      '{"parcel":{"tracking_no":"PKT-460048","receiver_name":"Kevin Maina"},"arrivals":['
      '{"tracking_no":"PKT-460048","from":"Nyeri","vehicle":"KDG 117T","at":"2026-11-19T17:12:00+03:00"},'
      '{"tracking_no":"PKT-458871","from":"Nakuru","vehicle":null,"at":"2026-11-19T11:40:00+03:00"}]}',
    ));

    expect(result.receiverName, 'Kevin Maina');
    expect(result.arrivals.map((parcel) => parcel.trackingNo), ['PKT-460048', 'PKT-458871']);
    expect(result.arrivals.last.vehicle, isNull);
    expect(result.arrivals.first.at.toUtc(), DateTime.utc(2026, 11, 19, 14, 12));
  });

  test('a check the app does not know about is an error, not a guess', () {
    expect(() => arrivalVerdictFromApi('lost'), throwsFormatException);
  });
}
