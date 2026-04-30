import 'package:flutter/material.dart';
import 'main.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fadeBadge;
  late final Animation<double> _fadeTitle;
  late final Animation<double> _fadeFeatures;
  late final Animation<double> _fadeButtons;
  late final Animation<Offset> _slideTitle;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..forward();

    _fadeBadge = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.0, 0.30, curve: Curves.easeOut),
    );
    _fadeTitle = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.15, 0.50, curve: Curves.easeOut),
    );
    _slideTitle = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.15, 0.55, curve: Curves.easeOut),
    ));
    _fadeFeatures = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.40, 0.70, curve: Curves.easeOut),
    );
    _fadeButtons = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.65, 1.0, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _startSinglePlayer() =>
      Navigator.of(context).pushReplacementNamed('/game');

  void _startMultiplayer() =>
      Navigator.of(context).pushReplacementNamed('/game-multi');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: Stack(
        children: [
          // ── Decorative circles ─────────────────────────────────────────────
          Positioned(
            top: -90, left: -70,
            child: Container(
              width: 280, height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: kGoldLight.withOpacity(0.55),
              ),
            ),
          ),
          Positioned(
            bottom: -100, right: -60,
            child: Container(
              width: 240, height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFE8DDD5).withOpacity(0.45),
              ),
            ),
          ),
          Positioned(
            top: 200, right: -40,
            child: Container(
              width: 120, height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: kGoldLight.withOpacity(0.3),
              ),
            ),
          ),

          // ── Content ────────────────────────────────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // ── Top badge ──────────────────────────────────────────────
                  FadeTransition(
                    opacity: _fadeBadge,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: kNavy,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'CCS · DSELC03C PROJECT',
                        style: TextStyle(
                          color: kGoldLight,
                          fontSize: 9,
                          letterSpacing: 2.5,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ),

                  const Spacer(),

                  // ── Logo mark ──────────────────────────────────────────────
                  FadeTransition(
                    opacity: _fadeTitle,
                    child: Container(
                      width: 58, height: 58,
                      decoration: BoxDecoration(
                        color: kNavy,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: kNavy.withOpacity(0.2),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.grid_3x3_rounded,
                        color: kGoldLight,
                        size: 28,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── Title block ────────────────────────────────────────────
                  SlideTransition(
                    position: _slideTitle,
                    child: FadeTransition(
                      opacity: _fadeTitle,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Tic-Tac-Toe',
                            style: TextStyle(
                              color: kTextLight,
                              fontSize: 38,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -1,
                              height: 1.05,
                            ),
                          ),
                          Row(
                            children: const [
                              Text(
                                'AI ',
                                style: TextStyle(
                                  color: kGold,
                                  fontSize: 38,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -1,
                                  height: 1.05,
                                ),
                              ),
                              Text(
                                'System',
                                style: TextStyle(
                                  color: kTextLight,
                                  fontSize: 38,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -1,
                                  height: 1.05,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // ── Thin divider ───────────────────────────────────────────
                  FadeTransition(
                    opacity: _fadeFeatures,
                    child: Container(height: 1, color: kBorder),
                  ),

                  const SizedBox(height: 28),

                  // ── Feature list ───────────────────────────────────────────
                  FadeTransition(
                    opacity: _fadeFeatures,
                    child: const Column(
                      children: [
                        _FeatureRow(label: 'AI-Powered Decision Engine'),
                        SizedBox(height: 10),
                        _FeatureRow(label: 'Real-Time Move Analysis'),
                        SizedBox(height: 10),
                        _FeatureRow(label: 'Priority-Based Strategy Rules'),
                        SizedBox(height: 10),
                        _FeatureRow(label: 'Full Move Log & Trace'),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // ── Mode Selection Buttons ─────────────────────────────────
                  FadeTransition(
                    opacity: _fadeButtons,
                    child: Column(
                      children: [
                        const Center(
                          child: Text(
                            'SELECT MODE',
                            style: TextStyle(
                              color: kTextMuted,
                              fontSize: 10,
                              letterSpacing: 2.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        Row(
                          children: [
                            Expanded(
                              child: _ModeCard(
                                icon: Icons.smart_toy_rounded,
                                title: 'Single\nPlayer',
                                subtitle: 'vs AI',
                                onTap: _startSinglePlayer,
                                isPrimary: true,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _ModeCard(
                                icon: Icons.people_rounded,
                                title: 'Multi-\nplayer',
                                subtitle: 'Pass & Play',
                                onTap: _startMultiplayer,
                                isPrimary: false,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Credits ────────────────────────────────────────────────
                  FadeTransition(
                    opacity: _fadeButtons,
                    child: const Center(
                      child: Text(
                        'Cawaling · Paculanan · Paras · Riman',
                        style: TextStyle(
                          color: kTextMuted,
                          fontSize: 9,
                          letterSpacing: 1.5,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Mode Card ─────────────────────────────────────────────────────────────────
class _ModeCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isPrimary;

  const _ModeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.isPrimary,
  });

  @override
  State<_ModeCard> createState() => _ModeCardState();
}

class _ModeCardState extends State<_ModeCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
          decoration: BoxDecoration(
            color: widget.isPrimary ? kNavy : kBgCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: widget.isPrimary ? kNavy : kBorder,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.isPrimary
                    ? kNavy.withOpacity(0.25)
                    : kNavy.withOpacity(0.06),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: widget.isPrimary
                      ? kGoldLight.withOpacity(0.15)
                      : kGoldLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  widget.icon,
                  size: 20,
                  color: widget.isPrimary ? kGoldLight : kGold,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                widget.title,
                style: TextStyle(
                  color: widget.isPrimary ? Colors.white : kTextLight,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.subtitle,
                style: TextStyle(
                  color: widget.isPrimary
                      ? kGoldLight.withOpacity(0.7)
                      : kTextMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Feature Row ───────────────────────────────────────────────────────────────
class _FeatureRow extends StatelessWidget {
  final String label;
  const _FeatureRow({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 6, height: 6,
          decoration: const BoxDecoration(
            color: kGold,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 14),
        Text(
          label,
          style: const TextStyle(
            color: kTextBody,
            fontSize: 13,
            height: 1.4,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.1,
          ),
        ),
      ],
    );
  }
}