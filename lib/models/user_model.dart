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
    );
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
    };
  }

  bool get isBronzeAccount => usertype == '5';

  /// True for Silver-tier accounts — hides 3rd-party websites & Add Order.
  /// Matches by usertype ID ("1") or by name once the backend returns it.
  bool get isSilverAccount =>
      usertype == '1' ||
      usertypeName?.toLowerCase().trim() == 'silver';
}
