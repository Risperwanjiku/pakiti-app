import 'package:flutter/material.dart';

import 'package:pakiti_app/models/search_result.dart';
import 'package:pakiti_app/screens/clerk/parcel_details_screen.dart';
import 'package:pakiti_app/services/api_client.dart';
import 'package:pakiti_app/services/parcel_service.dart';
import 'package:pakiti_app/theme/app_colors.dart';
import 'package:pakiti_app/utils/format.dart';
import 'package:pakiti_app/utils/messages.dart';
import 'package:pakiti_app/widgets/common/empty_list_card.dart';
import 'package:pakiti_app/widgets/common/load_error_card.dart';
import 'package:pakiti_app/widgets/common/list_heading.dart';
import 'package:pakiti_app/widgets/parcel/parcel_tile.dart';
import 'package:pakiti_app/widgets/form/search_field.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key, this.query = '', this.service, this.onChanged});

  // what was typed on home, searched for as soon as the screen opens
  final String query;

  // called when a parcel opened from here changes, so the screen behind can load again
  final VoidCallback? onChanged;

  // tests pass in a fake one
  final ParcelService? service;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  late final ParcelService _service = widget.service ?? ParcelService();
  late final _searchController = TextEditingController(text: widget.query);
  final _searchFocus = FocusNode();

  Future<SearchResult>? _searchResult;

  // counts searches, so an older one that finishes late doesn't open a parcel
  int _searchCount = 0;

  @override
  void initState() {
    super.initState();

    final query = widget.query.trim();

    if (query.isNotEmpty) {
      _searchResult = _runSearch(query);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  Future<SearchResult> _runSearch(String query) async {
    final thisSearch = ++_searchCount;
    final found = await _service.search(query);

    // a tracking number points at one parcel, so it opens straight away
    if (mounted && thisSearch == _searchCount && !found.byPhone && found.parcels.length == 1) {
      _openDetails(found.parcels.first.trackingNo);
    }

    return found;
  }

  void _submitSearch() {
    final query = _searchController.text.trim();

    if (query.isEmpty) {
      return;
    }

    setState(() {
      _searchResult = _runSearch(query);
    });
  }

  void _clearSearch() {
    _searchCount++;
    _searchController.clear();
    setState(() => _searchResult = null);
    _searchFocus.requestFocus();
  }

  void _openDetails(String trackingNo) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ParcelDetailsScreen(
          trackingNo: trackingNo,
          service: _service,
          onChanged: widget.onChanged,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final result = _searchResult;

    return Scaffold(
      backgroundColor: AppColors.page,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        scrolledUnderElevation: 0,
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.only(right: 16),
          // the clear button shows and hides as text is typed, so each change redraws it
          child: SearchField(
            controller: _searchController,
            focusNode: _searchFocus,
            autofocus: widget.query.isEmpty,
            hint: 'Tracking or phone number',
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _submitSearch(),
            onClear: _clearSearch,
            compact: true,
          ),
        ),
      ),
      body: result == null
          ? ListView(padding: const EdgeInsets.fromLTRB(24, 20, 24, 24), children: [_buildHelp()])
          : FutureBuilder<SearchResult>(
              future: result,
              builder: (context, snapshot) {
                return ListView(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  children: _buildResults(snapshot),
                );
              },
            ),
    );
  }

  Widget _buildHelp() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        'Search with the tracking number on the receipt, like PKT-460048, '
        'or the phone number of the sender or the receiver.',
        style: TextStyle(fontSize: 14, color: AppColors.grey),
      ),
    );
  }

  List<Widget> _buildResults(AsyncSnapshot<SearchResult> snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return [for (var i = 0; i < 3; i++) const ParcelTilePlaceholder()];
    }

    if (snapshot.hasError) {
      return [_buildError(snapshot.error)];
    }

    final result = snapshot.data!;

    if (result.parcels.isEmpty) {
      return [_buildNothingFound(result)];
    }

    final phone = localPhone(result.searchedFor);

    return [
      if (result.byPhone) ...[
        ListHeading(
          title: parcelCount(result.parcels.length),
          caption: result.name == null
              ? 'Sent or received by $phone'
              : 'Sent or received by ${result.name}, $phone',
        ),
        const SizedBox(height: 12),
      ],
      for (final parcel in result.parcels)
        ParcelTile(parcel: parcel, onTap: () => _openDetails(parcel.trackingNo)),
    ];
  }

  Widget _buildNothingFound(SearchResult result) {
    final title = result.byPhone
        ? 'No parcels for ${localPhone(result.searchedFor)}'
        : 'No parcel ${result.searchedFor}';
    final hint = result.byPhone
        ? 'Check the number, or search with the tracking number on the receipt, like PKT-460048.'
        : 'Check the number on the receipt, or search with the phone number of the sender or the receiver.';

    return EmptyListCard(
      title: title,
      message: hint,
      extra: const [
        SizedBox(height: 8),
        Text(
          'Only parcels sent from or to your office show up here.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: AppColors.grey),
        ),
      ],
    );
  }

  Widget _buildError(Object? error) {
    // what was typed needs changing, so there is nothing to try again
    final notUnderstood = error is ApiException && error.statusCode == 422;

    return LoadErrorCard(
      error: error,
      onRetry: _submitSearch,
      onLogIn: () => goToLogin(context),
      canRetry: !notUnderstood,
    );
  }
}
