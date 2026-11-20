import 'dart:convert';

import 'package:flutter/painting.dart';
import 'package:pakiti_app/models/clerk_summary.dart';
import 'package:pakiti_app/models/load_result.dart';
import 'package:pakiti_app/models/parcel_card.dart';
import 'package:pakiti_app/models/parcel_details.dart';
import 'package:pakiti_app/models/parcel_filter.dart';
import 'package:pakiti_app/models/parcel_page.dart';
import 'package:pakiti_app/models/parcel_status.dart';
import 'package:pakiti_app/models/search_result.dart';
import 'package:pakiti_app/models/staff_user.dart';
import 'package:pakiti_app/models/trip.dart';
import 'package:pakiti_app/models/trip_choices.dart';
import 'package:pakiti_app/services/api_client.dart';
import 'package:pakiti_app/services/auth_service.dart';
import 'package:pakiti_app/services/clerk_service.dart';
import 'package:pakiti_app/services/parcel_service.dart';
import 'package:pakiti_app/services/trip_service.dart';

// the details the API gave for a real booking, before it was loaded
const realDetailsReply =
    '{"ok":true,"data":{"parcel":{"tracking_no":"PKT-460048","status":"booked","is_late":false,'
    '"from":"Nyeri","to":"Nairobi","from_office":"Nyeri office","to_office":"Nairobi office",'
    '"travel_minutes":180,"sender":{"name":"Esther Wambui","phone":"+254722418305","email":null},'
    '"receiver":{"name":"Kevin Maina","phone":"+254745902117"},"contents":"Maize flour and beans",'
    '"declared_value":1800,"size":"medium","fee":350,"booked_at":"2026-11-12T23:12:37+03:00",'
    '"booked_by":"Peter Mwangi","expected_arrival":null,"vehicle":null},'
    '"events":[{"type":"booked","at":"2026-11-12T23:12:37+03:00","by":"Peter Mwangi",'
    '"by_role":"clerk","office":"Nyeri office","vehicle":null,"has_photo":true,"note":null}],'
    '"record_checked":true}}';

// what the API gave back for the first parcel scanned onto a real trip
const realLoadReply =
    '{"ok":true,"data":{"result":"loaded","parcel":{"tracking_no":"PKT-282420","status":"loaded",'
    '"from":"Nyeri","to":"Nairobi","vehicle":"KDG 117T"},"trip":{"trip_id":3,"status":"loading",'
    '"from":"Nyeri","to":"Nairobi","to_office":"Nairobi office","vehicle":"KDG 117T","departed_at":null,'
    '"expected_arrival":null,"arrived_at":null,"parcels":[{"tracking_no":"PKT-282420",'
    '"receiver_name":"Paul Kamau","contents":"Shoes","size":"small",'
    '"loaded_at":"2026-11-17T22:11:59+03:00","off_at":null}],"waiting":[]}}}';

// a one pixel PNG, so screens with the parcel photo don't go to the network
final pixel = MemoryImage(
  base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==',
  ),
);

class FakeParcelService extends ParcelService {
  FakeParcelService({this.found, this.parcel, this.error});

  final SearchResult? found;
  final ParcelDetails? parcel;
  final Object? error;
  final searches = <String>[];

  @override
  Future<SearchResult> search(String query) async {
    searches.add(query);

    if (error != null) {
      throw error!;
    }

    return found!;
  }

  @override
  Future<ParcelDetails> fetchDetails(String trackingNo) async {
    if (error != null) {
      throw error!;
    }

    return parcel!;
  }

  @override
  ImageProvider photoOf(String trackingNo) => pixel;
}

const peter = StaffUser(
  id: 1,
  fullName: 'Peter Mwangi',
  phone: '+254712345678',
  role: StaffRole.clerk,
  officeId: 2,
  officeName: 'Nyeri office',
);

// gives out its lists 30 at a time, the same way the API does
class FakeClerkService extends ClerkService {
  FakeClerkService({this.summary, this.lists = const {}, this.error});

  final ClerkSummary? summary;
  final Map<ParcelFilter, List<ParcelCard>> lists;
  final Object? error;

  // each page asked for, like 'arrived 0'
  final asked = <String>[];

  @override
  Future<ClerkSummary> fetchSummary() async {
    if (error != null) {
      throw error!;
    }

    return summary!;
  }

  @override
  Future<ParcelPage> fetchParcels(ParcelFilter filter, {int offset = 0}) async {
    asked.add('${filter.apiName} $offset');

    if (error != null) {
      throw error!;
    }

    final all = lists[filter] ?? const <ParcelCard>[];
    final page = all.skip(offset).take(30).toList();
    final next = offset + page.length;

    return ParcelPage(
      total: all.length,
      parcels: page,
      nextOffset: next < all.length ? next : null,
    );
  }
}

