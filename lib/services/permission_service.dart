import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';

/// معلومات إصدار نظام أندرويد وآلية التعامل مع الأذونات
class AndroidVersionInfo {
  final int sdkInt;
  final String release;
  final String deviceModel;
  final String securityPatch;

  const AndroidVersionInfo({
    required this.sdkInt,
    required this.release,
    required this.deviceModel,
    required this.securityPatch,
  });

  /// وصف سلوك الأذونات بناءً على إصدار SDK
  String get permissionBehaviorDescription {
    if (sdkInt <= 22) {
      return 'أندرويد 5.0 - 5.1 (Lollipop): تُمنح الأذونات تلقائياً عند التثبيت عبر AndroidManifest.xml.';
    } else if (sdkInt <= 28) {
      return 'أندرويد 6.0 - 9.0: أذونات وقت التشغيل مطلوبة وتُعرض على المستخدم بشكل ديناميكي.';
    } else if (sdkInt == 29) {
      return 'أندرويد 10 (Q): تم فصل الموقع في الخلفية. تم تقديم التخزين المحدود (Scoped Storage).';
    } else if (sdkInt == 30) {
      return 'أندرويد 11 (R): أذونات لمرة واحدة "هذه المرة فقط" وإعادة ضبط تلقائية للتطبيقات غير المستخدمة.';
    } else if (sdkInt == 31 || sdkInt == 32) {
      return 'أندرويد 12 (S): يجب طلب الموقع الدقيق والتقريبي معاً. تم تحديث أذونات البلوتوث (SCAN, CONNECT, ADVERTISE).';
    } else if (sdkInt == 33) {
      return 'أندرويد 13 (Tiramisu): يتطلب POST_NOTIFICATIONS وقت التشغيل. أذونات وسائط دقيقة (صور/فيديو/صوت).';
    } else if (sdkInt == 34) {
      return 'أندرويد 14: اختيار جزئي للصور والفيديو (READ_MEDIA_VISUAL_USER_SELECTED). قيود صارمة على خدمات المقدمة.';
    } else {
      return 'أندرويد 15+: بيئة خصوصية محسّنة، صفحات ذاكرة 16 كيلوبايت، وقيود محسّنة على خدمات الخلفية.';
    }
  }
}

/// نموذج بيانات إذن التطبيق على أندرويد وiOS
class AppPermissionItem {
  final String id;
  final Permission permission;
  final String name;
  final String category;
  final String description;
  final String androidPermissionName;
  final String iosUsageDescriptionKey;
  final IconData icon;
  final Color accentColor;
  final bool isSpecialPermission;

  const AppPermissionItem({
    required this.id,
    required this.permission,
    required this.name,
    required this.category,
    required this.description,
    required this.androidPermissionName,
    required this.iosUsageDescriptionKey,
    required this.icon,
    required this.accentColor,
    this.isSpecialPermission = false,
  });
}

