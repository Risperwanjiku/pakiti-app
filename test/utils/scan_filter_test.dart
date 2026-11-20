import 'package:flutter_test/flutter_test.dart';
import 'package:pakiti_app/utils/scan_filter.dart';

final start = DateTime(2026, 11, 17, 14, 0);

DateTime after(int milliseconds) => start.add(Duration(milliseconds: milliseconds));

void main() {
  test('only Pakiti labels count', () {
    final filter = ScanFilter();

    expect(filter.read(['6161100000123'], now: start), isNull);
    expect(filter.read(['https://example.com', ' PKT-460048 '], now: after(250)), 'PKT-460048');
    expect(filter.read([null], now: after(500)), isNull);
  });

  test('a label held in front of the camera counts once', () {
    final filter = ScanFilter();

    expect(filter.read(['PKT-460048'], now: start), 'PKT-460048');
    expect(filter.read(['PKT-460048'], now: after(250)), isNull);
    expect(filter.read(['PKT-460048'], now: after(1500)), isNull);
    expect(filter.read(['PKT-460048'], now: after(3000)), isNull);
  });

  test('the same label counts again after 2 seconds out of view', () {
    final filter = ScanFilter();

    expect(filter.read(['PKT-460048'], now: start), 'PKT-460048');
    expect(filter.read(['PKT-460048'], now: after(2500)), 'PKT-460048');
  });

  test('the next label counts straight away', () {
    final filter = ScanFilter();

    expect(filter.read(['PKT-460048'], now: start), 'PKT-460048');
    expect(filter.read(['PKT-461215'], now: after(400)), 'PKT-461215');
  });

  test('nothing counts while paused, and a new label waits its turn', () {
    final filter = ScanFilter();

    expect(filter.read(['PKT-461144'], now: start), 'PKT-461144');

    // the warning for PKT-461144 is open, with the label still held up
    expect(filter.read(['PKT-461144'], now: after(1000), paused: true), isNull);
    expect(filter.read(['PKT-461144'], now: after(2500), paused: true), isNull);
    expect(filter.read(['PKT-461144'], now: after(3000)), isNull);

    // a label shown while paused counts once the pause is over
    expect(filter.read(['PKT-461215'], now: after(3200), paused: true), isNull);
    expect(filter.read(['PKT-461215'], now: after(3400)), 'PKT-461215');
  });
}
