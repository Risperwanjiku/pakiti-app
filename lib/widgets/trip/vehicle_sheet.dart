import 'package:flutter/material.dart';

import 'package:pakiti_app/models/trip_choices.dart';
import 'package:pakiti_app/theme/app_colors.dart';
import 'package:pakiti_app/widgets/common/pakiti_sheet.dart';
import 'package:pakiti_app/widgets/common/sheet_option_row.dart';

// The vehicles to pick from. Gives back the vehicle picked, or null when the sheet is closed.
Future<VehicleChoice?> showVehicleSheet(
  BuildContext context, {
  required List<VehicleChoice> vehicles,
  required VehicleChoice? chosen,
}) {
  return showPakitiSheet<VehicleChoice>(
    context,
    builder: (_) => _VehicleSheet(vehicles: vehicles, chosen: chosen),
  );
}

class _VehicleSheet extends StatelessWidget {
  const _VehicleSheet({required this.vehicles, required this.chosen});

  final List<VehicleChoice> vehicles;
  final VehicleChoice? chosen;

  @override
  Widget build(BuildContext context) {
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
                'Choose the vehicle',
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
                  for (final vehicle in vehicles)
                    SheetOptionRow(
                      title: vehicle.regNumber,
                      note: vehicle.busy
                          ? 'On another trip'
                          : (vehicle.fleetNumber == null ? null : 'Fleet number ${vehicle.fleetNumber}'),
                      chosen: vehicle.id == chosen?.id,
                      // a vehicle out on another trip can't be picked
                      onTap: vehicle.busy ? null : () => Navigator.of(context).pop(vehicle),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
