import 'package:flutter/material.dart';

// what a button shows while it waits for the server, like Logging in…
class BusyLabel extends StatelessWidget {
  const BusyLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: Colors.white,
          ),
        ),
        const SizedBox(width: 12),
        Text(text),
      ],
    );
  }
}
