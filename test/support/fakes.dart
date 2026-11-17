import 'dart:convert';

import 'package:flutter/painting.dart';
import 'package:pakiti_app/models/parcel_details.dart';
import 'package:pakiti_app/models/search_result.dart';
import 'package:pakiti_app/services/parcel_service.dart';

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
  Future<ParcelDetails> details(String trackingNo) async {
    if (error != null) {
      throw error!;
    }

    return parcel!;
  }

  @override
  ImageProvider photo(String trackingNo) => pixel;
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