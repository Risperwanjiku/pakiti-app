import 'package:image_picker/image_picker.dart';

// The camera for a parcel photo, at booking and at handover. Gives back where the photo
// was saved, or null if the clerk closed the camera. Throws a PlatformException when
// the camera can't open, usually because Pakiti isn't allowed to use it.
Future<String?> takeParcelPhoto() async {
  // small enough to upload quickly on a slow connection, still clear enough for a claim
  final photo = await ImagePicker().pickImage(
    source: ImageSource.camera,
    maxWidth: 1600,
    imageQuality: 80,
  );

  return photo?.path;
}

const cameraFailedMessage = "The camera didn't open. Check that Pakiti is allowed to use it.";
