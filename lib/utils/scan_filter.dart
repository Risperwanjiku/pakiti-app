// Decides which camera readings count. The camera reads a label many times a second,
// so the same label only counts again after it has been out of view for 2 seconds.
class ScanFilter {
  static final _labelPattern = RegExp(r'^PKT-\d{6}$');

  String? _lastLabel;
  DateTime? _lastSeen;

  // the tracking number to act on, or null when there is nothing new
  String? read(Iterable<String?> values, {required DateTime now, bool paused = false}) {
    final label = values.map((value) => value?.trim() ?? '').where(_labelPattern.hasMatch).firstOrNull;

    if (label == null) {
      return null;
    }

    final lastSeen = _lastSeen;
    final stillInView = label == _lastLabel &&
        lastSeen != null &&
        now.difference(lastSeen) < const Duration(seconds: 2);

    if (paused) {
      // the label being dealt with stays counted as in view, and a new one waits
      if (label == _lastLabel) {
        _lastSeen = now;
      }
      return null;
    }

    _lastLabel = label;
    _lastSeen = now;

    return stillInView ? null : label;
  }
}