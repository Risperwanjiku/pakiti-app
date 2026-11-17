import 'package:flutter/material.dart';

import '../models/parcel_details.dart';
import '../theme/app_colors.dart';
import '../utils/format.dart';
import 'dashed_line.dart';

enum _Dot { done, current, upcoming }

enum _Line { solid, dashed, none }

// What has happened to the parcel so far, then the steps still to come in grey.
class ParcelHistory extends StatelessWidget {
  const ParcelHistory({super.key, required this.details});

  final ParcelDetails details;

  @override
  Widget build(BuildContext context) {
    final events = details.events;
    final stepsLeft = details.stepsLeft;
    final firstDay = events.isEmpty ? details.booking.bookedAt : events.first.at;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          longDate(firstDay),
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.grey,
          ),
        ),
        const SizedBox(height: 12),
        for (var i = 0; i < events.length; i++)
          _Step(
            title: _title(events[i]),
            time: _sameDay(events[i].at, firstDay)
                ? clockTime(events[i].at)
                : dayAndTime(events[i].at),
            detail: _detail(events[i]),
            dot: i < events.length - 1 || stepsLeft.isEmpty ? _Dot.done : _Dot.current,
            line: i < events.length - 1
                ? _Line.solid
                : (stepsLeft.isEmpty ? _Line.none : _Line.dashed),
          ),
        for (var i = 0; i < stepsLeft.length; i++)
          _Step(
            title: _comingTitle(stepsLeft[i]),
            detail: _comingDetail(stepsLeft[i]),
            dot: _Dot.upcoming,
            line: i < stepsLeft.length - 1 ? _Line.dashed : _Line.none,
          ),
      ],
    );
  }

  String _title(ParcelEvent event) {
    final booking = details.booking;

    return switch (event.step) {
      CustodyStep.booked => 'Booked at ${event.office ?? details.fromOffice}',
      CustodyStep.loaded =>
        event.vehicle == null ? 'Loaded' : 'Loaded onto ${event.vehicle}',
      CustodyStep.departed => 'Left ${booking.from}',
      CustodyStep.arrived => 'Arrived at ${event.office ?? details.toOffice}',
      CustodyStep.collected => 'Collected by ${booking.receiverName}',
    };
  }

  String _detail(ParcelEvent event) {
    final who = '${event.by}, ${event.byRole}';
    final detail = switch (event.step) {
      CustodyStep.booked => event.hasPhoto ? '$who. Photo taken.' : who,
      CustodyStep.departed =>
        event.vehicle == null ? who : 'On ${event.vehicle} with ${event.by}',
      CustodyStep.collected => 'Handed over by $who',
      _ => who,
    };

    return event.note == null ? detail : '$detail\n${event.note}';
  }

  String _comingTitle(CustodyStep step) {
    final booking = details.booking;

    return switch (step) {
      CustodyStep.booked => 'Booked',
      CustodyStep.loaded => 'Loaded onto a vehicle',
      CustodyStep.departed => 'Leaves ${booking.from}',
      CustodyStep.arrived => 'Arrives at ${details.toOffice}',
      CustodyStep.collected => 'Collected by ${booking.receiverName}',
    };
  }

  String? _comingDetail(CustodyStep step) {
    if (step != CustodyStep.arrived) {
      return null;
    }

    final expected = details.expectedArrival;

    return expected == null
        ? travelTime(details.travelMinutes)
        : 'Expected about ${clockTime(expected)}';
  }

  bool _sameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

class _Step extends StatelessWidget {
  const _Step({
    required this.title,
    this.time,
    this.detail,
    required this.dot,
    required this.line,
  });

  final String title;
  final String? time;
  final String? detail;
  final _Dot dot;
  final _Line line;

  @override
  Widget build(BuildContext context) {
    final time = this.time;
    final detail = this.detail;
    final upcoming = dot == _Dot.upcoming;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // the line runs from under this dot down to the next one
        if (line != _Line.none)
          Positioned(
            left: 6,
            width: 2,
            top: dot == _Dot.current ? 24 : 21,
            bottom: 0,
            child: line == _Line.solid
                ? const ColoredBox(color: AppColors.navy)
                : const DashedLine(color: AppColors.divider, axis: Axis.vertical),
          ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 14,
              child: Padding(
                padding: EdgeInsets.only(top: dot == _Dot.current ? 4 : 5),
                child: Center(child: _buildDot()),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(bottom: line == _Line.none ? 12 : 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: upcoming ? FontWeight.w500 : FontWeight.w600,
                              color: upcoming ? AppColors.grey : AppColors.darkText,
                            ),
                          ),
                        ),
                        if (time != null) ...[
                          const SizedBox(width: 12),
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              time,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.grey,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (detail != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        detail,
                        style: const TextStyle(fontSize: 13, color: AppColors.grey),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDot() {
    return switch (dot) {
      _Dot.done => Container(
          width: 12,
          height: 12,
          decoration: const BoxDecoration(
            color: AppColors.navy,
            shape: BoxShape.circle,
          ),
        ),
      _Dot.current => Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.navy, width: 3),
            boxShadow: const [
              BoxShadow(color: AppColors.navTint, spreadRadius: 4),
            ],
          ),
        ),
      _Dot.upcoming => Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.border, width: 2),
          ),
        ),
    };
  }
}