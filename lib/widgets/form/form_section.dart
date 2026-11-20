import 'package:flutter/material.dart';

import 'package:pakiti_app/widgets/common/section_title.dart';

// One part of a form, like Sender or Collection code: its heading, then its fields.
class FormSection extends StatelessWidget {
  const FormSection({super.key, required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionTitle(title: title),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }
}
