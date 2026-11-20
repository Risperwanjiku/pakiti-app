import 'package:flutter/material.dart';

import 'package:pakiti_app/models/parcel_filter.dart';
import 'package:pakiti_app/widgets/common/empty_list_card.dart';

// what Parcels says when the chosen filter has nothing in it
class NoParcelsCard extends StatelessWidget {
  const NoParcelsCard({
    super.key,
    required this.filter,
    required this.officeName,
    required this.onBook,
  });

  final ParcelFilter filter;
  final String officeName;
  final VoidCallback onBook;

  @override
  Widget build(BuildContext context) {
    final (title, message) = switch (filter) {
      ParcelFilter.all => (
          'No parcels yet',
          'Parcels sent from or to $officeName will show here.',
        ),
      ParcelFilter.booked => (
          'Nothing waiting to be loaded',
          'Parcels booked at $officeName show here until they are loaded onto a vehicle.',
        ),
      ParcelFilter.onTheWay => (
          'Nothing on the way',
          'Parcels coming to $officeName show here once they leave.',
        ),
      ParcelFilter.arrived => (
          'Nothing waiting for collection',
          'Parcels that arrive at $officeName show here until they are collected.',
        ),
    };

    return EmptyListCard(
      title: title,
      message: message,
      extra: [
        // nothing waiting usually means the next customer is at the counter
        if (filter == ParcelFilter.booked) ...[
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onBook,
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, 48),
              padding: const EdgeInsets.symmetric(horizontal: 24),
            ),
            icon: const Icon(Icons.add_circle_outline, size: 20),
            label: const Text('Book a parcel'),
          ),
        ],
      ],
    );
  }
}
