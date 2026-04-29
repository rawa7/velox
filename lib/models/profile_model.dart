class ProfileData {
  final Profile profile;
  final ProfileAccountInfo accountInfo;
  final Summary summary;

  ProfileData({
    required this.profile,
    required this.accountInfo,
    required this.summary,
  });

  factory ProfileData.fromJson(Map<String, dynamic> json) {
    final profileMap = Map<String, dynamic>.from(json['profile'] as Map);
    final summaryMap = Map<String, dynamic>.from(json['summary'] as Map);

    // Inject top-level usertype object into account_info and profile maps
    // so the localised name_ku / name_ar fields are available when parsing both.
    final usertypeMap = json['usertype'];
    final accountMap = Map<String, dynamic>.from(json['account_info'] as Map);
    if (usertypeMap is Map) {
      accountMap['usertype'] = usertypeMap;
      profileMap['usertype'] = usertypeMap;
    }

    return ProfileData(
      profile: Profile.fromJson(profileMap),
      accountInfo: ProfileAccountInfo.fromJson(accountMap),
      summary: Summary.fromJson(summaryMap),
    );
  }

  /// Payload for QR: [Profile.usercode], then [ProfileAccountInfo.usercode], then [ProfileAccountInfo.customerCode].
  String? get qrCodePayload {
    final p = profile.usercode.trim();
    if (p.isNotEmpty) return p;
    final u = accountInfo.usercode.trim();
    if (u.isNotEmpty) return u;
    final c = accountInfo.customerCode.trim();
    if (c.isNotEmpty) return c;
    return null;
  }
}

class Profile {
  final String id;
  final String name;
  final String phone;
  final String address;
  final String email;
  /// Customer code from API (`data.profile.usercode`).
  final String usercode;
  final String usertype;
  final String usertypeName;
  final String usertypeNameKu;
  final String usertypeNameAr;
  final String isActive;
  final bool hasPassword;

  Profile({
    required this.id,
    required this.name,
    required this.phone,
    required this.address,
    required this.email,
    this.usercode = '',
    required this.usertype,
    required this.usertypeName,
    this.usertypeNameKu = '',
    this.usertypeNameAr = '',
    required this.isActive,
    required this.hasPassword,
  });

  /// Returns the localised usertype name for the given locale code.
  String localizedUserTypeName(String languageCode) {
    switch (languageCode) {
      case 'fa': // Kurdish (Sorani)
        return usertypeNameKu.isNotEmpty ? usertypeNameKu : usertypeName;
      case 'ar':
        return usertypeNameAr.isNotEmpty ? usertypeNameAr : usertypeName;
      default:
        return usertypeName;
    }
  }

  factory Profile.fromJson(Map<String, dynamic> json) {
    // `usertype` may come as a nested object or a plain string/int
    final ut = json['usertype'];
    String utId = '';
    String utName = '';
    String utNameKu = '';
    String utNameAr = '';

    if (ut is Map) {
      utId = ut['id']?.toString() ?? '';
      utName = ut['name']?.toString() ?? '';
      utNameKu = ut['name_ku']?.toString() ?? '';
      utNameAr = ut['name_ar']?.toString() ?? '';
    } else {
      utId = ut?.toString() ?? '';
      utName = json['usertype_name']?.toString() ?? '';
    }

    return Profile(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      usercode: json['usercode']?.toString() ?? '',
      usertype: utId,
      usertypeName: utName,
      usertypeNameKu: utNameKu,
      usertypeNameAr: utNameAr,
      isActive: json['is_active']?.toString() ?? '1',
      hasPassword: json['has_password'] == true,
    );
  }
}

class ProfileAccountInfo {
  final int customerId;
  final String customerName;
  final String customerCode;
  /// Same family as [Profile.usercode] (`data.account_info.usercode`).
  final String usercode;
  final double currentBalance;
  final String accountType;
  final String accountTypeKu;
  final String accountTypeAr;
  final double debtLimit;
  final double ordersAwaitingPayment;
  final double availableCapacity;

  ProfileAccountInfo({
    required this.customerId,
    required this.customerName,
    required this.customerCode,
    this.usercode = '',
    required this.currentBalance,
    required this.accountType,
    this.accountTypeKu = '',
    this.accountTypeAr = '',
    required this.debtLimit,
    required this.ordersAwaitingPayment,
    required this.availableCapacity,
  });

