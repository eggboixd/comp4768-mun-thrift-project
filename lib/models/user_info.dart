class UserInfo {
  final String id;
  final String name;
  final String address;
  final String? about;
  final String profileImageUrl;

  UserInfo({
    required this.id,
    required this.name,
    required this.address,
    this.about,
    required this.profileImageUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'address': address,
      'about': about,
      'profileImageUrl': profileImageUrl,
    };
  }
}
