import 'parcel_card.dart';

class SearchResult {
  const SearchResult({
    required this.byPhone,
    required this.searchedFor,
    this.name,
    required this.parcels,
  });

  factory SearchResult.fromJson(Map<String, dynamic> json) {
    final byPhone = json['type'] == 'phone';
    final parcels = json['parcels'] as List<dynamic>;

    return SearchResult(
      byPhone: byPhone,
      searchedFor: (byPhone ? json['phone'] : json['tracking_no']) as String,
      name: json['name'] as String?,
      parcels: parcels
          .map((item) => ParcelCard.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  final bool byPhone;

  // the number the API understood, like +254722418305 or PKT-460048
  final String searchedFor;

  // the name last booked with that phone number
  final String? name;

  final List<ParcelCard> parcels;
}