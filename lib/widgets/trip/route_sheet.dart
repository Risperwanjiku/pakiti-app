import 'package:flutter/material.dart';

import 'package:pakiti_app/models/trip_choices.dart';
import 'package:pakiti_app/theme/app_colors.dart';
import 'package:pakiti_app/widgets/common/pakiti_sheet.dart';
import 'package:pakiti_app/widgets/common/sheet_option_row.dart';

// Every route, under the town it leaves from. Gives back the route picked,
// or null when the sheet is closed.
Future<RouteChoice?> showRouteSheet(
  BuildContext context, {
  required List<RouteChoice> routes,
  required RouteChoice? chosen,
}) {
  return showPakitiSheet<RouteChoice>(
    context,
    builder: (_) => _RouteSheet(routes: routes, chosen: chosen),
  );
}

class _RouteSheet extends StatelessWidget {
  const _RouteSheet({required this.routes, required this.chosen});

  final List<RouteChoice> routes;
  final RouteChoice? chosen;

  @override
  Widget build(BuildContext context) {
    // routes with parcels waiting go first, so the one that matters isn't far down the list
    final ordered = [
      ...routes.where((route) => route.waiting > 0),
      ...routes.where((route) => route.waiting == 0),
    ];
    final towns = {for (final route in ordered) route.from};

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.75),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 0, 24, 8),
              child: Text(
                'Choose the route',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: AppColors.darkText,
                ),
              ),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.only(bottom: 16),
                children: [
                  for (final town in towns) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 12, 24, 4),
                      child: Text(
                        'From $town',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.grey,
                        ),
                      ),
                    ),
                    for (final route in ordered.where((route) => route.from == town))
                      SheetOptionRow(
                        title: 'To ${route.to}',
                        note: _waitingNote(route.waiting),
                        noteColor: route.waiting > 0 ? AppColors.link : AppColors.grey,
                        chosen: route.id == chosen?.id,
                        onTap: () => Navigator.of(context).pop(route),
                      ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _waitingNote(int waiting) {
    return switch (waiting) {
      0 => 'Nothing waiting',
      1 => '1 parcel waiting',
      _ => '$waiting parcels waiting',
    };
  }
}
