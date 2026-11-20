import 'package:flutter/material.dart';

import 'package:pakiti_app/widgets/common/placeholder_bar.dart';
import 'package:pakiti_app/widgets/common/white_card.dart';

// grey bars in the shape of the town list, shown while the towns load
class TownListPlaceholder extends StatelessWidget {
  const TownListPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return WhiteCard(
      child: Column(
        children: List.generate(6, (_) {
          return SizedBox(
            height: 64,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const PlaceholderBar(width: 36, height: 36),
                  const SizedBox(width: 12),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const PlaceholderBar(width: 96, height: 14),
                      const SizedBox(height: 8),
                      const PlaceholderBar(width: 64, height: 12),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}
