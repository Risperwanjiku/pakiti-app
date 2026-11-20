import 'package:flutter_test/flutter_test.dart';
import 'package:pakiti_app/utils/format.dart';

void main() {
  group('ksh', () {
    test('adds commas to thousands', () {
      expect(ksh(350), 'KSh 350');
      expect(ksh(1800), 'KSh 1,800');
      expect(ksh(1234567), 'KSh 1,234,567');
    });

    test('shows whole shillings', () {
      expect(ksh(350.0), 'KSh 350');
      expect(ksh(349.6), 'KSh 350');
    });
  });

  test('parcelCount says parcel for one and parcels for more', () {
    expect(parcelCount(1), '1 parcel');
    expect(parcelCount(3), '3 parcels');
  });

  group('phone numbers', () {
    test('are shown the way people say them', () {
      expect(localPhone('+254745902117'), '0745 902 117');
      expect(phoneAfterCode('+254745902117'), '745 902 117');
    });

    test('hide the middle digits on the label', () {
      expect(maskedPhone('+254745902117'), '0745 *** 117');
    });
  });

  group('travelTime', () {
    test('uses minutes for trips under an hour', () {
      expect(travelTime(40), '40 min by road');
    });

    test('uses hours, rounded to 15 minutes', () {
      expect(travelTime(60), '1 hr by road');
      expect(travelTime(75), '1 hr 15 min by road');
      expect(travelTime(180), '3 hrs by road');
      expect(travelTime(212), '3 hrs 30 min by road');
    });
  });

  group('times', () {
    test('use am and pm', () {
      expect(clockTime(DateTime(2026, 11, 12, 16, 41)), '4:41 pm');
      expect(clockTime(DateTime(2026, 11, 13, 0, 10)), '12:10 am');
      expect(clockTime(DateTime(2026, 11, 13, 12, 5)), '12:05 pm');
    });

    test('dates read the way the label shows them', () {
      expect(dateAndTime(DateTime(2026, 11, 12, 16, 41)), '12 Nov 2026, 4:41 pm');
    });

    test('dates in the parcel history and next to the photo', () {
      expect(longDate(DateTime(2026, 11, 12, 16, 41)), '12 Nov 2026');
      expect(dayAndTime(DateTime(2026, 11, 13, 9, 5)), '13 Nov, 9:05 am');
    });

    test('say which day when it was not today', () {
      final now = DateTime(2026, 11, 17, 11, 7);

      expect(atTimeOrDay(DateTime(2026, 11, 17, 0, 10), now: now), 'at 12:10 am');
      expect(atTimeOrDay(DateTime(2026, 11, 16, 23, 50), now: now), 'on 16 Nov');
      expect(atTimeOrDay(DateTime(2026, 11, 13, 0, 10), now: now), 'on 13 Nov');
      expect(atTimeOrDay(DateTime(2025, 11, 17, 9, 0), now: now), 'on 17 Nov');
    });

    test('for an arrival say the day when it is not today', () {
      final now = DateTime(2026, 11, 17, 22, 5);

      expect(timeWithDay(DateTime(2026, 11, 17, 23, 40), now: now), '11:40 pm');
      expect(timeWithDay(DateTime(2026, 11, 18, 1, 10), now: now), '1:10 am tomorrow');
      expect(timeWithDay(DateTime(2026, 11, 19, 9, 0), now: now), '9:00 am on 19 Nov');
      expect(timeWithDay(DateTime(2026, 12, 1, 9, 0), now: DateTime(2026, 11, 30, 20)), '9:00 am tomorrow');
    });
  });
}