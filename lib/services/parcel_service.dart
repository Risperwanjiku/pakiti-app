import 'dart:math';

import '../models/booked_parcel.dart';
import '../models/new_parcel.dart';
import 'api_client.dart';

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