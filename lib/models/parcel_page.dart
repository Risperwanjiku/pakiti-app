import 'package:pakiti_app/models/parcel_card.dart';

// one page of the Parcels list, 30 parcels at most
class ParcelPage {
  const ParcelPage({required this.total, required this.parcels, this.nextOffset});

  factory ParcelPage.fromJson(Map<String, dynamic> json) {
    final parcels = json['parcels'] as List<dynamic>;

    return ParcelPage(
      total: json['total'] as int,
      parcels: parcels.map((item) => ParcelCard.fromJson(item as Map<String, dynamic>)).toList(),
      nextOffset: json['next_offset'] as int?,
    );
  }

  // all the parcels in the filter, not only the ones on this page
  final int total;
  final List<ParcelCard> parcels;

  // where the next page starts, null on the last page
  final int? nextOffset;
}
