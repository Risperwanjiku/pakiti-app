import 'package:flutter/material.dart';

import 'package:pakiti_app/services/api_client.dart';
import 'package:pakiti_app/theme/app_colors.dart';
import 'package:pakiti_app/widgets/common/white_card.dart';

// shown in place of a list or page that didn't load
class LoadErrorCard extends StatelessWidget {
  const LoadErrorCard({
    super.key,
    required this.error,
    required this.onRetry,
    required this.onLogIn,
    this.canRetry = true,
  });

  final Object? error;
  final VoidCallback onRetry;

  // a 401 means the session ended, so the button goes to login instead
  final VoidCallback onLogIn;

  // false when trying again can't help, like a parcel that isn't there
  final bool canRetry;

  @override
  Widget build(BuildContext context) {
    final error = this.error;
    final sessionEnded = error is ApiException && error.statusCode == 401;
    final message = error is ApiException
        ? error.message
        : 'Something went wrong. Please try again.';

    return WhiteCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: AppColors.darkText),
          ),
          if (canRetry) ...[
            const SizedBox(height: 16),
            FilledButton(
              onPressed: sessionEnded ? onLogIn : onRetry,
              child: Text(sessionEnded ? 'Log in again' : 'Try again'),
            ),
          ],
        ],
      ),
    );
  }
}