class PermissionService {
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  /// قائمة شاملة بجميع أذونات الجوال لأندرويد وiOS
  static final List<AppPermissionItem> allPermissions = [

    // ─── الموقع والتحديد ───────────────────────────────────────────────────
    const AppPermissionItem(
      id: 'location',
      permission: Permission.location,
      name: 'الموقع الدقيق والتقريبي',
      category: 'الموقع والتحديد',
      description: 'الوصول إلى إحداثيات GPS وموقع الشبكة للخرائط وخدمات التحديد الجغرافي.',
      androidPermissionName: 'ACCESS_FINE_LOCATION & ACCESS_COARSE_LOCATION',
      iosUsageDescriptionKey: 'NSLocationWhenInUseUsageDescription',
      icon: Icons.location_on_rounded,
      accentColor: Color(0xFF1E88E5),
    ),

    // ─── الوسائط والأجهزة ──────────────────────────────────────────────────
    const AppPermissionItem(
      id: 'camera',
      permission: Permission.camera,
      name: 'الكاميرا',
      category: 'الوسائط والأجهزة',
      description: 'التقاط الصور ومسح رموز QR وتسجيل مقاطع الفيديو المباشرة.',
      androidPermissionName: 'android.permission.CAMERA',
      iosUsageDescriptionKey: 'NSCameraUsageDescription',
      icon: Icons.camera_alt_rounded,
      accentColor: Color(0xFF8E24AA),
    ),
    const AppPermissionItem(
      id: 'microphone',
      permission: Permission.microphone,
      name: 'الميكروفون والصوت',
      category: 'الوسائط والأجهزة',
      description: 'تسجيل الرسائل الصوتية والبودكاست وتمكين إدخال الصوت.',
      androidPermissionName: 'android.permission.RECORD_AUDIO',
      iosUsageDescriptionKey: 'NSMicrophoneUsageDescription',
      icon: Icons.mic_rounded,
      accentColor: Color(0xFFD81B60),
    ),
    const AppPermissionItem(
      id: 'speech',
      permission: Permission.speech,
      name: 'التعرف على الكلام',
      category: 'الوسائط والأجهزة',
      description: 'تحويل الكلام المنطوق إلى نص وتنفيذ الأوامر الصوتية.',
      androidPermissionName: 'RECORD_AUDIO (Voice Recognition)',
      iosUsageDescriptionKey: 'NSSpeechRecognitionUsageDescription',
      icon: Icons.record_voice_over_rounded,
      accentColor: Color(0xFF5E35B1),
    ),

    // ─── التخزين والوسائط ──────────────────────────────────────────────────
    const AppPermissionItem(
      id: 'photos',
      permission: Permission.photos,
      name: 'الصور والمعرض',
      category: 'التخزين والوسائط',
      description: 'تصفح واختيار واستيراد ملفات الصور من ألبوم الجهاز.',
      androidPermissionName: 'READ_MEDIA_IMAGES (API 33+) / READ_EXTERNAL_STORAGE',
      iosUsageDescriptionKey: 'NSPhotoLibraryUsageDescription',
      icon: Icons.photo_library_rounded,
      accentColor: Color(0xFFFB8C00),
    ),
    const AppPermissionItem(
      id: 'videos',
      permission: Permission.videos,
      name: 'مقاطع الفيديو',
      category: 'التخزين والوسائط',
      description: 'قراءة واختيار مقاطع الفيديو المخزنة على ذاكرة الجهاز.',
      androidPermissionName: 'READ_MEDIA_VIDEO (API 33+)',
      iosUsageDescriptionKey: 'NSPhotoLibraryUsageDescription',
      icon: Icons.video_library_rounded,
      accentColor: Color(0xFFE53935),
    ),
    const AppPermissionItem(
      id: 'audio',
      permission: Permission.audio,
      name: 'الموسيقى والملفات الصوتية',
      category: 'التخزين والوسائط',
      description: 'الوصول إلى ملفات الموسيقى والبودكاست والملفات الصوتية المحلية.',
      androidPermissionName: 'READ_MEDIA_AUDIO (API 33+)',
      iosUsageDescriptionKey: 'NSAppleMusicUsageDescription',
      icon: Icons.audiotrack_rounded,
      accentColor: Color(0xFF00897B),
    ),

    // ─── المعلومات الشخصية ─────────────────────────────────────────────────
    const AppPermissionItem(
      id: 'contacts',
      permission: Permission.contacts,
      name: 'جهات الاتصال',
      category: 'المعلومات الشخصية',
      description: 'الوصول إلى جهات اتصال الجهاز لربط الملفات الشخصية وإيجاد الأصدقاء.',
      androidPermissionName: 'READ_CONTACTS / WRITE_CONTACTS',
      iosUsageDescriptionKey: 'NSContactsUsageDescription',
      icon: Icons.contacts_rounded,
      accentColor: Color(0xFF43A047),
    ),
    const AppPermissionItem(
      id: 'calendar',
      permission: Permission.calendarFullAccess,
      name: 'التقويم',
      category: 'المعلومات الشخصية',
      description: 'قراءة وجدولة المواعيد والاجتماعات والفعاليات في التقويم.',
      androidPermissionName: 'READ_CALENDAR / WRITE_CALENDAR',
      iosUsageDescriptionKey: 'NSCalendarsFullAccessUsageDescription',
      icon: Icons.calendar_month_rounded,
      accentColor: Color(0xFF1E88E5),
    ),
    const AppPermissionItem(
      id: 'reminders',
      permission: Permission.reminders,
      name: 'التذكيرات والمهام',
      category: 'المعلومات الشخصية',
      description: 'إنشاء وعرض وإشعار المهام والتذكيرات المخطط لها.',
      androidPermissionName: 'SCHEDULE_EXACT_ALARM',
      iosUsageDescriptionKey: 'NSRemindersFullAccessUsageDescription',
      icon: Icons.event_note_rounded,
      accentColor: Color(0xFF039BE5),
    ),

    // ─── الاتصالات والتنبيهات ──────────────────────────────────────────────
    const AppPermissionItem(
      id: 'notification',
      permission: Permission.notification,
      name: 'الإشعارات',
      category: 'الاتصالات والتنبيهات',
      description: 'إرسال التنبيهات الفورية وإشعارات شريط الحالة والشارات الصوتية.',
      androidPermissionName: 'POST_NOTIFICATIONS (API 33+)',
      iosUsageDescriptionKey: 'UNUserNotificationCenter',
      icon: Icons.notifications_active_rounded,
      accentColor: Color(0xFFE91E63),
    ),
    const AppPermissionItem(
      id: 'phone',
      permission: Permission.phone,
      name: 'الهاتف والمكالمات',
      category: 'الاتصالات والتنبيهات',
      description: 'إجراء مكالمات هاتفية وقراءة حالة الهاتف وعرض سجل المكالمات.',
      androidPermissionName: 'READ_PHONE_STATE, CALL_PHONE, READ_CALL_LOG',
      iosUsageDescriptionKey: 'CallKit / Telephone scheme',
      icon: Icons.phone_in_talk_rounded,
      accentColor: Color(0xFF7CB342),
    ),
    const AppPermissionItem(
      id: 'sms',
      permission: Permission.sms,
      name: 'الرسائل القصيرة (SMS)',
      category: 'الاتصالات والتنبيهات',
      description: 'إرسال واستقبال وقراءة رسائل SMS وMMS.',
      androidPermissionName: 'SEND_SMS, RECEIVE_SMS, READ_SMS',
      iosUsageDescriptionKey: 'MFMessageComposeViewController',
      icon: Icons.sms_rounded,
      accentColor: Color(0xFFF57C00),
    ),

    // ─── اللاسلكي والاتصال ─────────────────────────────────────────────────
    const AppPermissionItem(
      id: 'bluetooth_scan',
      permission: Permission.bluetoothScan,
      name: 'مسح البلوتوث',
      category: 'اللاسلكي والاتصال',
      description: 'مسح ملحقات Bluetooth Low Energy المجاورة والمنارات اللاسلكية.',
      androidPermissionName: 'BLUETOOTH_SCAN (API 31+)',
      iosUsageDescriptionKey: 'NSBluetoothAlwaysUsageDescription',
      icon: Icons.bluetooth_searching_rounded,
      accentColor: Color(0xFF0288D1),
    ),
    const AppPermissionItem(
      id: 'bluetooth_connect',
      permission: Permission.bluetoothConnect,
      name: 'الاتصال بالبلوتوث',
      category: 'اللاسلكي والاتصال',
      description: 'إنشاء اتصالات مقترنة بأجهزة البلوتوث وسماعات الرأس الصوتية.',
      androidPermissionName: 'BLUETOOTH_CONNECT (API 31+)',
      iosUsageDescriptionKey: 'NSBluetoothPeripheralUsageDescription',
      icon: Icons.bluetooth_connected_rounded,
      accentColor: Color(0xFF3F51B5),
    ),
    const AppPermissionItem(
      id: 'bluetooth_advertise',
      permission: Permission.bluetoothAdvertise,
      name: 'بث البلوتوث',
      category: 'اللاسلكي والاتصال',
      description: 'بث إشارات البلوتوث للإعلان عن البيانات للأجهزة الأخرى.',
      androidPermissionName: 'BLUETOOTH_ADVERTISE (API 31+)',
      iosUsageDescriptionKey: 'NSBluetoothPeripheralUsageDescription',
      icon: Icons.bluetooth_audio_rounded,
      accentColor: Color(0xFF00ACC1),
    ),
    const AppPermissionItem(
      id: 'nearby_wifi',
      permission: Permission.nearbyWifiDevices,
      name: 'أجهزة Wi-Fi القريبة',
      category: 'اللاسلكي والاتصال',
      description: 'اكتشاف والاتصال بأجهزة Wi-Fi القريبة دون الحاجة إلى موقع GPS.',
      androidPermissionName: 'NEARBY_WIFI_DEVICES (API 33+)',
      iosUsageDescriptionKey: 'NSLocalNetworkUsageDescription',
      icon: Icons.wifi_tethering_rounded,
      accentColor: Color(0xFF00897B),
    ),

    // ─── الجهاز والمستشعرات ────────────────────────────────────────────────
    const AppPermissionItem(
      id: 'sensors',
      permission: Permission.sensors,
      name: 'مستشعرات الجسم',
      category: 'الجهاز والمستشعرات',
      description: 'الوصول إلى مستشعرات الجسم الحيوية مثل مراقبي معدل ضربات القلب.',
      androidPermissionName: 'BODY_SENSORS / BODY_SENSORS_BACKGROUND',
      iosUsageDescriptionKey: 'NSMotionUsageDescription',
      icon: Icons.sensors_rounded,
      accentColor: Color(0xFF7E57C2),
    ),
    const AppPermissionItem(
      id: 'activity_recognition',
      permission: Permission.activityRecognition,
      name: 'النشاط البدني',
      category: 'الجهاز والمستشعرات',
      description: 'التعرف على حركة المستخدم مثل المشي والركض وركوب الدراجة والقيادة.',
      androidPermissionName: 'ACTIVITY_RECOGNITION',
      iosUsageDescriptionKey: 'NSMotionUsageDescription',
      icon: Icons.directions_run_rounded,
      accentColor: Color(0xFFFF7043),
    ),

    // ─── النظام والمتقدم ───────────────────────────────────────────────────
    const AppPermissionItem(
      id: 'system_alert_window',
      permission: Permission.systemAlertWindow,
      name: 'العرض فوق التطبيقات',
      category: 'النظام والمتقدم',
      description: 'رسم نوافذ عائمة أو رؤوس دردشة فوق التطبيقات الأخرى الجارية.',
      androidPermissionName: 'SYSTEM_ALERT_WINDOW',
      iosUsageDescriptionKey: 'غير متاح على iOS',
      icon: Icons.layers_rounded,
      accentColor: Color(0xFF6D4C41),
      isSpecialPermission: true,
    ),
    const AppPermissionItem(
      id: 'schedule_exact_alarm',
      permission: Permission.scheduleExactAlarm,
      name: 'جدولة تنبيهات دقيقة',
      category: 'النظام والمتقدم',
      description: 'تشغيل الإشعارات أو الإجراءات المجدولة في أوقات محددة بدقة.',
      androidPermissionName: 'SCHEDULE_EXACT_ALARM / USE_EXACT_ALARM',
      iosUsageDescriptionKey: 'الإشعارات المحلية',
      icon: Icons.alarm_on_rounded,
      accentColor: Color(0xFFD84315),
    ),
    const AppPermissionItem(
      id: 'install_packages',
      permission: Permission.requestInstallPackages,
      name: 'تثبيت تطبيقات مجهولة',
      category: 'النظام والمتقدم',
      description: 'السماح للتطبيق بطلب تثبيت حزم APK من التخزين الخارجي.',
      androidPermissionName: 'REQUEST_INSTALL_PACKAGES',
      iosUsageDescriptionKey: 'غير متاح على iOS',
      icon: Icons.system_update_rounded,
      accentColor: Color(0xFF37474F),
      isSpecialPermission: true,
    ),
  ];