// remembers what it was asked to do instead of calling the API
class FakeAuthService extends AuthService {
  FakeAuthService({this.error});

  final Object? error;

  // each change asked for, like 'old one -> new one'
  final changes = <String>[];
  bool loggedOut = false;

  @override
  Future<void> changePassword(String currentPassword, String newPassword) async {
    changes.add('$currentPassword -> $newPassword');

    if (error != null) {
      throw error!;
    }
  }

  @override
  Future<void> logout() async {
    loggedOut = true;
  }
}

const john = StaffUser(
  id: 2,
  fullName: 'John Otieno',
  phone: '+254723456789',
  role: StaffRole.conductor,
);

// answers the way the API does, from the trips it is given, and remembers what it was asked
class FakeTripService extends TripService {
  FakeTripService({
    this.current,
    this.choices,
    this.started,
    this.scans = const {},
    this.departed,
    this.error,
  });

  Trip? current;
  final TripChoices? choices;
  final Trip? started;

  // what each tracking number gives back when it is scanned
  final Map<String, LoadResult> scans;
  final Trip? departed;
  final Object? error;

  // each call, like 'start 1 1', 'load PKT-461302' or 'end 7 anyway'
  final calls = <String>[];

  @override
  Future<Trip?> fetchCurrentTrip() async {
    calls.add('current');
    _throwIfAsked();
    return current;
  }

  @override
  Future<TripChoices> fetchChoices() async {
    calls.add('choices');
    _throwIfAsked();
    return choices!;
  }

  @override
  Future<Trip> startTrip(int routeId, int vehicleId) async {
    calls.add('start $routeId $vehicleId');
    _throwIfAsked();
    return current = started!;
  }

  @override
  Future<void> cancelTrip(int tripId) async {
    calls.add('cancel $tripId');
    _throwIfAsked();
    current = null;
  }

  @override
  Future<LoadResult> loadParcel(int tripId, String trackingNo) async {
    calls.add('load $trackingNo');
    _throwIfAsked();

    final result = scans[trackingNo];

    if (result == null) {
      throw const ApiException('No parcel with that tracking number.', statusCode: 404);
    }

    current = result.trip;
    return result;
  }

  @override
  Future<Trip> departTrip(int tripId) async {
    calls.add('depart $tripId');
    _throwIfAsked();
    return current = departed!;
  }

  @override
  Future<void> endTrip(int tripId, {bool anyway = false}) async {
    calls.add(anyway ? 'end $tripId anyway' : 'end $tripId');
    _throwIfAsked();
    current = null;
  }

  void _throwIfAsked() {
    if (error != null) {
      throw error!;
    }
  }
}

// what John can choose from, with Nyeri to Nairobi on KDG 117T suggested from his last trip
TripChoices nyeriChoices({int? suggestedRouteId = 1, int? suggestedVehicleId = 1}) {
  return TripChoices.fromJson(_json({
    'routes': [
      {'route_id': 2, 'from': 'Nairobi', 'to': 'Nyeri', 'minutes': 180, 'waiting': 0},
      {'route_id': 1, 'from': 'Nyeri', 'to': 'Nairobi', 'minutes': 175, 'waiting': 2},
      {'route_id': 5, 'from': 'Nyeri', 'to': 'Nakuru', 'minutes': 150, 'waiting': 1},
    ],
    'vehicles': [
      {'vehicle_id': 2, 'reg_number': 'KDA 482M', 'fleet_number': '112', 'busy': true},
      {'vehicle_id': 3, 'reg_number': 'KCX 903P', 'fleet_number': '078', 'busy': false},
      {'vehicle_id': 1, 'reg_number': 'KDG 117T', 'fleet_number': '045', 'busy': false},
    ],
    'suggested': {'route_id': suggestedRouteId, 'vehicle_id': suggestedVehicleId},
  }));
}

// trip 7 from Nyeri to Nairobi on KDG 117T, still loading
Trip loadingTrip({
  List<String> onBoard = const [],
  List<String> waiting = const ['PKT-461388', 'PKT-461390'],
}) {
  return Trip.fromJson(_json({
    ..._trip,
    'status': 'loading',
    'departed_at': null,
    'expected_arrival': null,
    'arrived_at': null,
    'parcels': [
      for (final trackingNo in onBoard)
        _tripParcel(
          trackingNo,
          loadedAt: DateTime.now().subtract(const Duration(seconds: 20)).toIso8601String(),
        ),
    ],
    'waiting': [
      for (final trackingNo in waiting)
        {'tracking_no': trackingNo, 'receiver_name': _receivers[trackingNo] ?? 'Dennis Mwangi'},
    ],
  }));
}

