class User {
  final int id;
  final String? name;
  final String phone;
  final String? email;
  final String? address;
  final int isActive;
  final String? createdAt;
  final String? usertype; // "5" = bronze, others = gold/silver/plat
  final String? usertypeName; // e.g. "Bronze", "Silver", "Gold", "Platinum"
  /// Tier header gradient / text (from login `usertype` or flat user fields).
  final String? color1;
  final String? color2;
  final String? textColor;

  User({
    required this.id,
    this.name,
    required this.phone,
    this.email,
    this.address,
    required this.isActive,
    this.createdAt,
    this.usertype,
    this.usertypeName,
    this.color1,
    this.color2,
    this.textColor,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: int.parse(json['id'].toString()),
      name: json['name'],
      phone: json['phone'],
      email: json['email'],
      address: json['address'],
      isActive: int.parse(json['is_active'].toString()),
      createdAt: json['created_at'],
      usertype: json['usertype']?.toString(),
      usertypeName: json['usertype_name']?.toString(),
      color1: json['color1']?.toString(),
      color2: json['color2']?.toString(),
      textColor: json['text_color']?.toString(),
    );
  }

  /// Applies optional `usertype` tier colors/name onto a user field map (login / profile APIs).
  static Map<String, dynamic> mergeUsertypeIntoUserMap(
    Map<String, dynamic> userMap,
    dynamic usertypeJson,
  ) {
    final m = Map<String, dynamic>.from(userMap);
    // jsonDecode nested maps are often Map<dynamic, dynamic>, not Map<String, dynamic>
    if (usertypeJson is Map) {
      final ut = Map<String, dynamic>.from(usertypeJson);
      if (ut['name'] != null) m['usertype_name'] = ut['name'].toString();
      m['color1'] = ut['color1'] ?? m['color1'];
      m['color2'] = ut['color2'] ?? m['color2'];
      m['text_color'] = ut['text_color'] ?? m['text_color'];
    }
    return m;
  }

  /// Merges `data.user` with optional `data.usertype` (login response).
  factory User.fromLoginApiData(Map<String, dynamic> data) {
    final raw = data['user'];
    if (raw is! Map) {
      throw ArgumentError('login data must contain a user map');
    }
    final userMap = Map<String, dynamic>.from(raw);
    return User.fromJson(mergeUsertypeIntoUserMap(userMap, data['usertype']));
  }

  /// After [update_profile.php] / [profile.php]: overlay `profile` + merge `usertype` tier styling.
  factory User.fromUpdateProfileApiData(User existing, Map<String, dynamic> data) {
    final profileRaw = data['profile'];
    if (profileRaw is! Map) return existing;
    final profile = Map<String, dynamic>.from(profileRaw);
    final base = Map<String, dynamic>.from(existing.toJson());
    if (profile['name'] != null) base['name'] = profile['name'];
    if (profile['phone'] != null) base['phone'] = profile['phone'];
    if (profile.containsKey('email')) base['email'] = profile['email'];
    if (profile.containsKey('address')) base['address'] = profile['address'];
    if (profile['usertype'] != null) base['usertype'] = profile['usertype'].toString();
    if (profile['usertype_name'] != null) {
      base['usertype_name'] = profile['usertype_name'].toString();
    }
    if (profile['is_active'] != null) {
      base['is_active'] = profile['is_active'];
    }
    return User.fromJson(mergeUsertypeIntoUserMap(base, data['usertype']));
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'address': address,
      'is_active': isActive,
      'created_at': createdAt,
      'usertype': usertype,
      'usertype_name': usertypeName,
      'color1': color1,
      'color2': color2,
      'text_color': textColor,
    };
  }

  bool get isBronzeAccount => usertype == '5';

  /// True for Silver-tier accounts — hides 3rd-party websites & Add Order.
  /// Matches by usertype ID ("1") or by name once the backend returns it.
  bool get isSilverAccount =>
      usertype == '1' ||
      usertypeName?.toLowerCase().trim() == 'silver';
}
