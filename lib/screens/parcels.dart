import 'package:flutter/material.dart';

import '../models/parcel_card.dart';
import '../models/parcel_filter.dart';
import '../models/staff_user.dart';
import '../services/api_client.dart';
import '../services/clerk_service.dart';
import '../theme/app_colors.dart';
import '../widgets/parcel_tile.dart';
import 'choose_town.dart';
import 'login.dart';
import 'parcel_details.dart';
import 'search.dart';

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
  final _scroll = ScrollController();

  late ParcelFilter _filter = widget.filter;
  final List<ParcelCard> _parcels = [];
  int _total = 0;
  int? _nextOffset;

  bool _loading = true;
  Object? _error;
  bool _loadingMore = false;
  bool _moreFailed = false;

  // counts the loads, so an answer for a filter that is no longer chosen gets dropped
  int _loads = 0;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    _load();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  String get _office => widget.user.officeName ?? 'your office';

  Future<void> _load() async {
    final load = ++_loads;

    try {
      final page = await _service.fetchParcels(_filter);

      if (!mounted || load != _loads) {
        return;
      }

      setState(() {
        _parcels
          ..clear()
          ..addAll(page.parcels);
        _total = page.total;
        _nextOffset = page.nextOffset;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted || load != _loads) {
        return;
      }

      setState(() {
        _loading = false;
        _error = e;
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
      _moreFailed = false;
    });
    _load();
  }

  Future<void> _refresh() {
    setState(() {
      _loadingMore = false;
      _moreFailed = false;
    });
    return _load();
  }

  void _choose(ParcelFilter filter) {
    if (filter == _filter) {
      return;
    }

    _filter = filter;
    widget.onFilterChanged?.call(filter);
    _reload();

    if (_scroll.hasClients) {
      _scroll.jumpTo(0);
    }
  }

  void _onScroll() {
    // the next page starts loading a little before the end, so scrolling doesn't stop
    if (_scroll.position.extentAfter < 400) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    final offset = _nextOffset;

    if (offset == null || _loading || _loadingMore || _moreFailed) {
      return;
    }

    final load = _loads;
    setState(() => _loadingMore = true);

    try {
      final page = await _service.fetchParcels(_filter, offset: offset);

      if (!mounted || load != _loads) {
        return;
      }

      setState(() {
        _parcels.addAll(page.parcels);
        _total = page.total;
        _nextOffset = page.nextOffset;
        _loadingMore = false;
      });
    } catch (_) {
      if (!mounted || load != _loads) {
        return;
      }

      setState(() {
        _loadingMore = false;
        _moreFailed = true;
      });
    }
  }

  void _retryMore() {
    setState(() => _moreFailed = false);
    _loadMore();
  }

  void _goToLogin() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  void _openSearch() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SearchScreen()),
    );
  }

  void _openParcel(String trackingNo) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ParcelDetailsScreen(trackingNo: trackingNo)),
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
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        scrolledUnderElevation: 0,
        titleSpacing: 24,
        title: const Text(
          'Parcels',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.darkText,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Search parcels',
            onPressed: _openSearch,
            icon: const Icon(Icons.search, color: AppColors.darkText),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          controller: _scroll,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          children: [
            _buildFilters(),
            const SizedBox(height: 20),
            ..._buildList(),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters() {
    // all four fit on a 360 dp phone; this only scrolls with very large text
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        spacing: 8,
        children: [
          for (final filter in ParcelFilter.values) _buildFilter(filter),
        ],
      ),
    );
  }

  Widget _buildFilter(ParcelFilter filter) {
    final chosen = filter == _filter;

    return Semantics(
      button: true,
      selected: chosen,
      child: Material(
        color: chosen ? AppColors.navy : Colors.white,
        shape: const StadiumBorder(),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: () => _choose(filter),
          child: Container(
            height: 40,
            constraints: const BoxConstraints(minWidth: 44),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            alignment: Alignment.center,
            child: Text(
              filter.label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: chosen ? Colors.white : AppColors.darkText,
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildList() {
    final error = _error;

    if (_loading) {
      return [for (var i = 0; i < 3; i++) const ParcelTilePlaceholder()];
    }

    if (error != null) {
      return [_buildError(error)];
    }

    if (_parcels.isEmpty) {
      return [_buildEmpty()];
    }

    return [
      Text(
        _total == 1 ? '1 parcel' : '$_total parcels',
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.darkText,
        ),
      ),
      const SizedBox(height: 2),
      Text(
        _caption(),
        style: const TextStyle(fontSize: 13, color: AppColors.grey),
      ),
      const SizedBox(height: 12),
      for (final parcel in _parcels)
        ParcelTile(
          parcel: parcel,
          onTap: () => _openParcel(parcel.trackingNo),
        ),
      if (_loadingMore) const ParcelTilePlaceholder(),
      if (_moreFailed) _buildMoreFailed(),
    ];
  }

  String _caption() {
    return switch (_filter) {
      ParcelFilter.all => 'Sent from or to $_office, newest first',
      ParcelFilter.booked => 'Waiting to be loaded at $_office',
      ParcelFilter.onTheWay => 'On the way to $_office',
      ParcelFilter.arrived => 'Waiting for collection at $_office',
    };
  }

  Widget _buildEmpty() {
    final (title, body) = switch (_filter) {
      ParcelFilter.all => (
          'No parcels yet',
          'Parcels sent from or to $_office will show here.',
        ),
      ParcelFilter.booked => (
          'Nothing waiting to be loaded',
          'Parcels booked at $_office show here until they are loaded onto a vehicle.',
        ),
      ParcelFilter.onTheWay => (
          'Nothing on the way',
          'Parcels coming to $_office show here once they leave.',
        ),
      ParcelFilter.arrived => (
          'Nothing waiting for collection',
          'Parcels that arrive at $_office show here until they are collected.',
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Icon(Icons.inventory_2_outlined, size: 32, color: AppColors.grey),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.darkText,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            body,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: AppColors.grey),
          ),
          // nothing waiting usually means the next customer is at the counter
          if (_filter == ParcelFilter.booked) ...[
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _openBooking,
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, 48),
                padding: const EdgeInsets.symmetric(horizontal: 24),
              ),
              icon: const Icon(Icons.add_circle_outline, size: 20),
              label: const Text('Book a parcel'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMoreFailed() {
    return Row(
      children: [
        const Expanded(
          child: Text(
            "Couldn't load more parcels.",
            style: TextStyle(fontSize: 14, color: AppColors.grey),
          ),
        ),
        TextButton(
          onPressed: _retryMore,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.link,
            minimumSize: const Size(0, 44),
          ),
          child: const Text('Try again'),
        ),
      ],
    );
  }

  Widget _buildError(Object error) {
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
            onPressed: sessionEnded ? _goToLogin : _reload,
            child: Text(sessionEnded ? 'Log in again' : 'Try again'),
          ),
        ],
      ),
    );
  }
}