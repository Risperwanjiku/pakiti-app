import 'package:flutter/material.dart';

import '../models/parcel_filter.dart';
import '../models/staff_user.dart';
import '../services/clerk_service.dart';
import '../theme/app_colors.dart';
import 'clerk_home.dart';
import 'parcels.dart';

// The bottom bar and the tab it shows. A tab is built again each time it opens,
// so the numbers on home and the Parcels list are never out of date.
class ClerkTabs extends StatefulWidget {
  const ClerkTabs({super.key, required this.user, this.service});

  final StaffUser user;

  // tests pass in a fake one
  final ClerkService? service;

  @override
  State<ClerkTabs> createState() => _ClerkTabsState();
}

class _ClerkTabsState extends State<ClerkTabs> {
  int _tab = 0;
  ParcelFilter _filter = ParcelFilter.all;

  void _showParcels(ParcelFilter filter) {
    setState(() {
      _filter = filter;
      _tab = 1;
    });
  }

  void _openTab(int tab) {
    // Scan and Profile come in the next steps
    if (tab > 1) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('This part is coming next.')),
        );
      return;
    }

    setState(() => _tab = tab);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _tab == 0
          ? ClerkHomeScreen(
              user: widget.user,
              onShowParcels: _showParcels,
              service: widget.service,
            )
          : ParcelsScreen(
              user: widget.user,
              filter: _filter,
              onFilterChanged: (filter) => _filter = filter,
              service: widget.service,
            ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        indicatorColor: AppColors.navTint,
        onDestinationSelected: _openTab,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2),
            label: 'Parcels',
          ),
          NavigationDestination(
            icon: Icon(Icons.qr_code_scanner),
            label: 'Scan',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}