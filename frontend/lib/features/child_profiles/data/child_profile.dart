class ChildProfile {
  const ChildProfile({
    required this.id,
    required this.displayName,
    required this.isChild,
    this.allergies = const {},
    this.diets = const {},
  });

  factory ChildProfile.parent(int id) {
    return ChildProfile(id: id, displayName: 'Moi', isChild: false);
  }

  factory ChildProfile.fromJson(Map<String, dynamic> json) {
    return ChildProfile(
      id: json['id'] as int,
      displayName: json['displayName'] as String,
      isChild: true,
      allergies: _stringSet(json['allergies']),
      diets: _stringSet(json['diets']),
    );
  }

  final int id;
  final String displayName;
  final bool isChild;
  final Set<String> allergies;
  final Set<String> diets;

  static Set<String> _stringSet(dynamic value) {
    if (value is! List) return const {};
    return value.map((item) => item.toString()).toSet();
  }
}
