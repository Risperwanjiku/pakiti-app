import 'package:flutter/material.dart';

import 'package:pakiti_app/models/parcel_details.dart';
import 'package:pakiti_app/screens/clerk/parcel_photo_screen.dart';
import 'package:pakiti_app/services/api_client.dart';
import 'package:pakiti_app/services/parcel_service.dart';
import 'package:pakiti_app/theme/app_colors.dart';
import 'package:pakiti_app/utils/format.dart';
import 'package:pakiti_app/utils/messages.dart';
import 'package:pakiti_app/utils/phone_call.dart';
import 'package:pakiti_app/widgets/common/load_error_card.dart';
import 'package:pakiti_app/widgets/common/page_app_bar.dart';
import 'package:pakiti_app/widgets/common/white_card.dart';
import 'package:pakiti_app/widgets/parcel/parcel_facts_card.dart';
import 'package:pakiti_app/widgets/parcel/parcel_history_card.dart';
import 'package:pakiti_app/widgets/parcel/parcel_people_card.dart';
import 'package:pakiti_app/widgets/parcel/parcel_where_now_card.dart';
import 'package:pakiti_app/widgets/parcel/record_changed_warning.dart';

class ParcelDetailsScreen extends StatefulWidget {
  const ParcelDetailsScreen({super.key, required this.trackingNo, this.service});

  final String trackingNo;

  // tests pass in a fake one
  final ParcelService? service;

  @override
  State<ParcelDetailsScreen> createState() => _ParcelDetailsScreenState();
}

class _ParcelDetailsScreenState extends State<ParcelDetailsScreen> {
  late final ParcelService _service = widget.service ?? ParcelService();

  // made once, so the small photo and the full one share one download
  late final ImageProvider _photo = _service.photoOf(widget.trackingNo);

  late Future<ParcelDetails> _details;

  @override
  void initState() {
    super.initState();
    _details = _service.fetchDetails(widget.trackingNo);
  }

  Future<void> _refresh() async {
    setState(() {
      _details = _service.fetchDetails(widget.trackingNo);
    });
    await _details.then((_) {}, onError: (_) {});
  }

  void _retry() {
    setState(() {
      _details = _service.fetchDetails(widget.trackingNo);
    });
  }

  Future<void> _callPhone(String phone) async {
    if (await callNumber(phone)) {
      return;
    }

    if (mounted) {
      showMessage(context, "The phone app didn't open. The number is ${localPhone(phone)}.");
    }
  }

  void _openPhoto() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ParcelPhotoScreen(photo: _photo, trackingNo: widget.trackingNo),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.page,
      appBar: PageAppBar(title: widget.trackingNo),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<ParcelDetails>(
          future: _details,
          builder: (context, snapshot) {
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: _buildContent(snapshot),
              ),
            );
          },
        ),
      ),
    );
  }

  List<Widget> _buildContent(AsyncSnapshot<ParcelDetails> snapshot) {
    final loading = snapshot.connectionState == ConnectionState.waiting;
    final details = snapshot.data;
    final error = snapshot.error;

    if (snapshot.hasError && !loading) {
      return [
        LoadErrorCard(
          error: error,
          onRetry: _retry,
          onLogIn: () => goToLogin(context),
          // trying again won't find a parcel that isn't there
          canRetry: !(error is ApiException && error.statusCode == 404),
        ),
      ];
    }

    if (details == null) {
      return [
        _buildPlaceholder(200),
        const SizedBox(height: 16),
        _buildPlaceholder(160),
        const SizedBox(height: 16),
        _buildPlaceholder(220),
      ];
    }

    return [
      // a changed record matters more than anything else on the page
      if (!details.recordChecked) ...[
        const RecordChangedWarning(),
        const SizedBox(height: 16),
      ],
      ParcelWhereNowCard(details: details, onCall: _callPhone),
      const SizedBox(height: 16),
      ParcelPeopleCard(booking: details.booking, onCall: _callPhone),
      const SizedBox(height: 16),
      ParcelFactsCard(details: details, photo: _photo, onViewPhoto: _openPhoto),
      const SizedBox(height: 24),
      ParcelHistoryCard(details: details),
    ];
  }

  Widget _buildPlaceholder(double height) {
    return SizedBox(height: height, child: const WhiteCard(child: SizedBox.expand()));
  }
}
