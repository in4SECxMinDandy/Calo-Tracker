// Welcome Screen - App Entry Point
// Allows users to choose between Online (Community) or Offline mode
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../services/storage_service.dart';
import '../auth/login_screen.dart';
import '../home/home_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );

    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      _slideController.forward();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _continueOffline() async {
    await StorageService.setOnlineMode(false);
    if (mounted) {
      Navigator.of(
        context,
      ).pushReplacement(CupertinoPageRoute(builder: (_) => const HomeScreen()));
    }
  }

  void _continueOnline() {
    Navigator.of(
      context,
    ).push(CupertinoPageRoute(builder: (_) => const LoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors:
                isDark
                    ? [
                      const Color(0xFF1a1a2e),
                      const Color(0xFF16213e),
                      const Color(0xFF0f3460),
                    ]
                    : [
                      const Color(0xFFe8f5e9),
                      const Color(0xFFc8e6c9),
                      const Color(0xFFa5d6a7),
                    ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Top decorative circles
              Expanded(
                flex: 4,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: _buildLogoSection(isDark, size),
                ),
              ),

              // Bottom content
              Expanded(
                flex: 5,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: _buildContentSection(isDark),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogoSection(bool isDark, Size size) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Decorative circles
        Positioned(
          top: -50,
          right: -80,
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: (isDark ? Colors.green : Colors.white).withValues(
                alpha: 0.1,
              ),
            ),
          ),
        ),
        Positioned(
          top: 60,
          left: -40,
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: (isDark ? Colors.teal : Colors.green).withValues(
                alpha: 0.15,
              ),
            ),
          ),
        ),

        // Main Logo
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated rings logo
            SizedBox(
              width: 140,
              height: 140,
              child: CustomPaint(
                painter: _LogoRingsPainter(isDark: isDark),
                child: Center(
                  child: Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF4CAF50),
                          const Color(0xFF66BB6A),
                        ],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF4CAF50).withValues(alpha: 0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(
                      CupertinoIcons.leaf_arrow_circlepath,
                      color: Colors.white,
                      size: 36,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'CaloTracker',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF2E7D32),
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Sức khỏe trong tầm tay',
              style: TextStyle(
                fontSize: 16,
                color: isDark ? Colors.white60 : const Color(0xFF558B2F),
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildContentSection(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          children: [
          // Handle indicator
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? Colors.white24 : Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 28),

          Text(
            'Chào mừng bạn!',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Chọn cách bạn muốn sử dụng ứng dụng',
            style: TextStyle(
              fontSize: 15,
              color: isDark ? Colors.white54 : Colors.black54,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // Online Mode Button
          _buildModeButton(
            isDark: isDark,
            icon: CupertinoIcons.globe,
            title: 'Chế độ Online',
            subtitle: 'Đăng nhập • Cộng đồng • Thử thách',
            gradient: const [Color(0xFF667eea), Color(0xFF764ba2)],
            onTap: _continueOnline,
          ),
          const SizedBox(height: 16),

          // Offline Mode Button
          _buildModeButton(
            isDark: isDark,
            icon: CupertinoIcons.device_phone_portrait,
            title: 'Chế độ Offline',
            subtitle: 'Theo dõi cá nhân • Không cần đăng nhập',
            gradient: const [Color(0xFF11998e), Color(0xFF38ef7d)],
            onTap: _continueOffline,
          ),

          const SizedBox(height: 20),

          // Terms text
          Text(
            'Bằng việc tiếp tục, bạn đồng ý với\nĐiều khoản sử dụng và Chính sách bảo mật',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white38 : Colors.black38,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
        ],
      ),
      ),
    );
  }

  Widget _buildModeButton({
    required bool isDark,
    required IconData icon,
    required String title,
    required String subtitle,
    required List<Color> gradient,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: gradient),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: gradient.first.withValues(alpha: 0.4),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: Colors.white, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              CupertinoIcons.chevron_right,
              color: Colors.white70,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

// Custom painter for animated rings logo
class _LogoRingsPainter extends CustomPainter {
  final bool isDark;

  _LogoRingsPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final colors = [
      const Color(0xFF4CAF50),
      const Color(0xFF66BB6A),
      const Color(0xFF81C784),
    ];

    for (int i = 2; i >= 0; i--) {
      final radius = 30.0 + (i * 18);
      final paint =
          Paint()
            ..color = colors[i].withValues(alpha: 0.3 - (i * 0.08))
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3;

      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
