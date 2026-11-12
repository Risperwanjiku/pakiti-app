import 'package:flutter/material.dart';

import '../models/destination.dart';
import '../services/api_client.dart';
import '../services/clerk_service.dart';
import '../theme/app_colors.dart';
import 'login.dart';

class ChooseTownScreen extends StatefulWidget {
  const ChooseTownScreen({super.key});

  @override
  State<ChooseTownScreen> createState() => _ChooseTownScreenState();
}

class _ChooseTownScreenState extends State<ChooseTownScreen> {
  final _clerkService = ClerkService();
  final _search = TextEditingController();

  late Future<List<Destination>> _destinations;

  @override
  void initState() {
    super.initState();
    _destinations = _clerkService.fetchDestinations();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _retry() {
    setState(() => _destinations = _clerkService.fetchDestinations());
  }

  void _goToLogin() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  void _comingSoon(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _choose(Destination destination) {
    _comingSoon('Booking to ${destination.town} is coming next.');
  }

  // only letters and numbers are compared, so "muranga" still finds Murang'a
  String _simplify(String text) {
    return text.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.page,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        scrolledUnderElevation: 0,
        titleSpacing: 4,
        title: const Text(
          'Where is it going?',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.darkText,
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () => _comingSoon('The map is coming next.'),
            icon: const Icon(Icons.map_outlined, size: 20),
            label: const Text('Map'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.link,
              minimumSize: const Size(0, 44),
              textStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            child: _buildSearch(),
          ),
          Expanded(
            child: FutureBuilder<List<Destination>>(
              future: _destinations,
              builder: (context, snapshot) {
                return ListView(
                  padding: const EdgeInsets.all(24),
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  children: _buildTowns(snapshot),
                );
              },
            ),
          ),
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
      controller: _search,
      onChanged: (_) => setState(() {}),
      textInputAction: TextInputAction.search,
      textCapitalization: TextCapitalization.words,
      decoration: InputDecoration(
        hintText: 'Search town or county',
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

  List<Widget> _buildTowns(AsyncSnapshot<List<Destination>> snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return [
        _buildTitle('All towns'),
        const SizedBox(height: 12),
        _buildPlaceholder(),
      ];
    }

    if (snapshot.hasError) {
      return [_buildError(snapshot.error)];
    }

    final all = snapshot.data!;

    if (all.isEmpty) {
      return [
        _buildMessage(
          Icons.location_on_outlined,
          'No towns yet',
          'Your office has no routes yet. Your admin adds them.',
        ),
      ];
    }

    final query = _simplify(_search.text);
    final towns = query.isEmpty
        ? all
        : all
            .where((town) =>
                _simplify(town.town).contains(query) ||
                _simplify(town.county).contains(query))
            .toList();

    if (towns.isEmpty) {
      return [
        _buildMessage(
          Icons.location_off_outlined,
          'No parcel office in “${_search.text.trim()}”',
          'Parcels can only go to towns where your sacco has a parcel office.',
        ),
      ];
    }

    return [
      _buildTitle(query.isEmpty ? 'All towns' : 'Matching towns'),
      const SizedBox(height: 12),
      _buildList(towns),
      const SizedBox(height: 24),
      _buildNote(),
    ];
  }

  Widget _buildTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.darkText,
      ),
    );
  }

  Widget _buildList(List<Destination> towns) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < towns.length; i++) ...[
            if (i > 0)
              const Divider(height: 1, thickness: 1, color: AppColors.page),
            _buildTownRow(towns[i]),
          ],
        ],
      ),
    );
  }

  Widget _buildTownRow(Destination destination) {
    return MergeSemantics(
      child: Semantics(
        button: true,
        child: InkWell(
          onTap: () => _choose(destination),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 64),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.statusBookedBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.location_on_outlined,
                      size: 20,
                      color: AppColors.statusBooked,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          destination.town,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: AppColors.darkText,
                          ),
                        ),
                        Text(
                          '${destination.county} County',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right,
                    size: 20,
                    color: AppColors.border,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNote() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 20, color: AppColors.grey),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Can't find a town?",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.darkText,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Parcels can only go to towns where your sacco has a parcel '
                  'office. Your admin adds new offices.',
                  style: TextStyle(fontSize: 13, color: AppColors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessage(IconData icon, String title, String body) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, size: 32, color: AppColors.grey),
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
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: List.generate(6, (_) {
          return SizedBox(
            height: 64,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _buildBar(36, 36),
                  const SizedBox(width: 12),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildBar(96, 14),
                      const SizedBox(height: 8),
                      _buildBar(64, 12),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),
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
}