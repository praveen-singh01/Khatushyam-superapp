class AppProfile {
  const AppProfile({
    required this.id,
    required this.firebaseUid,
    required this.email,
    required this.onboardingCompleted,
    this.displayName,
    this.photoUrl,
    this.phone,
  });

  final String id;
  final String firebaseUid;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final String? phone;
  final bool onboardingCompleted;

  factory AppProfile.fromJson(Map<String, dynamic> json) {
    return AppProfile(
      id: (json['id'] as String?) ?? '',
      firebaseUid: (json['firebaseUid'] as String?) ?? '',
      email: (json['email'] as String?) ?? '',
      displayName: json['displayName'] as String?,
      photoUrl: json['photoUrl'] as String?,
      phone: json['phone'] as String?,
      onboardingCompleted: json['onboardingCompleted'] == true,
    );
  }

  AppProfile copyWith({
    String? displayName,
    String? photoUrl,
    String? phone,
    bool? onboardingCompleted,
  }) {
    return AppProfile(
      id: id,
      firebaseUid: firebaseUid,
      email: email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      phone: phone ?? this.phone,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
    );
  }
}
