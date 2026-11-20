import 'package:flutter/material.dart';

import 'package:pakiti_app/theme/app_colors.dart';

// the white bar with the screen's title, used on every screen except home
class PageAppBar extends StatelessWidget implements PreferredSizeWidget {
  const PageAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.isTab = false,
  });

  final String title;
  final List<Widget>? actions;

  // replaces the usual back arrow, like Back on the loading screen that also cancels the trip
  final Widget? leading;

  // a tab's own screen has a bigger title and no back arrow
  final bool isTab;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final hasBackButton = leading != null || (!isTab && Navigator.of(context).canPop());

    return AppBar(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      scrolledUnderElevation: 0,
      automaticallyImplyLeading: !isTab,
      leading: leading,
      // the title lines up with the page when there is no back arrow before it
      titleSpacing: hasBackButton ? 4 : 24,
      title: Text(
        title,
        style: TextStyle(
          fontSize: isTab ? 20 : 18,
          fontWeight: FontWeight.w600,
          color: AppColors.darkText,
        ),
      ),
      actions: actions,
    );
  }
}
