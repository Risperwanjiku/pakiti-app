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
      expect(travelTime(40), 'About 40 min on the road');
    });

    test('uses hours, rounded to 15 minutes', () {
      expect(travelTime(60), 'About 1 hr on the road');
      expect(travelTime(75), 'About 1 hr 15 min on the road');
      expect(travelTime(180), 'About 3 hrs on the road');
      expect(travelTime(212), 'About 3 hrs 30 min on the road');
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
  });
}