import 'dart:convert';

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

  static const String _sharePrefix = 'MYAM_PROFILE_V1:';

  static Set<String> _stringSet(dynamic value) {
    if (value is! List) return const {};
    return value.map((item) => item.toString()).toSet();
  }

  String toSharePayload() {
    return _sharePrefix + base64Url.encode(utf8.encode(_shareJson()));
  }

  String _shareJson() {
    return jsonEncode({
      'displayName': displayName,
      'allergies': allergies.toList()..sort(),
      'diets': diets.toList()..sort(),
    });
  }

  static ChildProfileShareSnapshot? tryParseSharePayload(String value) {
    if (!value.startsWith(_sharePrefix)) return null;

    try {
      final raw = utf8.decode(
        base64Url.decode(value.substring(_sharePrefix.length)),
      );
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;

      return ChildProfileShareSnapshot(
        displayName: decoded['displayName']?.toString() ?? 'Profil enfant',
        allergies: _stringList(decoded['allergies']),
        diets: _stringList(decoded['diets']),
      );
    } catch (_) {
      return null;
    }
  }

  static List<String> _stringList(dynamic value) {
    if (value is! List) return const <String>[];
    return value.map((item) => item.toString()).toList();
  }
}

class ChildProfileShareSnapshot {
  const ChildProfileShareSnapshot({
    required this.displayName,
    required this.allergies,
    required this.diets,
  });

  final String displayName;
  final List<String> allergies;
  final List<String> diets;

  String toPayload() {
    return ChildProfile._sharePrefix +
        base64Url.encode(utf8.encode(jsonEncode({
          'displayName': displayName,
          'allergies': [...allergies]..sort(),
          'diets': [...diets]..sort(),
        })));
  }
}
