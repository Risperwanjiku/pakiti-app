enum StaffRole { admin, clerk, conductor }

class StaffUser {
  const StaffUser({
    required this.id,
    required this.fullName,
    required this.phone,
    required this.role,
    this.officeId,
    this.officeName,
  });

  factory StaffUser.fromJson(Map<String, dynamic> json) {
    return StaffUser(
      id: json['user_id'] as int,
      fullName: json['full_name'] as String,
      phone: json['phone'] as String,
      role: StaffRole.values.byName(json['role'] as String),
      officeId: json['office_id'] as int?,
      officeName: json['office_name'] as String?,
    );
  }

  final int id;
  final String fullName;
  final String phone;
  final StaffRole role;
  final int? officeId;
  final String? officeName;

  String get firstName => fullName.split(' ').first;
}