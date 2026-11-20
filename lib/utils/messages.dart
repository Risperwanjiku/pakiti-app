import 'package:flutter/material.dart';

import 'package:pakiti_app/screens/account/login_screen.dart';
import 'package:pakiti_app/services/api_client.dart';

// a new message replaces the one showing, so quick taps don't stack them up
void showMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

// a 401 means the session has ended, so the message offers Log in again
void showApiError(BuildContext context, ApiException error) {
  final sessionEnded = error.statusCode == 401;

  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(error.message),
        action: sessionEnded
            ? SnackBarAction(label: 'Log in again', onPressed: () => goToLogin(context))
            : null,
      ),
    );
}

// For a catch that has to reset a busy button whatever went wrong. Anything that isn't
// from the API, like a reply the app couldn't read, gets a plain message.
void showError(BuildContext context, Object error) {
  if (error is ApiException) {
    showApiError(context, error);
  } else {
    showMessage(context, 'Something went wrong. Please try again.');
  }
}

// clears every screen first, so Back can't return to the old session
void goToLogin(BuildContext context) {
  Navigator.of(
    context,
  ).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
}
