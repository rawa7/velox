class OnboardingSlide {
  final int id;
  final int slideOrder;
  final String? imageUrl;
  final String titleEn;
  final String titleKu;
  final String titleAr;
  final String bodyEn;
  final String bodyKu;
  final String bodyAr;

  const OnboardingSlide({
    required this.id,
    required this.slideOrder,
    this.imageUrl,
    required this.titleEn,
    required this.titleKu,
    required this.titleAr,
    required this.bodyEn,
    required this.bodyKu,
    required this.bodyAr,
  });

  factory OnboardingSlide.fromJson(Map<String, dynamic> json) {
    return OnboardingSlide(
      id: json['id'] as int,
      slideOrder: json['slide_order'] as int,
      imageUrl: json['image_url'] as String?,
      titleEn: json['title_en'] as String? ?? '',
      titleKu: json['title_ku'] as String? ?? '',
      titleAr: json['title_ar'] as String? ?? '',
      bodyEn: json['body_en'] as String? ?? '',
      bodyKu: json['body_ku'] as String? ?? '',
      bodyAr: json['body_ar'] as String? ?? '',
    );
  }

  String titleFor(String languageCode) {
    switch (languageCode) {
      case 'ar':
        return titleAr;
      case 'fa':
        return titleKu;
      default:
        return titleEn;
    }
  }

  String bodyFor(String languageCode) {
    switch (languageCode) {
      case 'ar':
        return bodyAr;
      case 'fa':
        return bodyKu;
      default:
        return bodyEn;
    }
  }
}
