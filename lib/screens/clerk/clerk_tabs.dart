import 'package:flutter/material.dart';

import 'package:pakiti_app/models/parcel_filter.dart';
import 'package:pakiti_app/models/staff_user.dart';
import 'package:pakiti_app/screens/account/profile_screen.dart';
import 'package:pakiti_app/screens/clerk/clerk_home_screen.dart';
import 'package:pakiti_app/screens/clerk/parcels_screen.dart';
import 'package:pakiti_app/screens/clerk/scan_screen.dart';
import 'package:pakiti_app/services/clerk_service.dart';
import 'package:pakiti_app/theme/app_colors.dart';

// The bottom bar and the tab it shows. A tab is built again each time it opens,
// so the numbers on home and the Parcels list are never out of date.
class ClerkTabs extends StatefulWidget {
  const ClerkTabs({super.key, required this.user, this.service, this.camera = true});

  final StaffUser user;

  // tests pass in a fake one
  final ClerkService? service;

  // false in tests, where there is no camera
  final bool camera;

  @override
  State<ClerkTabs> createState() => _ClerkTabsState();
}

class _ClerkTabsState extends State<ClerkTabs> {
  int _tabIndex = 0;
  ParcelFilter _parcelsFilter = ParcelFilter.all;

  void _showParcels(ParcelFilter filter) {
    setState(() {
      _parcelsFilter = filter;
      _tabIndex = 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: switch (_tabIndex) {
        0 => ClerkHomeScreen(
            user: widget.user,
            onShowParcels: _showParcels,
            service: widget.service,
          ),
        1 => ParcelsScreen(
            user: widget.user,
            filter: _parcelsFilter,
            onFilterChanged: (filter) => _parcelsFilter = filter,
            service: widget.service,
          ),
        2 => ScanScreen(
            onSeeAll: () => _showParcels(ParcelFilter.arrived),
            service: widget.service,
            camera: widget.camera,
          ),
        _ => ProfileScreen(user: widget.user),
      },
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tabIndex,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        indicatorColor: AppColors.navTint,
        onDestinationSelected: (tab) => setState(() => _tabIndex = tab),
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
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
