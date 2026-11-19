// Decides which camera readings count. The camera reads a label many times a second,
// so the same label only counts again after it has been out of view for 2 seconds.
class ScanFilter {
  static final _label = RegExp(r'^PKT-\d{6}$');

  String? _last;
  DateTime? _lastSeen;

  // the tracking number to act on, or null when there is nothing new
  String? read(Iterable<String?> values, {required DateTime now, bool paused = false}) {
    final label = values.map((value) => value?.trim() ?? '').where(_label.hasMatch).firstOrNull;

    if (label == null) {
      return null;
    }

    final lastSeen = _lastSeen;
    final stillInView = label == _last &&
        lastSeen != null &&
        now.difference(lastSeen) < const Duration(seconds: 2);

    if (paused) {
      // the label being dealt with stays counted as in view, and a new one waits
      if (label == _last) {
        _lastSeen = now;
      }
      return null;
    }

    _last = label;
    _lastSeen = now;

    return stillInView ? null : label;
  }
}