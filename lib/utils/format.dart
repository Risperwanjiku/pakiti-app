const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

// 1 -> 1 parcel, 3 -> 3 parcels
String parcelCount(int parcels) => parcels == 1 ? '1 parcel' : '$parcels parcels';

// 1800 -> KSh 1,800
String ksh(num amount) {
  final whole = amount.round().toString();
  final grouped = whole.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',');

  return 'KSh $grouped';
}

// +254745902117 -> 0745 902 117
String localPhone(String phone) {
  final digits = phone.startsWith('+254') ? phone.substring(4) : phone;

  if (digits.length != 9) {
    return phone;
  }

  return '0${digits.substring(0, 3)} ${digits.substring(3, 6)} ${digits.substring(6)}';
}

// +254745902117 -> 745 902 117, the way the phone fields show it after +254
String phoneAfterCode(String phone) {
  final digits = phone.startsWith('+254') ? phone.substring(4) : phone;

  if (digits.length != 9) {
    return digits;
  }

  return '${digits.substring(0, 3)} ${digits.substring(3, 6)} ${digits.substring(6)}';
}

// +254745902117 -> 0745 *** 117, so the label on the parcel does not show the whole number
String maskedPhone(String phone) {
  final parts = localPhone(phone).split(' ');

  return parts.length == 3 ? '${parts[0]} *** ${parts[2]}' : localPhone(phone);
}

// 180 -> 3 hrs by road, short so it stays on one line under the town
String travelTime(int minutes) {
  if (minutes < 60) {
    return '$minutes min by road';
  }

  final rounded = (minutes / 15).round() * 15;
  final hours = rounded ~/ 60;
  final extraMinutes = rounded % 60;
  final hoursText = hours == 1 ? '1 hr' : '$hours hrs';

  return extraMinutes == 0 ? '$hoursText by road' : '$hoursText $extraMinutes min by road';
}

// 4:39 pm
String clockTime(DateTime time) {
  final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
  final minute = time.minute.toString().padLeft(2, '0');

  return '$hour:$minute ${time.hour < 12 ? 'am' : 'pm'}';
}

// 12 Nov 2026
String longDate(DateTime time) {
  return '${time.day} ${_months[time.month - 1]} ${time.year}';
}

// 12 Nov 2026, 4:41 pm
String dateAndTime(DateTime time) {
  return '${longDate(time)}, ${clockTime(time)}';
}

// 12 Nov, 4:41 pm
String dayAndTime(DateTime time) {
  return '${time.day} ${_months[time.month - 1]}, ${clockTime(time)}';
}

// 1:10 am, 1:10 am tomorrow or 1:10 am on 22 Nov, for an expected arrival,
// since a trip that leaves late in the evening gets in after midnight
String timeWithDay(DateTime time, {DateTime? now}) {
  final today = now ?? DateTime.now();
  final day = DateTime(time.year, time.month, time.day);
  final daysAway = day.difference(DateTime(today.year, today.month, today.day)).inDays;

  return switch (daysAway) {
    0 => clockTime(time),
    1 => '${clockTime(time)} tomorrow',
    _ => '${clockTime(time)} on ${time.day} ${_months[time.month - 1]}',
  };
}

// at 4:41 pm for a time today, on 12 Nov for an earlier day,
// so a parcel booked days ago doesn't look like it was booked today
String atTimeOrDay(DateTime time, {DateTime? now}) {
  final today = now ?? DateTime.now();

  if (time.year == today.year && time.month == today.month && time.day == today.day) {
    return 'at ${clockTime(time)}';
  }

  return 'on ${time.day} ${_months[time.month - 1]}';
}
