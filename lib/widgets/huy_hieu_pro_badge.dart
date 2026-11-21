import 'dart:math';
import 'package:material_ui/material_ui.dart';

/// Huy hiệu PRO nhỏ dùng cạnh tên người dùng trong header, hồ sơ, v.v.
class HuyHieuProBadge extends StatelessWidget {
  final double fontSize;
  final bool compact;

  const HuyHieuProBadge({
    super.key,
    this.fontSize = 11,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 8,
        vertical: compact ? 2 : 3,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFD700), Color(0xFFFFA000)],
        ),
        borderRadius: BorderRadius.circular(6),
        boxShadow: const [
          BoxShadow(
            color: Color(0x40FFD700),
            blurRadius: 6,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.workspace_premium, size: fontSize + 2, color: Colors.black87),
          if (!compact) const SizedBox(width: 3),
          Text(
            compact ? 'PRO' : 'PRO ⭐',
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

/// Huy hiệu PRO lớn, dùng trong trang chúc mừng hoặc hồ sơ.
class HuyHieuProLon extends StatefulWidget {
  final double size;
  const HuyHieuProLon({super.key, this.size = 100});

  @override
  State<HuyHieuProLon> createState() => _HuyHieuProLonState();
}

class _HuyHieuProLonState extends State<HuyHieuProLon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  late final Animation<double> _glow;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _scale = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
    _glow = Tween<double>(begin: 8, end: 20).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) => Transform.scale(
        scale: _scale.value,
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFFD700), Color(0xFFF57C00), Color(0xFFFFD700)],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xAAFFD700),
                blurRadius: _glow.value,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Icon(
            Icons.workspace_premium,
            size: widget.size * 0.5,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

/// Hiệu ứng confetti nhẹ cho màn hình chúc mừng.
class HieuUngChucMung extends StatefulWidget {
  final Widget child;
  const HieuUngChucMung({super.key, required this.child});

  @override
  State<HieuUngChucMung> createState() => _HieuUngChucMungState();
}

class _HieuUngChucMungState extends State<HieuUngChucMung>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  final _random = Random();
  late final List<_ManhConfetti> _manhList;

  @override
  void initState() {
    super.initState();
    _manhList = List.generate(40, (_) => _ManhConfetti(_random));
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: _ctrl,
              builder: (context, _) => CustomPaint(
                painter: _ConfettiPainter(_ctrl.value, _manhList),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ManhConfetti {
  final double x;      // 0..1
  final double delay;   // 0..0.5
  final double speed;   // 0.6..1.4
  final double size;    // 4..10
  final Color color;
  final double drift;   // -0.3..0.3

  _ManhConfetti(Random r)
      : x = r.nextDouble(),
        delay = r.nextDouble() * 0.3,
        speed = 0.6 + r.nextDouble() * 0.8,
        size = 4 + r.nextDouble() * 6,
        color = [
            const Color(0xFFFFD700),
            const Color(0xFFF57C00),
            const Color(0xFF7B1FA2),
            const Color(0xFF1976D2),
            const Color(0xFF43A047),
            const Color(0xFFE53935),
          ][r.nextInt(6)],
        drift = (r.nextDouble() - 0.5) * 0.6;
}

class _ConfettiPainter extends CustomPainter {
  final double t;
  final List<_ManhConfetti> manhList;

  _ConfettiPainter(this.t, this.manhList);

  @override
  void paint(Canvas canvas, Size size) {
    for (final m in manhList) {
      final localT = ((t - m.delay) / m.speed).clamp(0.0, 1.0);
      if (localT <= 0) continue;
      final opacity = localT < 0.8 ? 1.0 : (1.0 - localT) / 0.2;
      final paint = Paint()..color = m.color.withValues(alpha: opacity * 0.8);
      final dx = m.x * size.width + m.drift * size.width * localT;
      final dy = localT * size.height * 1.2 - m.size;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(dx, dy), width: m.size, height: m.size * 0.6),
          Radius.circular(m.size * 0.15),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.t != t;
}
