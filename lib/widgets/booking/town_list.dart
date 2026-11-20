import 'package:flutter/material.dart';

import 'package:pakiti_app/models/destination.dart';
import 'package:pakiti_app/theme/app_colors.dart';

// the white card of towns on Where is it going?, one tappable row per town
class TownList extends StatelessWidget {
  const TownList({super.key, required this.towns, required this.onChoose});

  final List<Destination> towns;
  final void Function(Destination destination) onChoose;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < towns.length; i++) ...[
            if (i > 0)
              const Divider(height: 1, thickness: 1, color: AppColors.page),
            _buildRow(towns[i]),
          ],
        ],
      ),
    );
  }

  Widget _buildRow(Destination destination) {
    return MergeSemantics(
      child: Semantics(
        button: true,
        child: InkWell(
          onTap: () => onChoose(destination),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 64),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.statusBookedBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.location_on_outlined,
                      size: 20,
                      color: AppColors.statusBooked,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          destination.town,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: AppColors.darkText,
                          ),
                        ),
                        Text(
                          '${destination.county} County',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right,
                    size: 20,
                    color: AppColors.border,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
