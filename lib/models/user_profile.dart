class UserProfile {
  final String id;
  final String nickname;
  final String? avatarUrl;
  final String provider;

  const UserProfile({
    required this.id,
    required this.nickname,
    this.avatarUrl,
    required this.provider,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'nickname': nickname,
        'avatarUrl': avatarUrl,
        'provider': provider,
      };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        id: (json['id'] ?? '').toString(),
        nickname: (json['nickname'] ?? '').toString(),
        avatarUrl: json['avatarUrl']?.toString(),
        provider: (json['provider'] ?? '').toString(),
      );
}
