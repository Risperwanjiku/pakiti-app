import 'package:flutter/material.dart';

import 'package:pakiti_app/models/parcel_card.dart';
import 'package:pakiti_app/models/parcel_filter.dart';
import 'package:pakiti_app/models/staff_user.dart';
import 'package:pakiti_app/screens/clerk/choose_town_screen.dart';
import 'package:pakiti_app/screens/clerk/parcel_details_screen.dart';
import 'package:pakiti_app/screens/clerk/search_screen.dart';
import 'package:pakiti_app/services/clerk_service.dart';
import 'package:pakiti_app/theme/app_colors.dart';
import 'package:pakiti_app/utils/format.dart';
import 'package:pakiti_app/utils/messages.dart';
import 'package:pakiti_app/widgets/common/load_error_card.dart';
import 'package:pakiti_app/widgets/common/page_app_bar.dart';
import 'package:pakiti_app/widgets/parcel/no_parcels_card.dart';
import 'package:pakiti_app/widgets/parcel/parcel_filter_bar.dart';
import 'package:pakiti_app/widgets/parcel/parcel_tile.dart';

class ParcelsScreen extends StatefulWidget {
  const ParcelsScreen({
    super.key,
    required this.user,
    this.filter = ParcelFilter.all,
    this.onFilterChanged,
    this.service,
  });

  final StaffUser user;

  // the filter it opens on, for example Arrived after tapping that number on home
  final ParcelFilter filter;

  // lets the tabs open Parcels on the same filter next time
  final ValueChanged<ParcelFilter>? onFilterChanged;

  // tests pass in a fake one
  final ClerkService? service;

  @override
  State<ParcelsScreen> createState() => _ParcelsScreenState();
}

class _ParcelsScreenState extends State<ParcelsScreen> {
  late final ClerkService _service = widget.service ?? ClerkService();
  final _scrollController = ScrollController();

  late ParcelFilter _filter = widget.filter;
  final List<ParcelCard> _parcels = [];
  int _totalCount = 0;
  int? _nextOffset;

  bool _loading = true;
  Object? _error;
  bool _loadingMore = false;
  bool _loadMoreFailed = false;

  // counts the loads, so an answer for a filter that is no longer chosen gets dropped
  int _loadCount = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadFirstPage();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  String get _officeName => widget.user.officeName ?? 'your office';

  Future<void> _loadFirstPage() async {
    final thisLoad = ++_loadCount;

    try {
      final page = await _service.fetchParcels(_filter);

      if (!mounted || thisLoad != _loadCount) {
        return;
      }

      setState(() {
        _parcels
          ..clear()
          ..addAll(page.parcels);
        _totalCount = page.total;
        _nextOffset = page.nextOffset;
        _loading = false;
        _error = null;
      });
    } catch (error) {
      if (!mounted || thisLoad != _loadCount) {
        return;
      }

      setState(() {
        _loading = false;
        _error = error;
      });
    }
  }

  // starts again from the first page, with placeholders while it loads
  void _reload() {
    setState(() {
      _loading = true;
      _error = null;
      _nextOffset = null;
      _loadingMore = false;
      _loadMoreFailed = false;
    });
    _loadFirstPage();
  }

  Future<void> _refresh() {
    setState(() {
      _loadingMore = false;
      _loadMoreFailed = false;
    });
    return _loadFirstPage();
  }

  void _chooseFilter(ParcelFilter filter) {
    if (filter == _filter) {
      return;
    }

    _filter = filter;
    widget.onFilterChanged?.call(filter);
    _reload();

    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }
  }

  void _onScroll() {
    // the next page starts loading a little before the end, so scrolling doesn't stop
    if (_scrollController.position.extentAfter < 400) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    final offset = _nextOffset;

    if (offset == null || _loading || _loadingMore || _loadMoreFailed) {
      return;
    }

    final thisLoad = _loadCount;
    setState(() => _loadingMore = true);

    try {
      final page = await _service.fetchParcels(_filter, offset: offset);

      if (!mounted || thisLoad != _loadCount) {
        return;
      }

      setState(() {
        _parcels.addAll(page.parcels);
        _totalCount = page.total;
        _nextOffset = page.nextOffset;
        _loadingMore = false;
      });
    } catch (_) {
      if (!mounted || thisLoad != _loadCount) {
        return;
      }

      setState(() {
        _loadingMore = false;
        _loadMoreFailed = true;
      });
    }
  }

  void _retryLoadMore() {
    setState(() => _loadMoreFailed = false);
    _loadMore();
  }

  void _openSearch() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SearchScreen()),
    );
  }

  // a parcel handed over on its page leaves the Arrived list, so the list loads again
  void _openParcel(String trackingNo) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ParcelDetailsScreen(trackingNo: trackingNo, onChanged: _refresh),
      ),
    );
  }

  Future<void> _openBooking() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ChooseTownScreen()),
    );

    // a new booking waits under Booked until it is loaded
    if (mounted) {
      _reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.page,
      appBar: PageAppBar(
        title: 'Parcels',
        isTab: true,
        actions: [
          IconButton(
            tooltip: 'Search parcels',
            onPressed: _openSearch,
            icon: const Icon(Icons.search, color: AppColors.darkText),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          // outside the list, so the filters stay in reach however far down it goes
          ParcelFilterBar(chosen: _filter, onChoose: _chooseFilter),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                children: _buildList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildList() {
    final error = _error;

    if (_loading) {
      return [for (var i = 0; i < 3; i++) const ParcelTilePlaceholder()];
    }

    if (error != null) {
      return [LoadErrorCard(error: error, onRetry: _reload, onLogIn: () => goToLogin(context))];
    }

    if (_parcels.isEmpty) {
      return [
        NoParcelsCard(filter: _filter, officeName: _officeName, onBook: _openBooking),
      ];
    }

    return [
      Text(
        parcelCount(_totalCount),
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.darkText,
        ),
      ),
      const SizedBox(height: 2),
      Text(
        _listCaption(),
        style: const TextStyle(fontSize: 13, color: AppColors.grey),
      ),
      const SizedBox(height: 12),
      for (final parcel in _parcels)
        ParcelTile(
          parcel: parcel,
          onTap: () => _openParcel(parcel.trackingNo),
        ),
      if (_loadingMore) const ParcelTilePlaceholder(),
      if (_loadMoreFailed) _buildLoadMoreFailed(),
    ];
  }

  // the API sends All newest first, and the other three oldest first, like a queue
  String _listCaption() {
    return switch (_filter) {
      ParcelFilter.all => 'Sent from or to $_officeName, newest first',
      ParcelFilter.booked => 'Waiting to be loaded at $_officeName, oldest first',
      ParcelFilter.onTheWay => 'On the way to $_officeName, oldest first',
      ParcelFilter.arrived => 'Waiting for collection at $_officeName, oldest first',
    };
  }

  Widget _buildLoadMoreFailed() {
    return Row(
      children: [
        const Expanded(
          child: Text(
            "Couldn't load more parcels.",
            style: TextStyle(fontSize: 14, color: AppColors.grey),
          ),
        ),
        TextButton(
          onPressed: _retryLoadMore,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.link,
            minimumSize: const Size(0, 44),
          ),
          child: const Text('Try again'),
        ),
      ],
    );
  }
}
