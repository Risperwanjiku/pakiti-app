import 'package:flutter/material.dart';

import 'package:pakiti_app/models/clerk_summary.dart';
import 'package:pakiti_app/models/parcel_filter.dart';
import 'package:pakiti_app/models/staff_user.dart';
import 'package:pakiti_app/screens/clerk/choose_town_screen.dart';
import 'package:pakiti_app/screens/clerk/parcel_details_screen.dart';
import 'package:pakiti_app/screens/clerk/search_screen.dart';
import 'package:pakiti_app/services/clerk_service.dart';
import 'package:pakiti_app/theme/app_colors.dart';
import 'package:pakiti_app/utils/messages.dart';
import 'package:pakiti_app/widgets/common/empty_list_card.dart';
import 'package:pakiti_app/widgets/common/load_error_card.dart';
import 'package:pakiti_app/widgets/common/pakiti_app_bar.dart';
import 'package:pakiti_app/widgets/common/see_all_heading.dart';
import 'package:pakiti_app/widgets/parcel/parcel_tile.dart';
import 'package:pakiti_app/widgets/parcel/today_counts.dart';

class ClerkHomeScreen extends StatefulWidget {
  const ClerkHomeScreen({
    super.key,
    required this.user,
    required this.onShowParcels,
    this.service,
  });

  final StaffUser user;

  // the numbers and See all open the Parcels tab on the matching filter
  final ValueChanged<ParcelFilter> onShowParcels;

  // tests pass in a fake one
  final ClerkService? service;

  @override
  State<ClerkHomeScreen> createState() => _ClerkHomeScreenState();
}

class _ClerkHomeScreenState extends State<ClerkHomeScreen> {
  late final ClerkService _clerkService = widget.service ?? ClerkService();
  final _searchController = TextEditingController();

  late Future<ClerkSummary> _summary;

  @override
  void initState() {
    super.initState();
    _summary = _clerkService.fetchSummary();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    // braces, because setState throws in debug mode when its callback hands back a Future
    setState(() {
      _summary = _clerkService.fetchSummary();
    });
    await _summary.then((_) {}, onError: (_) {});
  }

  void _retry() {
    setState(() {
      _summary = _clerkService.fetchSummary();
    });
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

  void _openSearch(String text) {
    final query = text.trim();

    if (query.isEmpty) {
      return;
    }

    _searchController.clear();
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => SearchScreen(query: query)),
    );
  }

  void _openParcel(String trackingNo) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ParcelDetailsScreen(trackingNo: trackingNo)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.page,
      appBar: PakitiAppBar(
        actions: [
          IconButton(
            tooltip: 'Notifications',
            onPressed: () => showMessage(context, 'This part is coming next.'),
            icon: const Icon(
              Icons.notifications_none_rounded,
              color: AppColors.darkText,
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
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
      controller: _searchController,
      textInputAction: TextInputAction.search,
      onSubmitted: _openSearch,
      decoration: InputDecoration(
        hintText: 'PKT-460048 or 0712 345 678',
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
      return [
        LoadErrorCard(error: snapshot.error, onRetry: _retry, onLogIn: () => goToLogin(context)),
      ];
    }

    final summary = snapshot.data;

    return [
      _buildSectionTitle(summary == null ? 'Today' : 'Today at ${summary.town}'),
      const SizedBox(height: 8),
      TodayCounts(summary: summary, onShowParcels: widget.onShowParcels),
      const SizedBox(height: 14),
      SeeAllHeading(
        title: 'Recent parcels',
        onSeeAll: () => widget.onShowParcels(ParcelFilter.all),
      ),
      const SizedBox(height: 4),
      if (summary == null)
        for (var i = 0; i < 3; i++) const ParcelTilePlaceholder()
      else if (summary.recent.isEmpty)
        const EmptyListCard(
          title: 'No parcels yet',
          message: 'Parcels you book or receive at this office will show here.',
          iconColor: AppColors.border,
        )
      else
        for (final parcel in summary.recent)
          ParcelTile(
            parcel: parcel,
            onTap: () => _openParcel(parcel.trackingNo),
          ),
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
}
