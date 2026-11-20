import 'package:flutter/material.dart';

import 'package:pakiti_app/models/arrival.dart';
import 'package:pakiti_app/utils/messages.dart';
import 'package:pakiti_app/widgets/common/load_error_card.dart';
import 'package:pakiti_app/widgets/common/see_all_heading.dart';
import 'package:pakiti_app/widgets/scan/arrival_row.dart';
import 'package:pakiti_app/widgets/trip/empty_trip_list.dart';
import 'package:pakiti_app/widgets/trip/trip_parcel_row.dart';

// The Marked as arrived today list under the camera on the Scan tab.
class ArrivalsToday extends StatelessWidget {
  const ArrivalsToday({
    super.key,
    required this.arrivals,
    required this.onRetry,
    required this.onSeeAll,
  });

  final Future<List<ArrivedParcel>> arrivals;
  final VoidCallback onRetry;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ArrivedParcel>>(
      future: arrivals,
      builder: (context, snapshot) {
        return ListView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          children: [
            SeeAllHeading(title: 'Marked as arrived today', onSeeAll: onSeeAll),
            const SizedBox(height: 4),
            ..._buildList(context, snapshot),
          ],
        );
      },
    );
  }

  List<Widget> _buildList(BuildContext context, AsyncSnapshot<List<ArrivedParcel>> snapshot) {
    final arrivals = snapshot.data;

    if (snapshot.hasError && snapshot.connectionState != ConnectionState.waiting) {
      return [
        LoadErrorCard(
          error: snapshot.error,
          onRetry: onRetry,
          onLogIn: () => goToLogin(context),
        ),
      ];
    }

    // still loading the first time
    if (arrivals == null) {
      return const [];
    }

    if (arrivals.isEmpty) {
      return const [EmptyTripList(text: 'Nothing marked as arrived yet today.')];
    }

    return [
      TripParcelCard(
        rows: [for (final parcel in arrivals) ArrivalRow(parcel: parcel)],
      ),
    ];
  }
}
