import 'package:flutter/material.dart';

class WelcomeScreen extends StatelessWidget {
  final int grantedCount;
  final int totalCount;

  const WelcomeScreen({
    super.key,
    this.grantedCount = 0,
    this.totalCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('الأذونات الممنوحة', style: TextStyle(fontWeight: FontWeight.bold)),
          leading: IconButton(
            icon: const Icon(Icons.arrow_forward_rounded),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
            children: [
              const SizedBox(height: 12),

              Center(
                child: Container(
                  width: 124,
                  height: 124,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFD81B60).withValues(alpha: 0.20),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.asset(
                      'images/logo.png',
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.image_not_supported_rounded,
                        size: 44,
                        color: Color(0xFFD81B60),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Text(
                'الأذونات مفعّلة!',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                totalCount > 0
                    ? 'تم تفعيل $grantedCount من أصل $totalCount إذناً للجوال. تطبيقك يملك الآن صلاحية الوصول إلى الأجهزة والوسائط والمستشعرات والاتصالات.'
                    : 'تم تفعيل جميع الأذونات المطلوبة. جهازك مجهّز بالكامل لاستخدام جميع إمكانيات التطبيق.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: colorScheme.onSurfaceVariant, height: 1.5),
              ),
              const SizedBox(height: 28),

              const Text(
                'الإمكانيات المفعّلة',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              _buildFeatureTile(
                context: context,
                icon: Icons.location_on_rounded,
                iconColor: const Color(0xFF1E88E5),
                title: 'الموقع الدقيق والتقريبي',
                subtitle: 'الملاحة عبر GPS، الأسوار الجغرافية، وكشف القرب جاهزة.',
              ),
              const SizedBox(height: 10),

              _buildFeatureTile(
                context: context,
                icon: Icons.camera_alt_rounded,
                iconColor: const Color(0xFF8E24AA),
                title: 'الكاميرا وماسح QR',
                subtitle: 'التقاط الصور، مسح الباركود، وتسجيل الفيديو مفعّلة.',
              ),
              const SizedBox(height: 10),

              _buildFeatureTile(
                context: context,
                icon: Icons.mic_rounded,
                iconColor: const Color(0xFFD81B60),
                title: 'الصوت والميكروفون',
                subtitle: 'التسجيل الصوتي والأوامر الصوتية والتعرف على الكلام مفعّلة.',
              ),
              const SizedBox(height: 10),

              _buildFeatureTile(
                context: context,
                icon: Icons.photo_library_rounded,
                iconColor: const Color(0xFFFB8C00),
                title: 'الصور والفيديو والملفات الصوتية',
                subtitle: 'الوصول إلى الصور والفيديو والموسيقى من ألبوم الجهاز.',
              ),
              const SizedBox(height: 10),

              _buildFeatureTile(
                context: context,
                icon: Icons.contacts_rounded,
                iconColor: const Color(0xFF43A047),
                title: 'جهات الاتصال والتقويم',
                subtitle: 'مزامنة قاعدة العناوين وفعاليات التقويم والتذكيرات.',
              ),
              const SizedBox(height: 10),

              _buildFeatureTile(
                context: context,
                icon: Icons.notifications_active_rounded,
                iconColor: const Color(0xFFE91E63),
                title: 'الإشعارات الفورية',
                subtitle: 'التنبيهات الحرجة والإشعارات السريعة والشارات مفعّلة.',
              ),
              const SizedBox(height: 10),

              _buildFeatureTile(
                context: context,
                icon: Icons.bluetooth_rounded,
                iconColor: const Color(0xFF0288D1),
                title: 'البلوتوث والاتصال اللاسلكي',
                subtitle: 'اقتران الأجهزة الطرفية، المسح، وWi-Fi القريب مفعّلة.',
              ),
              const SizedBox(height: 10),

              _buildFeatureTile(
                context: context,
                icon: Icons.sensors_rounded,
                iconColor: const Color(0xFF7E57C2),
                title: 'المستشعرات والنشاط البدني',
                subtitle: 'القياسات الحيوية وعداد الخطوات والتعرف على النشاط.',
              ),
              const SizedBox(height: 28),

              FilledButton.icon(
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.arrow_back_rounded),
                label: const Text(
                  'استكشاف ميزات التطبيق',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('جميع أذونات الجوال مهيّأة وجاهزة للعمل!'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),

              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.tune_rounded),
                label: const Text('العودة إلى لوحة الأذونات'),
                onPressed: () => Navigator.of(context).pop(),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureTile({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: iconColor.withValues(alpha: 0.12),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                  style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(subtitle,
                  style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant, height: 1.3)),
              ],
            ),
          ),
          const Icon(Icons.check_circle_rounded, color: Colors.green, size: 20),
        ],
      ),
    );
  }
}
