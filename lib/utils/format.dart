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

// 180 -> About 3 hrs on the road
String travelTime(int minutes) {
  if (minutes < 60) {
    return 'About $minutes min on the road';
  }

  final rounded = (minutes / 15).round() * 15;
  final hours = rounded ~/ 60;
  final rest = rounded % 60;
  final hrs = hours == 1 ? '1 hr' : '$hours hrs';

  return rest == 0 ? 'About $hrs on the road' : 'About $hrs $rest min on the road';
}

// 4:39 pm
String clockTime(DateTime time) {
  final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
  final minute = time.minute.toString().padLeft(2, '0');

  return '$hour:$minute ${time.hour < 12 ? 'am' : 'pm'}';
}