Trip onTheWayTrip() {
  return Trip.fromJson(_json({
    ..._trip,
    'status': 'departed',
    'departed_at': '2026-11-17T14:15:00',
    'expected_arrival': '2026-11-17T17:15:00',
    'arrived_at': null,
    'parcels': [
      _tripParcel('PKT-460048', loadedAt: '2026-11-17T14:01:00'),
      _tripParcel('PKT-461215', loadedAt: '2026-11-17T14:04:00'),
      _tripParcel('PKT-461302', loadedAt: '2026-11-17T14:10:00'),
    ],
    'waiting': <Object>[],
  }));
}

// at Nairobi, with PKT-461215 still on board
Trip inNairobiTrip({bool allOff = false}) {
  return Trip.fromJson(_json({
    ..._trip,
    'status': 'arrived',
    'departed_at': '2026-11-17T14:15:00',
    'expected_arrival': '2026-11-17T17:15:00',
    'arrived_at': '2026-11-17T17:10:00',
    'parcels': [
      _tripParcel('PKT-460048', loadedAt: '2026-11-17T14:01:00', offAt: '2026-11-17T17:12:00'),
      _tripParcel(
        'PKT-461215',
        loadedAt: '2026-11-17T14:04:00',
        offAt: allOff ? '2026-11-17T17:20:00' : null,
      ),
      _tripParcel('PKT-461302', loadedAt: '2026-11-17T14:10:00', offAt: '2026-11-17T17:13:00'),
    ],
    'waiting': <Object>[],
  }));
}

// what the API says after a scan, with the trip as it is afterwards
LoadResult scanResult(
  String result,
  String trackingNo,
  Trip trip, {
  String status = 'booked',
  String from = 'Nyeri',
  String to = 'Nairobi',
  String? vehicle,
}) {
  return LoadResult(
    outcome: loadOutcomeFromApi(result),
    parcel: ScannedParcel.fromJson(_json({
      'tracking_no': trackingNo,
      'status': status,
      'from': from,
      'to': to,
      'vehicle': vehicle,
    })),
    trip: trip,
  );
}

const _trip = {
  'trip_id': 7,
  'from': 'Nyeri',
  'to': 'Nairobi',
  'to_office': 'Nairobi office',
  'vehicle': 'KDG 117T',
};

const _receivers = {
  'PKT-460048': 'Kevin Maina',
  'PKT-461215': 'Faith Njeri',
  'PKT-461302': 'Brian Ochieng',
  'PKT-461388': 'Mercy Wairimu',
  'PKT-461390': 'Joseph Kamau',
};

Map<String, Object?> _tripParcel(String trackingNo, {String? loadedAt, String? offAt}) {
  return {
    'tracking_no': trackingNo,
    'receiver_name': _receivers[trackingNo] ?? 'Dennis Mwangi',
    'contents': trackingNo == 'PKT-461215' ? 'School books' : 'Maize flour and beans',
    'size': trackingNo == 'PKT-461215' ? 'small' : 'medium',
    'loaded_at': loadedAt,
    'off_at': offAt,
  };
}

// a parcel in a list, by default one that came in from Nakuru and is waiting here
ParcelCard listed(
  String trackingNo, {
  ParcelStatus status = ParcelStatus.arrived,
  bool outgoing = false,
  String name = 'Dennis Mwangi',
  String town = 'Nakuru',
  Duration ago = const Duration(minutes: 35),
}) {
  return ParcelCard(
    trackingNo: trackingNo,
    status: status,
    isLate: false,
    isOutgoing: outgoing,
    otherName: name,
    otherTown: town,
    lastActivity: DateTime.now().subtract(ago),
  );
}

// The times below have no offset, so they read the same in whatever
// time zone the tests run in, here or on GitHub.

SearchResult estherParcels() {
  return SearchResult.fromJson(_json({
    'type': 'phone',
    'phone': '+254722418305',
    'name': 'Esther Wambui',
    'parcels': [
      _card('PKT-460048', 'in_transit', 'outgoing', 'Kevin Maina', 'Nairobi'),
      _card('PKT-191127', 'booked', 'outgoing', 'John Kariuki', 'Embu'),
      _card('PKT-388204', 'collected', 'incoming', 'Dennis Mwangi', 'Nakuru'),
    ],
  }));
}

