import '../models/clerk_summary.dart';
import '../models/destination.dart';
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
}