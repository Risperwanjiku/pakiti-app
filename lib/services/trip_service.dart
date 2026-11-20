import 'package:pakiti_app/models/load_result.dart';
import 'package:pakiti_app/models/trip.dart';
import 'package:pakiti_app/models/trip_choices.dart';
import 'package:pakiti_app/services/api_client.dart';

class TripService {
  TripService({ApiClient? api}) : _api = api ?? ApiClient.instance;

  final ApiClient _api;

  // null when the conductor has no trip open
  Future<Trip?> fetchCurrentTrip() async {
    final data = await _api.get('/conductor/trip');
    final trip = data['trip'] as Map<String, dynamic>?;

    return trip == null ? null : Trip.fromJson(trip);
  }

  Future<TripChoices> fetchChoices() async {
    final data = await _api.get('/conductor/choices');
    return TripChoices.fromJson(data);
  }

  Future<Trip> startTrip(int routeId, int vehicleId) async {
    final data = await _api.post('/trips', {
      'route_id': routeId,
      'vehicle_id': vehicleId,
    });

    return Trip.fromJson(data['trip'] as Map<String, dynamic>);
  }

  // only works while nothing is on the trip
  Future<void> cancelTrip(int tripId) async {
    await _api.post('/trips/$tripId/cancel');
  }

  Future<LoadResult> loadParcel(int tripId, String trackingNo) async {
    final data = await _api.post('/trips/$tripId/parcels', {'tracking_no': trackingNo});
    return LoadResult.fromJson(data);
  }

  Future<Trip> departTrip(int tripId) async {
    final data = await _api.post('/trips/$tripId/depart');
    return Trip.fromJson(data['trip'] as Map<String, dynamic>);
  }

  // anyway is only sent once the conductor has seen what is still on board
  Future<void> endTrip(int tripId, {bool anyway = false}) async {
    await _api.post('/trips/$tripId/end', {'anyway': anyway});
  }
}