SearchResult nothingFor(String phone) {
  return SearchResult.fromJson(_json({
    'type': 'phone',
    'phone': phone,
    'name': null,
    'parcels': <Object>[],
  }));
}

SearchResult trackingNumberFound() {
  return SearchResult.fromJson(_json({
    'type': 'tracking_no',
    'tracking_no': 'PKT-460048',
    'parcels': [
      _card('PKT-460048', 'in_transit', 'outgoing', 'Kevin Maina', 'Nairobi'),
    ],
  }));
}

ParcelDetails justBooked() {
  return ParcelDetails.fromJson(_json({
    'parcel': {
      ..._booking,
      'status': 'booked',
      'is_late': false,
      'expected_arrival': null,
      'vehicle': null,
    },
    'events': [_booked],
    'record_checked': true,
  }));
}

ParcelDetails onTheWay({bool recordChecked = true}) {
  return ParcelDetails.fromJson(_json({
    'parcel': {
      ..._booking,
      'status': 'in_transit',
      'is_late': false,
      'expected_arrival': '2026-11-12T20:30:00',
      'vehicle': _vehicle,
    },
    'events': [_booked, _loaded, _departed],
    'record_checked': recordChecked,
  }));
}

// the conductor ended the trip at Nairobi with this parcel still on the vehicle
ParcelDetails leftOnBoard() {
  return ParcelDetails.fromJson(_json({
    'parcel': {
      ..._booking,
      'status': 'in_transit',
      'is_late': true,
      'expected_arrival': '2026-11-12T20:30:00',
      'vehicle': _vehicle,
    },
    'events': [
      _booked,
      _loaded,
      _departed,
      _event('not_offloaded', '2026-11-12T20:45:00', 'John Otieno', 'conductor', office: 'Nairobi office', vehicle: 'KDG 117T'),
    ],
    'record_checked': true,
  }));
}

ParcelDetails collectedNextDay() {
  return ParcelDetails.fromJson(_json({
    'parcel': {
      ..._booking,
      'status': 'collected',
      'is_late': false,
      'expected_arrival': '2026-11-12T20:25:00',
      'vehicle': _vehicle,
    },
    'events': [
      _booked,
      _loaded,
      _departed,
      _event('arrived', '2026-11-12T20:20:00', 'Samuel Kiprop', 'clerk', office: 'Nairobi office', vehicle: 'KDG 117T'),
      _event('collected', '2026-11-13T09:05:00', 'Samuel Kiprop', 'clerk', office: 'Nairobi office'),
    ],
    'record_checked': true,
  }));
}

const _booking = {
  'tracking_no': 'PKT-460048',
  'from': 'Nyeri',
  'to': 'Nairobi',
  'from_office': 'Nyeri office',
  'to_office': 'Nairobi office',
  'travel_minutes': 180,
  'sender': {'name': 'Esther Wambui', 'phone': '+254722418305', 'email': null},
  'receiver': {'name': 'Kevin Maina', 'phone': '+254745902117'},
  'contents': 'Maize flour and beans',
  'declared_value': 1800,
  'size': 'medium',
  'fee': 350,
  'booked_at': '2026-11-12T16:41:00',
  'booked_by': 'Peter Mwangi',
};

const _vehicle = {
  'reg_number': 'KDG 117T',
  'conductor': 'John Otieno',
  'conductor_phone': '+254723456789',
};

final _booked = _event('booked', '2026-11-12T16:41:00', 'Peter Mwangi', 'clerk', office: 'Nyeri office', photo: true);
final _loaded = _event('loaded', '2026-11-12T17:10:00', 'John Otieno', 'conductor', vehicle: 'KDG 117T');
final _departed = _event('departed', '2026-11-12T17:25:00', 'John Otieno', 'conductor', vehicle: 'KDG 117T');

Map<String, Object?> _event(
  String type,
  String at,
  String by,
  String role, {
  String? office,
  String? vehicle,
  bool photo = false,
}) {
  return {
    'type': type,
    'at': at,
    'by': by,
    'by_role': role,
    'office': office,
    'vehicle': vehicle,
    'has_photo': photo,
    'note': null,
  };
}

Map<String, Object?> _card(String trackingNo, String status, String direction, String name, String town) {
  return {
    'tracking_no': trackingNo,
    'status': status,
    'is_late': false,
    'direction': direction,
    'other_name': name,
    'other_town': town,
    'last_activity': '2026-11-12T17:25:00',
  };
}

// through real JSON and back, so the types are the ones the API gives
Map<String, dynamic> _json(Map<String, Object?> value) {
  return jsonDecode(jsonEncode(value)) as Map<String, dynamic>;
}