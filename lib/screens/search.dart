import 'package:flutter/material.dart';

import '../models/search_result.dart';
import '../services/api_client.dart';
import '../services/parcel_service.dart';
import '../theme/app_colors.dart';
import '../utils/format.dart';
import '../widgets/parcel_tile.dart';
import 'login.dart';
import 'parcel_details.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key, this.query = '', this.service});

  // what was typed on home, searched for as soon as the screen opens
  final String query;

  // tests pass in a fake one
  final ParcelService? service;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  late final ParcelService _service = widget.service ?? ParcelService();
  late final _search = TextEditingController(text: widget.query);
  final _focus = FocusNode();

  Future<SearchResult>? _result;

  // counts searches, so an older one that finishes late doesn't open a parcel
  int _searches = 0;

  @override
  void initState() {
    super.initState();

    final query = widget.query.trim();

    if (query.isNotEmpty) {
      _result = _start(query);
    }
  }

  @override
  void dispose() {
    _search.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<SearchResult> _start(String query) async {
    final search = ++_searches;
    final found = await _service.search(query);

    // a tracking number points at one parcel, so it opens straight away
    if (mounted && search == _searches && !found.byPhone && found.parcels.length == 1) {
      _openDetails(found.parcels.first.trackingNo);
    }

    return found;
  }

  void _submit() {
    final query = _search.text.trim();

    if (query.isEmpty) {
      return;
    }

    setState(() {
      _result = _start(query);
    });
  }

  void _clear() {
    _searches++;
    _search.clear();
    setState(() => _result = null);
    _focus.requestFocus();
  }

  void _openDetails(String trackingNo) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ParcelDetailsScreen(trackingNo: trackingNo, service: _service),
      ),
    );
  }

  void _goToLogin() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;

    return Scaffold(
      backgroundColor: AppColors.page,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        scrolledUnderElevation: 0,
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.only(right: 16),
          child: _buildSearchBox(),
        ),
      ),
      body: result == null
          ? ListView(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
              children: [_buildHelp()],
            )
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

  Widget _buildSearchBox() {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    );

    return TextField(
      controller: _search,
      focusNode: _focus,
      autofocus: widget.query.isEmpty,
      textInputAction: TextInputAction.search,
      onChanged: (_) => setState(() {}),
      onSubmitted: (_) => _submit(),
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: AppColors.darkText,
      ),
      decoration: InputDecoration(
        hintText: 'Tracking or phone number',
        hintStyle: const TextStyle(
          fontWeight: FontWeight.w400,
          color: AppColors.grey,
        ),
        prefixIcon: const Icon(Icons.search, color: AppColors.grey),
        suffixIcon: _search.text.isEmpty
            ? null
            : IconButton(
                tooltip: 'Clear search',
                onPressed: _clear,
                icon: const Icon(Icons.close, color: AppColors.grey),
              ),
        filled: true,
        fillColor: AppColors.page,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        border: border,
        enabledBorder: border,
        focusedBorder: border.copyWith(
          borderSide: const BorderSide(color: AppColors.link, width: 2),
        ),
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

    final count = result.parcels.length;
    final phone = localPhone(result.searchedFor);

    return [
      if (result.byPhone) ...[
        Text(
          count == 1 ? '1 parcel' : '$count parcels',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.darkText,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          result.name == null
              ? 'Sent or received by $phone'
              : 'Sent or received by ${result.name}, $phone',
          style: const TextStyle(fontSize: 13, color: AppColors.grey),
        ),
        const SizedBox(height: 12),
      ],
      for (final parcel in result.parcels)
        ParcelTile(
          parcel: parcel,
          onTap: () => _openDetails(parcel.trackingNo),
        ),
    ];
  }

  Widget _buildNothingFound(SearchResult result) {
    final title = result.byPhone
        ? 'No parcels for ${localPhone(result.searchedFor)}'
        : 'No parcel ${result.searchedFor}';
    final hint = result.byPhone
        ? 'Check the number, or search with the tracking number on the receipt, like PKT-460048.'
        : 'Check the number on the receipt, or search with the phone number of the sender or the receiver.';

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
            hint,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: AppColors.grey),
          ),
          const SizedBox(height: 8),
          const Text(
            'Only parcels sent from or to your office show up here.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppColors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildError(Object? error) {
    final sessionEnded = error is ApiException && error.statusCode == 401;
    final notUnderstood = error is ApiException && error.statusCode == 422;
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
          // what was typed needs changing, so there is nothing to try again
          if (!notUnderstood) ...[
            const SizedBox(height: 16),
            FilledButton(
              onPressed: sessionEnded ? _goToLogin : _submit,
              child: Text(sessionEnded ? 'Log in again' : 'Try again'),
            ),
          ],
        ],
      ),
    );
  }
}