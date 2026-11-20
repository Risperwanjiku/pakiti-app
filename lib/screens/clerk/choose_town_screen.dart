import 'package:flutter/material.dart';

import 'package:pakiti_app/models/booked_parcel.dart';
import 'package:pakiti_app/models/destination.dart';
import 'package:pakiti_app/screens/clerk/book_parcel_screen.dart';
import 'package:pakiti_app/services/clerk_service.dart';
import 'package:pakiti_app/theme/app_colors.dart';
import 'package:pakiti_app/utils/messages.dart';
import 'package:pakiti_app/widgets/booking/missing_town_note.dart';
import 'package:pakiti_app/widgets/booking/town_list.dart';
import 'package:pakiti_app/widgets/booking/town_list_placeholder.dart';
import 'package:pakiti_app/widgets/common/empty_list_card.dart';
import 'package:pakiti_app/widgets/common/load_error_card.dart';
import 'package:pakiti_app/widgets/common/section_title.dart';
import 'package:pakiti_app/widgets/common/page_app_bar.dart';
import 'package:pakiti_app/widgets/form/search_field.dart';

class ChooseTownScreen extends StatefulWidget {
  const ChooseTownScreen({super.key, this.pickOnly = false});

  // true when the booking form opens this to change the town, so the town is sent back to it
  final bool pickOnly;

  @override
  State<ChooseTownScreen> createState() => _ChooseTownScreenState();
}

class _ChooseTownScreenState extends State<ChooseTownScreen> {
  final _clerkService = ClerkService();
  final _searchController = TextEditingController();

  late Future<List<Destination>> _destinations;

  // set by Book another on the Parcel booked screen, so the next form keeps the same sender
  BookedParcel? _sameSenderAs;

  @override
  void initState() {
    super.initState();
    _destinations = _clerkService.fetchDestinations();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadTownsAgain() {
    setState(() {
      _destinations = _clerkService.fetchDestinations();
    });
  }

  Future<void> _chooseTown(Destination destination) async {
    if (widget.pickOnly) {
      Navigator.of(context).pop(destination);
      return;
    }

    final booked = await Navigator.of(context).push<BookedParcel>(
      MaterialPageRoute(
        builder: (_) => BookParcelScreen(
          destination: destination,
          sameSenderAs: _sameSenderAs,
          onBookAnother: _bookAnother,
        ),
      ),
    );

    // after a booking the next form starts empty, unless the clerk taps Book another
    if (booked != null && mounted) {
      setState(() => _sameSenderAs = null);
    }
  }

  void _bookAnother(BookedParcel parcel) {
    setState(() {
      _sameSenderAs = parcel;
      _searchController.clear();
    });
  }

  // only letters and numbers are compared, so "muranga" still finds Murang'a
  String _simplifyForSearch(String text) {
    return text.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.page,
      appBar: PageAppBar(
        title: 'Where is it going?',
        actions: [
          TextButton.icon(
            onPressed: () => showMessage(context, 'The map is coming next.'),
            icon: const Icon(Icons.map_outlined, size: 20),
            label: const Text('Map'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.link,
              minimumSize: const Size(0, 44),
              textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: Column(
        children: [
          Padding(padding: const EdgeInsets.fromLTRB(24, 16, 24, 0), child: _buildSearch()),
          Expanded(
            child: FutureBuilder<List<Destination>>(
              future: _destinations,
              builder: (context, snapshot) {
                return ListView(
                  padding: const EdgeInsets.all(24),
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  children: _buildTowns(snapshot),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // the list below filters as each letter is typed
  Widget _buildSearch() {
    return SearchField(
      controller: _searchController,
      hint: 'Search town or county',
      onChanged: (_) => setState(() {}),
      capitalization: TextCapitalization.words,
    );
  }

  List<Widget> _buildTowns(AsyncSnapshot<List<Destination>> snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return [
        const SectionTitle(title: 'All towns'),
        const SizedBox(height: 12),
        const TownListPlaceholder(),
      ];
    }

    if (snapshot.hasError) {
      return [
        LoadErrorCard(
          error: snapshot.error,
          onRetry: _loadTownsAgain,
          onLogIn: () => goToLogin(context),
        ),
      ];
    }

    final allTowns = snapshot.data!;

    if (allTowns.isEmpty) {
      return [
        const EmptyListCard(
          icon: Icons.location_on_outlined,
          title: 'No towns yet',
          message: 'Your office has no routes yet. Your admin adds them.',
        ),
      ];
    }

    final query = _simplifyForSearch(_searchController.text);
    final towns = query.isEmpty
        ? allTowns
        : allTowns
              .where(
                (town) =>
                    _simplifyForSearch(town.town).contains(query) ||
                    _simplifyForSearch(town.county).contains(query),
              )
              .toList();

    if (towns.isEmpty) {
      return [
        EmptyListCard(
          icon: Icons.location_off_outlined,
          title: 'No parcel office in “${_searchController.text.trim()}”',
          message: 'Parcels can only go to towns where your sacco has a parcel office.',
        ),
      ];
    }

    return [
      SectionTitle(title: query.isEmpty ? 'All towns' : 'Matching towns'),
      const SizedBox(height: 12),
      TownList(towns: towns, onChoose: _chooseTown),
      const SizedBox(height: 24),
      const MissingTownNote(),
    ];
  }
}