  /// Returns the localised account type name for the given locale code.
  String localizedAccountType(String languageCode) {
    switch (languageCode) {
      case 'fa': // Kurdish (Sorani)
        return accountTypeKu.isNotEmpty ? accountTypeKu : accountType;
      case 'ar':
        return accountTypeAr.isNotEmpty ? accountTypeAr : accountType;
      default:
        return accountType;
    }
  }

  factory ProfileAccountInfo.fromJson(Map<String, dynamic> json) {
    // account_type may come as a nested usertype object or plain string
    final at = json['account_type'];
    String atName = '';
    String atNameKu = '';
    String atNameAr = '';

    if (at is Map) {
      atName = at['name']?.toString() ?? '';
      atNameKu = at['name_ku']?.toString() ?? '';
      atNameAr = at['name_ar']?.toString() ?? '';
    } else {
      atName = at?.toString() ?? '';
    }

    // Also check flat fields returned directly in account_info
    if (atNameKu.isEmpty) atNameKu = json['account_type_ku']?.toString() ?? '';
    if (atNameAr.isEmpty) atNameAr = json['account_type_ar']?.toString() ?? '';

    // Also check nested usertype object if present
    final ut = json['usertype'];
    if (ut is Map) {
      if (atName.isEmpty) atName = ut['name']?.toString() ?? '';
      if (atNameKu.isEmpty) atNameKu = ut['name_ku']?.toString() ?? '';
      if (atNameAr.isEmpty) atNameAr = ut['name_ar']?.toString() ?? '';
    }

    return ProfileAccountInfo(
      customerId: json['customer_id'] is int
          ? json['customer_id']
          : int.tryParse(json['customer_id']?.toString() ?? '0') ?? 0,
      customerName: json['customer_name']?.toString() ?? '',
      customerCode: json['customer_code']?.toString() ?? '',
      usercode: json['usercode']?.toString() ?? '',
      currentBalance: (json['current_balance'] is num)
          ? (json['current_balance'] as num).toDouble()
          : double.tryParse(json['current_balance']?.toString() ?? '0') ?? 0.0,
      accountType: atName,
      accountTypeKu: atNameKu,
      accountTypeAr: atNameAr,
      debtLimit: (json['debt_limit'] is num)
          ? (json['debt_limit'] as num).toDouble()
          : double.tryParse(json['debt_limit']?.toString() ?? '0') ?? 0.0,
      ordersAwaitingPayment: (json['orders_awaiting_payment'] is num)
          ? (json['orders_awaiting_payment'] as num).toDouble()
          : double.tryParse(json['orders_awaiting_payment']?.toString() ?? '0') ?? 0.0,
      availableCapacity: (json['available_capacity'] is num)
          ? (json['available_capacity'] as num).toDouble()
          : double.tryParse(json['available_capacity']?.toString() ?? '0') ?? 0.0,
    );
  }
}

class Summary {
  final int totalItems;
  final int activeItems;
  final int excludedItems;
  final double totalPurchases;
  final double totalPayments;
  final int totalPaidItems;

  Summary({
    required this.totalItems,
    required this.activeItems,
    required this.excludedItems,
    required this.totalPurchases,
    required this.totalPayments,
    required this.totalPaidItems,
  });

  factory Summary.fromJson(Map<String, dynamic> json) {
    return Summary(
      totalItems: json['total_items'] is int
          ? json['total_items']
          : int.tryParse(json['total_items']?.toString() ?? '0') ?? 0,
      activeItems: json['active_items'] is int
          ? json['active_items']
          : int.tryParse(json['active_items']?.toString() ?? '0') ?? 0,
      excludedItems: json['excluded_items'] is int
          ? json['excluded_items']
          : int.tryParse(json['excluded_items']?.toString() ?? '0') ?? 0,
      totalPurchases: (json['total_purchases'] is num)
          ? (json['total_purchases'] as num).toDouble()
          : double.tryParse(json['total_purchases']?.toString() ?? '0') ?? 0.0,
      totalPayments: (json['total_payments'] is num)
          ? (json['total_payments'] as num).toDouble()
          : double.tryParse(json['total_payments']?.toString() ?? '0') ?? 0.0,
      totalPaidItems: json['total_paid_items'] is int
          ? json['total_paid_items']
          : int.tryParse(json['total_paid_items']?.toString() ?? '0') ?? 0,
    );
  }
}