  /// جلب معلومات جهاز أندرويد وإصدار النظام
  Future<AndroidVersionInfo?> getAndroidInfo() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return null;
    }
    try {
      final androidInfo = await _deviceInfo.androidInfo;
      return AndroidVersionInfo(
        sdkInt: androidInfo.version.sdkInt,
        release: androidInfo.version.release,
        deviceModel: '${androidInfo.manufacturer} ${androidInfo.model}',
        securityPatch: androidInfo.version.securityPatch ?? 'غير معروف',
      );
    } catch (e) {
      debugPrint('خطأ في جلب معلومات أندرويد: $e');
      return null;
    }
  }

  /// جلب حالة جميع الأذونات المتتبعة
  Future<Map<Permission, PermissionStatus>> getAllStatuses() async {
    final Map<Permission, PermissionStatus> result = {};
    for (final item in allPermissions) {
      try {
        result[item.permission] = await item.permission.status;
      } catch (e) {
        result[item.permission] = PermissionStatus.denied;
      }
    }
    return result;
  }

  /// جلب حالة إذن واحد
  Future<PermissionStatus> getStatus(Permission permission) async {
    try {
      return await permission.status;
    } catch (e) {
      return PermissionStatus.denied;
    }
  }

  /// طلب إذن واحد
  Future<PermissionStatus> requestPermission(Permission permission) async {
    try {
      return await permission.request();
    } catch (e) {
      return PermissionStatus.denied;
    }
  }

  /// طلب جميع الأذونات القياسية دفعة واحدة
  Future<Map<Permission, PermissionStatus>> requestAll() async {
    final standardPermissions = allPermissions
        .where((item) => !item.isSpecialPermission)
        .map((item) => item.permission)
        .toList();
    return await standardPermissions.request();
  }

  /// طلب أذونات فئة معينة
  Future<Map<Permission, PermissionStatus>> requestCategory(String category) async {
    final categoryPermissions = allPermissions
        .where((item) => item.category == category && !item.isSpecialPermission)
        .map((item) => item.permission)
        .toList();
    if (categoryPermissions.isEmpty) return {};
    return await categoryPermissions.request();
  }

  /// فتح إعدادات التطبيق في نظام التشغيل
  Future<bool> openSettings() async {
    return await openAppSettings();
  }
}
