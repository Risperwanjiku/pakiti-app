import 'package:flutter/material.dart';

// the plain white card with rounded corners that most of the app is built from
class WhiteCard extends StatelessWidget {
  const WhiteCard({super.key, required this.child, this.padding = EdgeInsets.zero});

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: child,
    );
  }
}
