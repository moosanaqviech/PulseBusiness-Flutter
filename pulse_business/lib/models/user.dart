class AppUser {
  final String uid;
  final String email;
  final bool hasBusinessProfile;
  final DateTime createdAt;

  AppUser({
    required this.uid,
    required this.email,
    this.hasBusinessProfile = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory AppUser.fromMap(Map<String, dynamic> map, String uid) {
    return AppUser(
      uid: uid,
      email: map['email'] ?? '',
      hasBusinessProfile: map['hasBusinessProfile'] ?? false,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'hasBusinessProfile': hasBusinessProfile,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  AppUser copyWith({
    String? uid,
    String? email,
    bool? hasBusinessProfile,
    DateTime? createdAt,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      hasBusinessProfile: hasBusinessProfile ?? this.hasBusinessProfile,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}