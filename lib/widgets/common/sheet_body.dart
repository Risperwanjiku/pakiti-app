import 'package:flutter/material.dart';

import 'package:pakiti_app/theme/app_colors.dart';

// What goes inside a sheet opened with showPakitiSheet: a title, then text and buttons.
// It scrolls if a small phone can't fit it all, and stops short of the top of the screen.
class SheetBody extends StatelessWidget {
  const SheetBody({super.key, this.title, required this.children});

  final String? title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final title = this.title;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.85),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (title != null)
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AppColors.darkText,
                  ),
                ),
              ...children,
            ],
          ),
        ),
      ),
    );
  }
}
