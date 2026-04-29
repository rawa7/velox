// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'فيلوكس';

  @override
  String get login => 'تسجيل الدخول';

  @override
  String get phone => 'الهاتف';

  @override
  String get password => 'كلمة المرور';

  @override
  String get enterPhone => 'أدخل رقم هاتفك';

  @override
  String get enterPassword => 'أدخل كلمة المرور';

  @override
  String get forgotPassword => 'نسيت كلمة المرور؟';

  @override
  String get dontHaveAccount => 'ليس لديك حساب؟';

  @override
  String get registerNow => 'سجل الآن';

  @override
  String get home => 'الرئيسية';

  @override
  String get websites => 'المواقع';

  @override
  String get store => 'المتجر';

  @override
  String get myOrders => 'طلباتي';

  @override
  String get account => 'الحساب';

  @override
  String get hello => 'مرحباً';

  @override
  String get newOrder => 'طلب جديد';

  @override
  String get help => 'مساعدة';

  @override
  String get hotDeals => 'عروض ساخنة لك';

  @override
  String get searchWebsites => 'البحث في المواقع...';

  @override
  String get noWebsitesFound => 'لم يتم العثور على مواقع';

  @override
  String get dolphinShop => 'متجر فيلوكس';

  @override
  String get allBrands => 'جميع الماركات';

  @override
  String get searchProducts => 'البحث عن المنتجات...';

  @override
  String get noProductsFound => 'لم يتم العثور على منتجات';

  @override
  String get order => 'طلب';

  @override
  String get viewDetails => 'عرض التفاصيل';

  @override
  String get brand => 'الماركة';

  @override
  String get category => 'الفئة';

  @override
  String get description => 'الوصف';

  @override
  String get placeOrder => 'إرسال الطلب';

  @override
  String get productLink => 'رابط المنتج';

  @override
  String get pasteProductLink => 'الصق رابط المنتج هنا';

  @override
  String get productLinkHelper =>
      'أضف أي سلة تسوق من شي إن أو منتج فردي من أي موقع. الصق الرابط ثم اضغط «استخراج من الرابط».';

  @override
  String get dataExtraction => 'استخراج البيانات';

  @override
  String get extractFromLink => 'استخراج من الرابط';

  @override
  String get extractingFromLink => 'جاري الاستخراج...';

  @override
  String get productDetails => 'تفاصيل المنتج';

  @override
  String get productDetailsExtracted => 'تم استخراج تفاصيل المنتج';

  @override
  String cartItemsExtracted(int count) {
    return 'تم استخراج $count عنصرًا من السلة';
  }

  @override
  String get sizeHintExample => 'مثل: M، L، XL، مقاس واحد...';

  @override
  String get getDataFromLink => 'جلب البيانات من الرابط';

  @override
  String get fetchingDetails => 'جاري جلب تفاصيل المنتج...';

  @override
  String get selectDataEntryMode => 'اختر طريقة إدخال البيانات';

  @override
  String get selectDataEntryModeDescription => 'كيف تريد إدخال بيانات المنتج؟';

  @override
  String get automatic => 'تلقائي';

  @override
  String get automaticDescription => 'جلب البيانات من الرابط تلقائياً';

  @override
  String get manual => 'يدوي';

  @override
  String get manualDescription => 'إدخال تفاصيل المنتج يدوياً';

  @override
  String get automaticMode => 'الوضع التلقائي';

  @override
  String get manualMode => 'الوضع اليدوي';

  @override
  String get switchToAutomatic => 'التبديل إلى التلقائي';

  @override
  String get switchToManual => 'التبديل إلى اليدوي';

  @override
  String get productImage => 'صورة المنتج';

  @override
  String get selectImage => 'اختر صورة';

  @override
  String get takePhoto => 'التقط صورة';

  @override
  String get chooseFromGallery => 'اختر من المعرض';

  @override
  String get cancel => 'إلغاء';

  @override
  String get detectedPrice => 'السعر المكتشف';

  @override
  String get currency => 'العملة';

  @override
  String get selectCurrency => 'اختر العملة';

  @override
  String get color => 'اللون';

  @override
  String get itemCodeOrName => 'رمز / اسم المنتج';

  @override
  String get size => 'المقاس';

  @override
  String get selectSize => 'اختر المقاس';

  @override
  String get quantity => 'الكمية';

  @override
  String get note => 'ملاحظة (اختياري)';

  @override
  String get enterNote => 'أدخل أي ملاحظات إضافية...';

  @override
  String get charactersRemaining => 'حرف متبقي';

  @override
  String get country => 'البلد';

  @override
  String get selectCountry => 'اختر البلد';

  @override
  String get submit => 'إرسال';

  @override
  String get pleaseSelectImage => 'الرجاء اختيار صورة المنتج';

  @override
  String get pleaseSelectCountry => 'الرجاء اختيار البلد';

  @override
  String get pleaseSelectSize => 'الرجاء اختيار المقاس';

  @override
  String get orderSubmitted => 'تم إرسال الطلب بنجاح!';

  @override
  String get errorSubmittingOrder => 'خطأ في إرسال الطلب';

  @override
  String get allOrders => 'جميع الطلبات';

  @override
  String get processed => 'معالج';

  @override
  String get waiting => 'قيد الانتظار';

  @override
  String get delivered => 'تم التوصيل';

  @override
  String get noOrdersFound => 'لم يتم العثور على طلبات';

  @override
  String get loading => 'جاري التحميل...';

  @override
  String get orderDetails => 'تفاصيل الطلب';

  @override
  String get orderId => 'رقم الطلب';

  @override
  String get serialNumber => 'ID';

  @override
  String get link => 'الرابط';

  @override
  String get itemPrice => 'سعر المنتج';

  @override
  String get shipping => 'الشحن';

  @override
  String get cargo => 'الشحن الداخلي';

  @override
  String get commission => 'العمولة';

  @override
  String get tax => 'الضريبة';

  @override
  String get taxWithPercentLabel => 'الضريبة (٪٦)';

  @override
  String get totalPrice => 'السعر الإجمالي';

  @override
  String get status => 'الحالة';

  @override
  String get paymentStatus => 'حالة الدفع';

  @override
  String get createdAt => 'تاريخ الإنشاء';

  @override
  String get none => 'لا يوجد';

  @override
  String get reorder => 'إعادة الطلب';

  @override
  String get acceptOrder => 'قبول الطلب';

  @override
  String get rejectOrder => 'رفض الطلب';

  @override
  String get confirmAccept => 'تأكيد الطلب';

  @override
  String get confirmApprove => 'تأكيد الموافقة';

  @override
  String get confirmReject => 'تأكيد الرفض';

  @override
  String get areYouSureAccept => 'هل أنت متأكد من قبول هذا الطلب؟';

  @override
  String get areYouSureApprove => 'هل أنت متأكد من الموافقة على هذا الطلب؟';

  @override
  String get areYouSureReject => 'هل أنت متأكد من رفض هذا الطلب؟';

  @override
  String get yes => 'نعم';

  @override
  String get no => 'لا';

  @override
  String get orderAccepted => 'تم قبول الطلب بنجاح!';

  @override
  String get orderRejected => 'تم رفض الطلب بنجاح!';

  @override
  String get errorProcessingOrder => 'خطأ في معالجة الطلب';

  @override
  String get profile => 'الملف الشخصي';

  @override
  String get wallet => 'المحفظة';

  @override
  String get currentBalance => 'الرصيد الحالي';

  @override
  String get accountType => 'نوع الحساب';

  @override
  String get debtLimit => 'حد الدين';

  @override
  String get owedAmount => 'المبلغ المستحق';

  @override
  String get ordersAwaitingPayment => 'طلبات في انتظار الدفع';

  @override
  String get availableCapacity => 'السعة المتاحة';

  @override
  String get contactInformation => 'معلومات الاتصال';

  @override
  String get phoneNumber => 'رقم الهاتف';

  @override
  String get email => 'البريد الإلكتروني';

  @override
  String get address => 'العنوان';

  @override
  String get accountLimits => 'حدود الحساب';

  @override
  String get financialSummary => 'الملخص المالي';

  @override
  String get totalSpent => 'إجمالي الإنفاق';

  @override
  String get totalDeposits => 'إجمالي الإيداعات';

  @override
  String get totalWithdrawals => 'إجمالي السحوبات';

  @override
  String get drShipping => 'شحن دي آر';

  @override
  String get drsShippingCost => 'تكلفة شحن DRS';

  @override
  String get drsCreditLimit => 'حد ائتمان DRS';

  @override
  String get orderStatistics => 'إحصائيات الطلبات';

  @override
  String get logout => 'تسجيل الخروج';

  @override
  String get settings => 'الإعدادات';

  @override
  String get language => 'اللغة';

  @override
  String get english => 'الإنجليزية';

  @override
  String get arabic => 'العربية';

  @override
  String get kurdish => 'الكردية';

  @override
  String get changeLanguage => 'تغيير اللغة';

  @override
  String get selectLanguage => 'اختر اللغة';

  @override
  String get price => 'السعر';

  @override
  String get qty => 'الكمية';

  @override
  String get accept => 'قبول';

  @override
  String get approve => 'موافقة';

  @override
  String get reject => 'رفض';

  @override
  String get addToOrder => 'إضافة إلى الطلب';

  @override
  String get error => 'خطأ';

  @override
  String get success => 'نجاح';

  @override
  String get retry => 'إعادة المحاولة';

  @override
  String get close => 'إغلاق';

  @override
  String get save => 'حفظ';

  @override
  String get edit => 'تعديل';

  @override
  String get delete => 'حذف';

  @override
  String get search => 'بحث';

  @override
  String get filter => 'تصفية';

  @override
  String get sort => 'ترتيب';

  @override
  String get refresh => 'تحديث';

  @override
  String get contactSupport => 'الاتصال بالدعم';

  @override
  String get profileChangeDetailsHint =>
      'يرجى التواصل مع الدعم لتغيير البيانات.';

  @override
  String get rateOurApp => 'قيم تطبيقنا';

  @override
  String get areYouSureLogout => 'هل أنت متأكد من تسجيل الخروج؟';

  @override
  String get logoutConfirm => 'تأكيد تسجيل الخروج';

  @override
  String get noInternetConnection => 'لا يوجد اتصال بالإنترنت';

  @override
  String get pleaseCheckConnection => 'يرجى التحقق من اتصالك بالإنترنت';

  @override
  String get somethingWentWrong => 'حدث خطأ ما';

  @override
  String get tryAgain => 'حاول مرة أخرى';

  @override
  String get loadingProfile => 'جاري تحميل الملف الشخصي...';

  @override
  String get failedToLoadProfile => 'فشل تحميل الملف الشخصي';

  @override
  String get noBannersAvailable => 'لا توجد بانرات متاحة';

  @override
  String get contactFormComingSoon => 'نموذج الاتصال قريباً!';

  @override
  String get ratingComingSoon => 'التقييم قريباً!';

  @override
  String get helpAndSupport => 'المساعدة والدعم';

  @override
  String get helpMessage =>
      'للمساعدة، يرجى الاتصال بفريق الدعم.\n\nالهاتف: +964 750 774 6088\nالبريد الإلكتروني: support@veloxshipping.com';

  @override
  String get chatOnWhatsApp => 'محادثة عبر واتساب';

  @override
  String get ok => 'حسناً';

  @override
  String get noWebsitesAvailable => 'لا توجد مواقع متاحة';

  @override
  String get notificationsComingSoon => 'الإشعارات قريباً!';

  @override
  String get advancedFilterComingSoon => 'التصفية المتقدمة قريباً!';

  @override
  String get goldenprizma => 'جولدن بريزما';

  @override
  String helloUser(String name) {
    return 'مرحباً، $name!';
  }

  @override
  String get processingOrder => 'معالجة الطلب';

  @override
  String get totalItems => 'إجمالي العناصر';

  @override
  String orderItemsSectionTitle(int count) {
    return '$count عنصرًا';
  }

  @override
  String get outOfStock => 'هذا المنتج غير متوفر.';

  @override
  String get exchangeRateItemToUsd => 'سعر الصرف (عملة المنتج → دولار)';

  @override
  String get exchangeRateUsdToIqd => 'سعر الصرف (دولار → دينار)';

  @override
  String get active => 'نشط';

  @override
  String get paid => 'مدفوع';

  @override
  String get excluded => 'مستبعد';

  @override
  String get updatedAt => 'آخر تحديث في';

  @override
  String get website => 'موقع إلكتروني';

  @override
  String get deliveryRequest => 'طلب التوصيل';

  @override
  String get requestDelivery => 'طلب التوصيل';

  @override
  String get youRequestedDelivery => 'لقد طلبت التوصيل';

  @override
  String get youWillGetItASAP => 'سوف تحصل عليه في أقرب وقت';

  @override
  String get whatsappSupport => 'دعم واتساب';

  @override
  String get ourLocation => 'موقعنا';

  @override
  String get moreOptions => 'خيارات أخرى';

  @override
  String get accountStatement => 'كشف الحساب';

  @override
  String get deliveredToErbil => 'تم التوصيل إلى أربيل';

  @override
  String get financialSummaryText => 'الملخص المالي';

  @override
  String get accountLimitsText => 'حدود الحساب';

  @override
  String get debtLimitText => 'حد الدين';

  @override
  String get availableCapacityText => 'السعة المتاحة';

  @override
  String get totalPurchases => 'إجمالي المشتريات';

  @override
  String get totalPayments => 'إجمالي المدفوعات';

  @override
  String get contactSupportText => 'الاتصال بالدعم';

  @override
  String get quickLinks => 'روابط سريعة';

  @override
  String get deleteAccount => 'حذف الحساب';

  @override
  String get deleteAccountConfirmTitle => 'حذف الحساب؟';

  @override
  String get deleteAccountConfirmMessage =>
      'هل أنت متأكد تماماً من رغبتك في حذف حسابك؟ هذا الإجراء لا يمكن التراجع عنه.';

  @override
  String get deleteAccountFinalConfirmTitle => 'تحذير نهائي!';

  @override
  String get deleteAccountFinalConfirmMessage =>
      'هذه فرصتك الأخيرة! بمجرد حذف حسابك، ستتم إزالة جميع بياناتك بشكل دائم. هل أنت متأكد؟';

  @override
  String get yesDelete => 'نعم، احذف';

  @override
  String get noCancel => 'لا، إلغاء';

  @override
  String get accountDeleted => 'تم حذف الحساب';

  @override
  String get accountDeletedMessage =>
      'تم حذف حسابك بنجاح. اتصل بالدعم إذا كنت بحاجة إلى إعادة تفعيله.';

  @override
  String get accountDeletionFailed => 'فشل حذف الحساب';

  @override
  String get enterPasswordToDelete => 'أدخل كلمة المرور لتأكيد الحذف';

  @override
  String get pleaseLogin => 'الرجاء تسجيل الدخول';

  @override
  String get loginRequired => 'تحتاج إلى تسجيل الدخول للوصول إلى هذه الميزة';

  @override
  String get loginNow => 'تسجيل الدخول الآن';

  @override
  String get continueAsGuest => 'متابعة كضيف';

  @override
  String get skipAccount => 'تخطي الحساب';

  @override
  String get signIn => 'تسجيل الدخول';

  @override
  String get signUp => 'إنشاء حساب';

  @override
  String get fullName => 'الاسم الكامل';

  @override
  String get city => 'المدينة';

  @override
  String get selectCity => 'اختر مدينتك';

  @override
  String get pleaseSelectCity => 'الرجاء اختيار مدينتك';

  @override
  String get enterYourFullName => 'أدخل اسمك الكامل';

  @override
  String get enterYourPhoneNumber => 'أدخل رقم هاتفك';

  @override
  String get enterYourPassword => 'أدخل كلمة المرور';

  @override
  String get enterYourAddress => 'أدخل عنوانك';

  @override
  String get pleaseEnterYourName => 'الرجاء إدخال اسمك';

  @override
  String get nameMustBeAtLeast2Characters =>
      'يجب أن يكون الاسم حرفين على الأقل';

  @override
  String get pleaseEnterYourPhoneNumber => 'الرجاء إدخال رقم هاتفك';

  @override
  String get pleaseEnterValidPhoneNumber =>
      'يجب أن يكون رقم الهاتف 11 رقمًا بالضبط';

  @override
  String get pleaseEnterYourAddress => 'الرجاء إدخال عنوانك';

  @override
  String get pleaseEnterPassword => 'الرجاء إدخال كلمة المرور';

  @override
  String get passwordMustBeAtLeast6Characters =>
      'يجب أن تكون كلمة المرور 6 أحرف على الأقل';

  @override
  String get pleaseEnterPhoneAndPassword =>
      'الرجاء إدخال رقم الهاتف وكلمة المرور';

  @override
  String get accountCreated => 'تم إنشاء الحساب!';

  @override
  String get accountCreatedSuccessMessage =>
      'تم إنشاء حسابك بنجاح!\n\nسيقوم المسؤول بتفعيل حسابك في أقرب وقت ممكن. سيتم إشعارك بمجرد تفعيل حسابك.';

  @override
  String get dontHaveAnAccount => 'ليس لديك حساب؟';

  @override
  String get changePassword => 'تغيير كلمة المرور';

  @override
  String get changePasswordDescription =>
      'الرجاء إدخال كلمة المرور الحالية واختيار كلمة مرور جديدة لتأمين حسابك.';

  @override
  String get currentPassword => 'كلمة المرور الحالية';

  @override
  String get enterCurrentPassword => 'أدخل كلمة المرور الحالية';

  @override
  String get pleaseEnterCurrentPassword => 'الرجاء إدخال كلمة المرور الحالية';

  @override
  String get newPassword => 'كلمة المرور الجديدة';

  @override
  String get enterNewPassword => 'أدخل كلمة المرور الجديدة';

  @override
  String get pleaseEnterNewPassword => 'الرجاء إدخال كلمة المرور الجديدة';

  @override
  String get passwordMustBeAtLeast4Characters =>
      'يجب أن تكون كلمة المرور 4 أحرف على الأقل';

  @override
  String get confirmPassword => 'تأكيد كلمة المرور';

  @override
  String get enterConfirmPassword => 'أعد إدخال كلمة المرور الجديدة';

  @override
  String get pleaseEnterConfirmPassword => 'الرجاء تأكيد كلمة المرور';

  @override
  String get passwordsDoNotMatch => 'كلمات المرور غير متطابقة';

  @override
  String get passwordChangedSuccessfully => 'تم تغيير كلمة المرور بنجاح';

  @override
  String get failedToChangePassword => 'فشل تغيير كلمة المرور';

  @override
  String get userNotFound => 'المستخدم غير موجود';

  @override
  String get passwordTips => 'نصائح كلمة المرور';

  @override
  String get passwordTip1 => 'يجب أن تكون كلمة المرور 4 أحرف على الأقل';

  @override
  String get passwordTip2 => 'استخدم كلمة مرور قوية لحماية حسابك';

  @override
  String get pendingPrice => 'السعر قيد الانتظار';

  @override
  String get notifications => 'الإشعارات';

  @override
  String get lightMode => 'الوضع الفاتح';

  @override
  String get darkMode => 'الوضع الداكن';

  @override
  String get welcomeToVelox => 'مرحباً بك في فيلوكس';

  @override
  String get haveAccount => 'هل لديك حساب؟';

  @override
  String get iHaveAnAccount => 'نعم، سجّل الدخول';

  @override
  String get createNewAccount => 'إنشاء حساب جديد';

  @override
  String get enterPhoneToRegister => 'أدخل رقم هاتفك للبدء';

  @override
  String get sendVerificationCode => 'إرسال رمز التحقق';

  @override
  String get verifyYourPhone => 'تحقق من رقم هاتفك';

  @override
  String codeSentTo(String phone) {
    return 'تم إرسال الرمز إلى $phone';
  }

  @override
  String get verificationCode => 'رمز التحقق';

  @override
  String get enterVerificationCode => 'أدخل الرمز المكوّن من 6 أرقام';

  @override
  String get verify => 'تحقق';

  @override
  String get resendCode => 'إعادة إرسال الرمز';

  @override
  String resendIn(int seconds) {
    return 'إعادة الإرسال خلال $seconds ثانية';
  }

  @override
  String get completeYourProfile => 'أكمل ملفك الشخصي';

  @override
  String get almostThere => 'اقتربت! أدخل بياناتك';

  @override
  String get otpSentSuccess => 'تم إرسال رمز التحقق عبر واتساب';

  @override
  String get invalidOtpCode => 'رمز غير صحيح. حاول مرة أخرى.';

  @override
  String get phoneAlreadyRegistered =>
      'رقم الهاتف مسجل مسبقاً. الرجاء تسجيل الدخول.';

  @override
  String get step1of3 => 'الخطوة 1 من 3';

  @override
  String get step2of3 => 'الخطوة 2 من 3';

  @override
  String get step3of3 => 'الخطوة 3 من 3';

  @override
  String get whatsappCode => 'ستصلك رسالة على واتساب تحتوي على الرمز';

  @override
  String get back => 'رجوع';

  @override
  String get myQrCode => 'رمزي';

  @override
  String get customerCodeUnavailable => 'الرمز غير متوفر';
}
