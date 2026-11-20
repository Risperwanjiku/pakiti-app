import 'package:flutter/material.dart';

class ParcelPhotoScreen extends StatelessWidget {
  const ParcelPhotoScreen({super.key, required this.photo, required this.trackingNo});

  final ImageProvider photo;
  final String trackingNo;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.black,
        titleSpacing: 4,
        title: Text(trackingNo, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
      ),
      // pinch to look closer at the condition of the parcel
      body: InteractiveViewer(
        maxScale: 5,
        child: Center(
          child: Image(
            image: photo,
            fit: BoxFit.contain,
            loadingBuilder: (context, child, progress) {
              return progress == null
                  ? child
                  : const CircularProgressIndicator(color: Colors.white);
            },
            errorBuilder: (context, error, stackTrace) {
              return const Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  "The photo didn't load. Go back and try again.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.white),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
