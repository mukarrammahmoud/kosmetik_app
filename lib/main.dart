import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'services/permission_service.dart';
import 'welcome_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const PermissionDemoApp());
}

class PermissionDemoApp extends StatelessWidget {
  const PermissionDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'أذونات الجوال',
      debugShowCheckedModeBanner: false,
      // دعم RTL للغة العربية
      locale: const Locale('ar'),
      builder: (context, child) => Directionality(
        textDirection: TextDirection.rtl,
        child: child!,
      ),
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E88E5),
          brightness: Brightness.light,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E88E5),
          brightness: Brightness.dark,
        ),
      ),
      themeMode: ThemeMode.system,
      home: const PermissionScreen(),
    );
  }
}

class PermissionScreen extends StatefulWidget {
  const PermissionScreen({super.key});

  @override
  State<PermissionScreen> createState() => _PermissionScreenState();
}

class _PermissionScreenState extends State<PermissionScreen>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  final PermissionService _permissionService = PermissionService();

  Map<Permission, PermissionStatus> _statuses = {};
  AndroidVersionInfo? _androidInfo;
  bool _isLoading = true;
  bool _isBulkRequesting = false;

  bool _isRecordingSimulated = false;
  late final AnimationController _waveController;

  List<String> get _categories {
    final seen = <String>{};
    return PermissionService.allPermissions
        .map((p) => p.category)
        .where((c) => seen.add(c))
        .toList();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _loadState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _waveController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _checkAllStatuses();
  }

  Future<void> _loadState() async {
    setState(() => _isLoading = true);
    final info = await _permissionService.getAndroidInfo();
    final statuses = await _permissionService.getAllStatuses();
    if (mounted) {
      setState(() {
        _androidInfo = info;
        _statuses = statuses;
        _isLoading = false;
      });
    }
  }

  Future<void> _checkAllStatuses() async {
    final statuses = await _permissionService.getAllStatuses();
    if (mounted) setState(() => _statuses = statuses);
  }

  PermissionStatus _statusOf(Permission p) =>
      _statuses[p] ?? PermissionStatus.denied;

  int get _grantedCount =>
      _statuses.values.where((s) => s.isGranted).length;

  int get _totalCount => PermissionService.allPermissions.length;

  Future<void> _requestSingle(AppPermissionItem item) async {
    if (_statusOf(item.permission).isPermanentlyDenied || item.isSpecialPermission) {
      _showSettingsPrompt(item.name);
      return;
    }
    final proceed = await _showRationaleDialog(
      title: item.name,
      icon: item.icon,
      iconColor: item.accentColor,
      category: item.category,
      message:
          '${item.description}\n\n'
          'أندرويد: ${item.androidPermissionName}\n'
          'iOS: ${item.iosUsageDescriptionKey}',
    );
    if (proceed != true) return;

    final status = await _permissionService.requestPermission(item.permission);
    if (mounted) {
      setState(() => _statuses[item.permission] = status);
      _showStatusSnack(item.name, status);
    }
  }

  Future<void> _requestCategoryPermissions(String category) async {
    final result = await _permissionService.requestCategory(category);
    if (mounted) {
      setState(() => _statuses.addAll(result));
      final granted = result.values.where((s) => s.isGranted).length;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$category: تم منح $granted من ${result.length} أذونات'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _requestAllPermissions() async {
    setState(() => _isBulkRequesting = true);
    final results = await _permissionService.requestAll();
    if (mounted) {
      setState(() {
        _statuses.addAll(results);
        _isBulkRequesting = false;
      });
      final granted = results.values.where((s) => s.isGranted).length;
      if (granted == results.length) {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => WelcomeScreen(
            grantedCount: _grantedCount,
            totalCount: _totalCount,
          ),
        ));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم منح $granted من ${results.length} أذوناً. بعضها يحتاج تفعيلاً يدوياً من الإعدادات.'),
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'الإعدادات',
              onPressed: _permissionService.openSettings,
            ),
          ),
        );
      }
    }
  }

  void _showStatusSnack(String name, PermissionStatus status) {
    String msg;
    if (status.isGranted) {
      msg = 'تم منح إذن $name ✓';
    } else if (status.isPermanentlyDenied) {
      msg = 'تم رفض $name نهائياً. فعّله من الإعدادات.';
    } else {
      msg = 'تم رفض إذن $name.';
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        action: status.isPermanentlyDenied
            ? SnackBarAction(label: 'الإعدادات', onPressed: _permissionService.openSettings)
            : null,
      ),
    );
  }

  Future<bool?> _showRationaleDialog({
    required String title,
    required IconData icon,
    required Color iconColor,
    required String category,
    required String message,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          icon: Icon(icon, size: 44, color: iconColor),
          title: Column(
            children: [
              Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 17)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(category,
                  style: TextStyle(fontSize: 11, color: iconColor, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          content: Text(message, style: const TextStyle(fontSize: 13, height: 1.5)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('ليس الآن'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('السماح'),
            ),
          ],
        ),
      ),
    );
  }

  void _showSettingsPrompt(String permissionName) {
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          icon: const Icon(Icons.settings_suggest_rounded, size: 44, color: Colors.orange),
          title: Text(permissionName),
          content: const Text(
            'هذا الإذن يتطلب التفعيل اليدوي.\n\n'
            'اضغط على "فتح الإعدادات" وفعّله من قسم الأذونات.',
            style: TextStyle(height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('إلغاء'),
            ),
            FilledButton.icon(
              icon: const Icon(Icons.open_in_new_rounded, size: 16),
              label: const Text('فتح الإعدادات'),
              onPressed: () {
                Navigator.of(ctx).pop();
                _permissionService.openSettings();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAndroidGuideSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.78,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (ctx, scrollController) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: ListView(
              controller: scrollController,
              children: [
                Center(
                  child: Container(
                    width: 40, height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(Icons.android_rounded, color: Colors.green.shade700, size: 28),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'دليل توافق إصدارات أندرويد',
                        style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'كيف تتطور الأذونات عبر إصدارات أندرويد المختلفة:',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
                const Divider(height: 28),
                _buildVersionTile(version: 'أندرويد 5.0–5.1 (API 21–22)', name: 'Lollipop', tagColor: Colors.blueGrey,
                  details: 'تُمنح الأذونات تلقائياً عند التثبيت عبر AndroidManifest. لا تظهر نوافذ وقت التشغيل.'),
                _buildVersionTile(version: 'أندرويد 6.0–9.0 (API 23–28)', name: 'Marshmallow–Pie', tagColor: Colors.teal,
                  details: 'تم تقديم أذونات وقت التشغيل. تظهر نوافذ حوار النظام عند استدعاء request().'),
                _buildVersionTile(version: 'أندرويد 10 (API 29)', name: 'Android Q', tagColor: Colors.indigo,
                  details: 'فصل موقع الخلفية. تم تقديم التخزين المحدود. أضيف منح الموقع لمرة واحدة.'),
                _buildVersionTile(version: 'أندرويد 11 (API 30)', name: 'Android R', tagColor: Colors.purple,
                  details: 'أذونات "هذه المرة فقط". إعادة ضبط تلقائية للتطبيقات غير المستخدمة. تم تقديم MANAGE_EXTERNAL_STORAGE.'),
                _buildVersionTile(version: 'أندرويد 12 و12L (API 31–32)', name: 'Android S', tagColor: Colors.deepOrange,
                  details: 'يجب طلب الموقع الدقيق والتقريبي معاً. تم تقسيم أذونات البلوتوث: SCAN، CONNECT، ADVERTISE.'),
                _buildVersionTile(version: 'أندرويد 13 (API 33)', name: 'Tiramisu', tagColor: Colors.amber.shade900,
                  details: 'يتطلب POST_NOTIFICATIONS وقت التشغيل. أذونات وسائط دقيقة (صور/فيديو/صوت). تم إضافة NEARBY_WIFI_DEVICES.'),
                _buildVersionTile(version: 'أندرويد 14 (API 34)', name: 'Upside Down Cake', tagColor: Colors.green.shade700,
                  details: 'READ_MEDIA_VISUAL_USER_SELECTED للوصول الجزئي للصور. أنواع خدمات المقدمة الصارمة.'),
                _buildVersionTile(version: 'أندرويد 15+ (API 35+)', name: 'Vanilla Ice Cream+', tagColor: Colors.cyan.shade800,
                  details: 'بيئة خصوصية محسّنة، صفحات ذاكرة 16KB، وقيود محسّنة على خدمات الخلفية ومستشعرات الصحة.'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVersionTile({
    required String version,
    required String name,
    required String details,
    required Color tagColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: tagColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(name,
                    style: TextStyle(color: tagColor, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(version,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5))),
              ],
            ),
            const SizedBox(height: 6),
            Text(details,
              style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant, height: 1.4)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final allGranted = _grantedCount == _totalCount && _totalCount > 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('أذونات الجوال', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline_rounded),
            tooltip: 'دليل توافق أندرويد',
            onPressed: _showAndroidGuideSheet,
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'تحديث الحالة',
            onPressed: _loadState,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadState,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // ── معلومات النظام ───────────────────────────────────
                  _buildSystemInfoCard(colorScheme),
                  const SizedBox(height: 14),

                  // ── ملخص التقدم ──────────────────────────────────────
                  _buildProgressCard(colorScheme),
                  const SizedBox(height: 18),

                  // ── أزرار الإجراءات ──────────────────────────────────
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: _isBulkRequesting
                        ? const SizedBox(
                            width: 18, height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.security_rounded),
                    label: Text(
                      _isBulkRequesting ? 'جارٍ الطلب...' : 'طلب جميع الأذونات',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    onPressed: _isBulkRequesting ? null : _requestAllPermissions,
                  ),
                  const SizedBox(height: 8),

                  if (allGranted) ...[
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.green.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.celebration_rounded),
                      label: const Text(
                        'تم المنح! عرض الملخص',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                      onPressed: () {
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (context) => WelcomeScreen(
                            grantedCount: _grantedCount,
                            totalCount: _totalCount,
                          ),
                        ));
                      },
                    ),
                    const SizedBox(height: 8),
                  ],

                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.settings_rounded),
                    label: const Text('فتح إعدادات التطبيق'),
                    onPressed: _permissionService.openSettings,
                  ),
                  const SizedBox(height: 26),

                  // ── الأذونات حسب الفئة ───────────────────────────────
                  for (final category in _categories) ...[
                    _buildCategoryHeader(category, colorScheme),
                    const SizedBox(height: 10),
                    for (final item in PermissionService.allPermissions
                        .where((p) => p.category == category)) ...[
                      _buildPermissionCard(item, colorScheme),
                      const SizedBox(height: 10),
                    ],
                    const SizedBox(height: 14),
                  ],

                  Center(
                    child: TextButton.icon(
                      onPressed: _showAndroidGuideSheet,
                      icon: const Icon(Icons.help_outline_rounded, size: 16),
                      label: const Text(
                        'عرض دليل توافق أندرويد',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
    );
  }

  // ─────────────────────── بطاقة معلومات النظام ────────────────────────────
  Widget _buildSystemInfoCard(ColorScheme colorScheme) {
    final info = _androidInfo;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.android_rounded, color: Colors.green.shade600, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  info != null
                      ? 'أندرويد ${info.release} (API ${info.sdkInt}) • ${info.deviceModel}'
                      : 'النظام والجهاز',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                ),
              ),
              InkWell(
                onTap: _showAndroidGuideSheet,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  child: Row(
                    children: [
                      Text('الدليل',
                        style: TextStyle(fontSize: 12, color: colorScheme.primary, fontWeight: FontWeight.w600)),
                      Icon(Icons.chevron_left_rounded, size: 16, color: colorScheme.primary),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (info != null) ...[
            const SizedBox(height: 6),
            Text(
              info.permissionBehaviorDescription,
              style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant, height: 1.4),
            ),
          ],
        ],
      ),
    );
  }

  // ─────────────────────── بطاقة ملخص التقدم ───────────────────────────────
  Widget _buildProgressCard(ColorScheme colorScheme) {
    final progress = _totalCount > 0 ? _grantedCount / _totalCount : 0.0;
    final color = progress == 1.0
        ? Colors.green
        : progress >= 0.5
            ? Colors.orange
            : colorScheme.primary;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.shield_rounded, color: color, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'تم منح $_grantedCount من $_totalCount إذناً',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
              Text(
                '${(progress * 100).round()}%',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: colorScheme.outlineVariant.withValues(alpha: 0.3),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _grantedCount == _totalCount
                ? 'جميع أذونات الجوال مفعّلة. تطبيقك يتمتع بوصول كامل إلى الجهاز.'
                : 'اطلب الأذونات المتبقية أدناه لفتح جميع إمكانيات التطبيق.',
            style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant, height: 1.4),
          ),
        ],
      ),
    );
  }

  // ─────────────────────── رأس الفئة ───────────────────────────────────────
  Widget _buildCategoryHeader(String category, ColorScheme colorScheme) {
    final categoryItems = PermissionService.allPermissions
        .where((p) => p.category == category).toList();
    final grantedInCategory = categoryItems
        .where((p) => _statusOf(p.permission).isGranted).length;
    final allGranted = grantedInCategory == categoryItems.length;

    return Row(
      children: [
        Expanded(
          child: Text(
            category,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
          ),
        ),
        Text(
          '$grantedInCategory/${categoryItems.length}',
          style: TextStyle(
            fontSize: 12, fontWeight: FontWeight.w600,
            color: allGranted ? Colors.green.shade700 : colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: 8),
        if (!allGranted)
          TextButton(
            style: TextButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            ),
            onPressed: () => _requestCategoryPermissions(category),
            child: const Text('طلب الكل', style: TextStyle(fontSize: 12)),
          )
        else
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle_rounded, size: 13, color: Colors.green.shade700),
                const SizedBox(width: 4),
                Text('مفعّلة',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.green.shade700)),
              ],
            ),
          ),
      ],
    );
  }

  // ─────────────────────── بطاقة الإذن ─────────────────────────────────────
  Widget _buildPermissionCard(AppPermissionItem item, ColorScheme colorScheme) {
    final status = _statusOf(item.permission);
    final isGranted = status.isGranted;
    final isPermanentlyDenied = status.isPermanentlyDenied;
    final isSpecial = item.isSpecialPermission;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isGranted
              ? Colors.green.withValues(alpha: 0.4)
              : isPermanentlyDenied
                  ? Colors.red.withValues(alpha: 0.3)
                  : colorScheme.outlineVariant.withValues(alpha: 0.5),
          width: isGranted ? 1.5 : 1.0,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: item.accentColor.withValues(alpha: 0.12),
                  child: Icon(item.icon, color: item.accentColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(item.name,
                              style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold)),
                          ),
                          if (isSpecial)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.orange.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Text('خاص',
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.orange.shade800)),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      _buildStatusChip(status),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              item.description,
              style: TextStyle(fontSize: 12.5, color: colorScheme.onSurfaceVariant, height: 1.4),
            ),
            const SizedBox(height: 5),
            Row(
              children: [
                Icon(Icons.android_rounded, size: 11,
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.55)),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    item.androidPermissionName,
                    style: TextStyle(fontSize: 10.5,
                      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.65)),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                if (!isGranted)
                  Expanded(
                    child: FilledButton.tonalIcon(
                      style: FilledButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      icon: Icon(
                        isPermanentlyDenied || isSpecial
                            ? Icons.settings_rounded
                            : Icons.check_circle_outline_rounded,
                        size: 16,
                      ),
                      label: Text(
                        isPermanentlyDenied || isSpecial ? 'فتح الإعدادات' : 'طلب الإذن',
                        style: const TextStyle(fontSize: 13),
                      ),
                      onPressed: () => _requestSingle(item),
                    ),
                  ),
                if (isGranted) ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        side: BorderSide(color: Colors.green.withValues(alpha: 0.5)),
                      ),
                      icon: const Icon(Icons.verified_rounded, color: Colors.green, size: 16),
                      label: const Text('نشط', style: TextStyle(fontSize: 13, color: Colors.green)),
                      onPressed: null,
                    ),
                  ),
                  const SizedBox(width: 6),
                  IconButton(
                    icon: const Icon(Icons.settings_outlined, size: 18),
                    tooltip: 'إدارة في الإعدادات',
                    visualDensity: VisualDensity.compact,
                    onPressed: _permissionService.openSettings,
                  ),
                ],
              ],
            ),
            if (item.id == 'microphone' && isGranted) ...[
              const SizedBox(height: 10),
              _buildVoiceTestWidget(colorScheme),
            ],
          ],
        ),
      ),
    );
  }

  // ─────────────────────── شريحة الحالة ────────────────────────────────────
  Widget _buildStatusChip(PermissionStatus status) {
    Color bg; Color fg; String label; IconData icon;

    if (status.isGranted) {
      bg = Colors.green.withValues(alpha: 0.15); fg = Colors.green.shade700;
      label = 'ممنوح'; icon = Icons.check_circle_rounded;
    } else if (status.isPermanentlyDenied) {
      bg = Colors.red.withValues(alpha: 0.15); fg = Colors.red.shade700;
      label = 'محظور نهائياً'; icon = Icons.block_rounded;
    } else if (status.isRestricted) {
      bg = Colors.orange.withValues(alpha: 0.15); fg = Colors.orange.shade800;
      label = 'مقيّد'; icon = Icons.lock_clock_rounded;
    } else if (status.isLimited) {
      bg = Colors.amber.withValues(alpha: 0.15); fg = Colors.amber.shade900;
      label = 'محدود'; icon = Icons.lens_blur_rounded;
    } else {
      bg = Colors.grey.withValues(alpha: 0.18); fg = Colors.grey.shade700;
      label = 'لم يُطلب'; icon = Icons.info_outline_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: fg),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: fg)),
        ],
      ),
    );
  }

  // ─────────────────────── أداة اختبار الميكروفون ──────────────────────────
  Widget _buildVoiceTestWidget(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _isRecordingSimulated ? Icons.record_voice_over_rounded : Icons.mic_none_rounded,
                color: _isRecordingSimulated ? Colors.redAccent : Colors.deepPurpleAccent,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _isRecordingSimulated ? 'جارٍ الاستماع...' : 'الميكروفون جاهز',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  backgroundColor: _isRecordingSimulated ? Colors.red.shade100 : null,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                ),
                onPressed: () {
                  setState(() {
                    _isRecordingSimulated = !_isRecordingSimulated;
                    if (_isRecordingSimulated) {
                      _waveController.repeat(reverse: true);
                    } else {
                      _waveController.stop();
                    }
                  });
                },
                child: Text(
                  _isRecordingSimulated ? 'إيقاف' : 'اختبار',
                  style: TextStyle(fontSize: 11,
                    color: _isRecordingSimulated ? Colors.red.shade800 : null),
                ),
              ),
            ],
          ),
          if (_isRecordingSimulated) ...[
            const SizedBox(height: 10),
            AnimatedBuilder(
              animation: _waveController,
              builder: (ctx, child) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(14, (i) {
                    final h = 5.0 + 18.0 * (0.5 + 0.5 * math.sin(_waveController.value * 2 * math.pi + i * 0.5));
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      width: 3.5, height: h,
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withValues(alpha: 0.4 + 0.6 * _waveController.value),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    );
                  }),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}
