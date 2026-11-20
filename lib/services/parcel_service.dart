import 'dart:math';

import 'package:flutter/painting.dart';

import 'package:pakiti_app/models/booked_parcel.dart';
import 'package:pakiti_app/models/handed_over.dart';
import 'package:pakiti_app/models/new_parcel.dart';
import 'package:pakiti_app/models/parcel_details.dart';
import 'package:pakiti_app/models/search_result.dart';
import 'package:pakiti_app/services/api_client.dart';

class ParcelService {
  ParcelService({ApiClient? api}) : _api = api ?? ApiClient.instance;

  final ApiClient _api;

  // sending the same requestId again returns the first booking instead of making a second one
  Future<BookedParcel> book(NewParcel parcel, {required String requestId}) async {
    final data = await _api.postForm(
      '/parcels',
      fields: {
        'request_id': requestId,
        'route_id': '${parcel.destination.routeId}',
        'size': parcel.size.name,
        'contents': parcel.contents,
        'declared_value': '${parcel.value}',
        'sender_name': parcel.senderName,
        'sender_phone': parcel.senderPhone,
        if (parcel.senderEmail != null) 'sender_email': parcel.senderEmail!,
        'receiver_name': parcel.receiverName,
        'receiver_phone': parcel.receiverPhone,
      },
      files: {'photo': parcel.photoPath},
    );

    return BookedParcel.fromJson(data['parcel'] as Map<String, dynamic>);
  }

  // a tracking number or a phone number, typed any way
  Future<SearchResult> search(String query) async {
    final data = await _api.get('/parcels?q=${Uri.encodeQueryComponent(query)}');
    return SearchResult.fromJson(data);
  }

  Future<ParcelDetails> fetchDetails(String trackingNo) async {
    final data = await _api.get('/parcels/${Uri.encodeComponent(trackingNo)}');
    return ParcelDetails.fromJson(data);
  }

  // the photo taken at booking
  ImageProvider photoOf(String trackingNo) {
    return NetworkImage(
      _api.url('/parcels/${Uri.encodeComponent(trackingNo)}/photo').toString(),
      headers: _api.authHeader,
    );
  }

  // the photo taken when the receiver collected it
  ImageProvider handoverPhotoOf(String trackingNo) {
    return NetworkImage(
      _api.url('/parcels/${Uri.encodeComponent(trackingNo)}/handover-photo').toString(),
      headers: _api.authHeader,
    );
  }

  // A wrong code comes back as an ApiException with a 'code' field error, and the
  // fifth wrong one as a 423, which means the parcel is now locked.
  Future<HandedOver> handOver(
    String trackingNo, {
    required String code,
    required String photoPath,
  }) async {
    final data = await _api.postForm(
      '/parcels/${Uri.encodeComponent(trackingNo)}/collection',
      fields: {'code': code},
      files: {'photo': photoPath},
    );

    return HandedOver.fromJson(data);
  }

  // the old code stops working as soon as the new one is made
  Future<void> sendNewCode(String trackingNo) async {
    await _api.post('/parcels/${Uri.encodeComponent(trackingNo)}/code');
  }

  // a random version 4 UUID
  static String newRequestId() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));

    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;

    final hex = bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();

    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
  }
}
