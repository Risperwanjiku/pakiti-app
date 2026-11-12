import 'package:flutter/material.dart';

import '../models/clerk_summary.dart';
import '../models/parcel_status.dart';
import '../models/staff_user.dart';
import '../services/api_client.dart';
import '../services/clerk_service.dart';
import '../theme/app_colors.dart';
import '../utils/time_ago.dart';
import 'choose_town.dart';
import 'login.dart';

class ClerkHomeScreen extends StatefulWidget {
  const ClerkHomeScreen({super.key, required this.user});

  final StaffUser user;

  @override
  State<ClerkHomeScreen> createState() => _ClerkHomeScreenState();
}

class _ClerkHomeScreenState extends State<ClerkHomeScreen> {
  final _clerkService = ClerkService();

  late Future<ClerkSummary> _summary;

  @override
  void initState() {
    super.initState();
    _summary = _clerkService.fetchSummary();
  }

  Future<void> _refresh() async {
    setState(() => _summary = _clerkService.fetchSummary());
    await _summary.then((_) {}, onError: (_) {});
  }

  void _retry() {
    setState(() => _summary = _clerkService.fetchSummary());
  }

  void _goToLogin() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  Future<void> _openBooking() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ChooseTownScreen()),
    );

    // the counts and recent parcels change after a booking
    if (mounted) {
      _refresh();
    }
  }

  void _comingSoon() {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('This part is coming next.')),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.page,
      appBar: _buildAppBar(),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<ClerkSummary>(
          future: _summary,
          builder: (context, snapshot) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              children: [
                Text(
                  'Habari, ${widget.user.firstName}',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: AppColors.darkText,
                  ),
                ),
                const SizedBox(height: 16),
                _buildBookButton(),
                const SizedBox(height: 12),
                _buildSearch(),
                const SizedBox(height: 24),
                ..._buildSummary(snapshot),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: _buildNavigationBar(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      scrolledUnderElevation: 0,
      titleSpacing: 24,
      title: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.navy,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              'P',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'Pakiti',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.darkText,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          tooltip: 'Notifications',
          onPressed: _comingSoon,
          icon: const Icon(
            Icons.notifications_none_rounded,
            color: AppColors.darkText,
          ),
        ),
        const SizedBox(width: 12),
      ],
    );
  }

  Widget _buildBookButton() {
    return FilledButton(
      onPressed: _openBooking,
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(60),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      child: const Row(
        children: [
          Icon(Icons.add_circle_outline),
          SizedBox(width: 12),
          Expanded(child: Text('Book a parcel')),
          Icon(Icons.arrow_forward, size: 20),
        ],
      ),
    );
  }

  Widget _buildSearch() {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide.none,
    );

    return TextField(
      textInputAction: TextInputAction.search,
      onSubmitted: (_) => _comingSoon(),
      decoration: InputDecoration(
        hintText: 'PKT-20416 or 0712 345 678',
        hintStyle: const TextStyle(color: AppColors.grey),
        prefixIcon: const Icon(Icons.search, color: AppColors.grey),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
        border: border,
        enabledBorder: border,
        focusedBorder: border.copyWith(
          borderSide: const BorderSide(color: AppColors.link, width: 2),
        ),
      ),
    );
  }

  List<Widget> _buildSummary(AsyncSnapshot<ClerkSummary> snapshot) {
    final loading = snapshot.connectionState == ConnectionState.waiting;

    if (snapshot.hasError && !loading) {
      return [_buildError(snapshot.error)];
    }

    final summary = snapshot.data;

    return [
      _buildSectionTitle(summary == null ? 'Today' : 'Today at ${summary.town}'),
      const SizedBox(height: 8),
      IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: _buildStat(
                summary?.bookedToday,
                'Booked',
                onTap: summary == null ? null : _comingSoon,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildStat(
                summary?.onTheWay,
                'On the way',
                onTap: summary == null ? null : _comingSoon,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildStat(
                summary?.arrived,
                'Arrived',
                highlight: true,
                onTap: summary == null ? null : _comingSoon,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 14),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildSectionTitle('Recent parcels'),
          TextButton(
            onPressed: _comingSoon,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.link,
              minimumSize: const Size(0, 44),
              padding: const EdgeInsets.symmetric(horizontal: 4),
            ),
            child: const Text('See all'),
          ),
        ],
      ),
      const SizedBox(height: 4),
      if (summary == null)
        ...List.generate(3, (_) => _buildParcelPlaceholder())
      else if (summary.recent.isEmpty)
        _buildEmpty()
      else
        ...summary.recent.map(_buildParcelCard),
    ];
  }

  Widget _buildSectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.darkText,
      ),
    );
  }

  Widget _buildStat(
    int? value,
    String label, {
    bool highlight = false,
    VoidCallback? onTap,
  }) {
    final color = highlight ? AppColors.statusArrived : AppColors.navy;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 34,
                child: value == null
                    ? Align(
                        alignment: Alignment.centerLeft,
                        child: _buildBar(32, 22),
                      )
                    : Text(
                        '$value',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w600,
                          color: color,
                        ),
                      ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: highlight ? FontWeight.w500 : FontWeight.w400,
                  color: highlight ? AppColors.statusArrived : AppColors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildParcelCard(RecentParcel parcel) {
    final (label, textColor, background) = _statusStyle(parcel);
    final place = parcel.isOutgoing
        ? 'To ${parcel.otherName}, ${parcel.otherTown}'
        : 'From ${parcel.otherName}, ${parcel.otherTown}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: _comingSoon,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        parcel.trackingNo,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.darkText,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: background,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: textColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        place,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.grey,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      timeAgo(parcel.lastActivity),
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.grey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  (String, Color, Color) _statusStyle(RecentParcel parcel) {
    if (parcel.isLate) {
      return ('Late', AppColors.statusLate, AppColors.statusLateBg);
    }

    return switch (parcel.status) {
      ParcelStatus.booked => (
          'Booked',
          AppColors.statusBooked,
          AppColors.statusBookedBg,
        ),
      ParcelStatus.loaded => (
          'Loaded',
          AppColors.statusBooked,
          AppColors.statusBookedBg,
        ),
      ParcelStatus.inTransit => (
          'On the way',
          AppColors.statusOnTheWay,
          AppColors.statusOnTheWayBg,
        ),
      ParcelStatus.arrived => (
          'Arrived',
          AppColors.statusArrived,
          AppColors.statusArrivedBg,
        ),
      ParcelStatus.collected => (
          'Collected',
          AppColors.statusCollected,
          AppColors.statusCollectedBg,
        ),
    };
  }

  Widget _buildParcelPlaceholder() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        height: 76,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [_buildBar(96, 16), _buildBar(180, 14)],
        ),
      ),
    );
  }

  Widget _buildBar(double width, double height) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.page,
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }

  Widget _buildEmpty() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Column(
        children: [
          Icon(Icons.inventory_2_outlined, size: 32, color: AppColors.border),
          SizedBox(height: 12),
          Text(
            'No parcels yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.darkText,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Parcels you book or receive at this office will show here.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: AppColors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildError(Object? error) {
    final sessionEnded = error is ApiException && error.statusCode == 401;
    final message = error is ApiException
        ? error.message
        : 'Something went wrong. Please try again.';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: AppColors.darkText),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: sessionEnded ? _goToLogin : _retry,
            child: Text(sessionEnded ? 'Log in again' : 'Try again'),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationBar() {
    return NavigationBar(
      selectedIndex: 0,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      indicatorColor: AppColors.navTint,
      onDestinationSelected: (index) {
        if (index != 0) {
          _comingSoon();
        }
      },
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: 'Home',
        ),
        NavigationDestination(
          icon: Icon(Icons.inventory_2_outlined),
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
    );
  }
}