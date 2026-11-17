import 'package:url_launcher/url_launcher.dart';

// opens the phone app with the number in it; the clerk still presses call
Future<bool> callNumber(String phone) async {
  try {
    return await launchUrl(Uri(scheme: 'tel', path: phone));
  } on Exception {
    return false;
  }
}