import '../models/clerk_summary.dart';
import 'api_client.dart';

class ClerkService {
  ClerkService({ApiClient? api}) : _api = api ?? ApiClient.instance;

  final ApiClient _api;

  Future<ClerkSummary> fetchSummary() async {
    final data = await _api.get('/clerk/summary');
    return ClerkSummary.fromJson(data);
  }
}