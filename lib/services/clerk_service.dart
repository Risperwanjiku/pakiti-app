import '../models/clerk_summary.dart';
import '../models/destination.dart';
import '../models/parcel_filter.dart';
import '../models/parcel_page.dart';
import 'api_client.dart';

class ClerkService {
  ClerkService({ApiClient? api}) : _api = api ?? ApiClient.instance;

  final ApiClient _api;

  Future<ClerkSummary> fetchSummary() async {
    final data = await _api.get('/clerk/summary');
    return ClerkSummary.fromJson(data);
  }

  Future<List<Destination>> fetchDestinations() async {
    final data = await _api.get('/clerk/destinations');
    final destinations = data['destinations'] as List<dynamic>;

    return destinations
        .map((item) => Destination.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<ParcelPage> fetchParcels(ParcelFilter filter, {int offset = 0}) async {
    final data = await _api.get('/clerk/parcels?show=${filter.apiName}&offset=$offset');
    return ParcelPage.fromJson(data);
  }
}