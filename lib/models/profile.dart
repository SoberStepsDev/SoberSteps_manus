class Profile {
  final String id;
  final String? username;
  final DateTime? sobrietyStartDate;
  final String? substanceType;
  final String? addictionCategory; // 'substance', 'behavioral', 'return_to_self'
  final bool returnToSelfEnabled;
  final String? returnToSelfType; // 'self_hatred', 'perfectionism', 'toxic_relationships'
  final int checkinReminderHour;
  final String? emergencyContactName;
  final String? emergencyContactPhone;
  final String abVariant;
  final bool contentPolicyAccepted;
  final DateTime createdAt;

  Profile({
    required this.id,
    this.username,
    this.sobrietyStartDate,
    this.substanceType,
    this.addictionCategory,
    this.returnToSelfEnabled = false,
    this.returnToSelfType,
    this.checkinReminderHour = 21,
    this.emergencyContactName,
    this.emergencyContactPhone,
    this.abVariant = 'A',
    this.contentPolicyAccepted = false,
    required this.createdAt,
  });

  factory Profile.fromJson(Map<String, dynamic> json) => Profile(
        id: json['id'],
        username: json['username'],
        sobrietyStartDate: json['sobriety_start_date'] != null
            ? DateTime.parse(json['sobriety_start_date'])
            : null,
        substanceType: json['substance_type'] ?? json['addiction_type'],
        addictionCategory: json['addiction_category'],
        returnToSelfEnabled: json['return_to_self_enabled'] ?? false,
        returnToSelfType: json['return_to_self_type'],
        checkinReminderHour: json['checkin_reminder_hour'] ?? 21,
        emergencyContactName: json['emergency_contact_name'],
        emergencyContactPhone: json['emergency_contact_phone'],
        abVariant: json['ab_variant'] ?? 'A',
        contentPolicyAccepted: json['content_policy_accepted'] ?? false,
        createdAt: DateTime.parse(json['created_at']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'sobriety_start_date': sobrietyStartDate?.toIso8601String().split('T')[0],
        'substance_type': substanceType,
        'addiction_type': substanceType,
        'addiction_category': addictionCategory,
        'return_to_self_enabled': returnToSelfEnabled,
        'return_to_self_type': returnToSelfType,
        'checkin_reminder_hour': checkinReminderHour,
        'emergency_contact_name': emergencyContactName,
        'emergency_contact_phone': emergencyContactPhone,
        'ab_variant': abVariant,
        'content_policy_accepted': contentPolicyAccepted,
      };
}
