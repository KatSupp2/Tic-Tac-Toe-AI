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
  late final Animation<double> _fadeTitle;
  late final Animation<double> _fadeSub;
  late final Animation<double> _fadeBtn;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..forward();

    _fadeTitle = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.0, 0.45, curve: Curves.easeOut),
    );
    _fadeSub = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.35, 0.65, curve: Curves.easeOut),
    );
    _fadeBtn = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.60, 1.0, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _enter() {
    Navigator.of(context).pushReplacementNamed('/game');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.4),
            radius: 1.0,
            colors: [Color(0xFF2A0A0F), kBg],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Top badge ───────────────────────────────────────────────
                FadeTransition(
                  opacity: _fadeTitle,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                        border: Border.all(color: kBorder)),
                    child: const Text(
                      'CCS · DSELC03C PROJECT',
                      style: TextStyle(
                        color: kTextMuted,
                        fontSize: 8,
                        letterSpacing: 2.5,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ),

                const Spacer(),

                // ── Title block ─────────────────────────────────────────────
                FadeTransition(
                  opacity: _fadeTitle,
                  child: Container(
                    decoration: const BoxDecoration(
                      border: Border(
                          left: BorderSide(color: kGold, width: 4)),
                    ),
                    padding: const EdgeInsets.only(left: 16),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'TIC-TAC-TOE',
                          style: TextStyle(
                            color: kTextLight,
                            fontSize: 36,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 4,
                            height: 1.1,
                            fontFamily: 'monospace',
                          ),
                        ),
                        Text(
                          'AI SYSTEM',
                          style: TextStyle(
                            color: kGold,
                            fontSize: 36,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 4,
                            height: 1.1,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),


                const SizedBox(height: 32),

                // ── Divider ─────────────────────────────────────────────────
                FadeTransition(
                  opacity: _fadeSub,
                  child: Container(height: 1, color: kBorder),
                ),

                const SizedBox(height: 32),

                // ── Feature list ────────────────────────────────────────────
                FadeTransition(
                  opacity: _fadeSub,
                  child: Column(
                    children: const [
                      _FeatureRow(icon: '◈', label: 'AI-Powered Decision Engine'),
                      SizedBox(height: 12),
                      _FeatureRow(icon: '◈', label: 'Real-Time Move Analysis'),
                      SizedBox(height: 12),
                      _FeatureRow(icon: '◈', label: 'Priority-Based Strategy Rules'),
                      SizedBox(height: 12),
                      _FeatureRow(icon: '◈', label: 'Full Move Log & Trace'),
                    ],
                  ),
                ),

                const Spacer(),

                // ── Enter button ────────────────────────────────────────────
                FadeTransition(
                  opacity: _fadeBtn,
                  child: GestureDetector(
                    onTap: _enter,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: kBgDeep,
                        border: Border.all(color: kGold, width: 1.5),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        '▸  START GAME',
                        style: TextStyle(
                          color: kGold,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 4,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // ── Version tag ─────────────────────────────────────────────
                FadeTransition(
                  opacity: _fadeBtn,
                  child: const Center(
                    child: Text(
                      'Cawaling, Paculanan, Paras, Riman',
                      style: TextStyle(
                        color: kBorder,
                        fontSize: 7,
                        letterSpacing: 2,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Feature Row Widget ────────────────────────────────────────────────────────
class _FeatureRow extends StatelessWidget {
  final String icon;
  final String label;
  const _FeatureRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(icon,
            style: const TextStyle(
                color: kGold, fontSize: 11, fontFamily: 'monospace')),
        const SizedBox(width: 12),
        Text(label,
            style: const TextStyle(
              color: kTextBody,
              fontSize: 12,
              height: 1.4,
              fontFamily: 'monospace',
            )),
      ],
    );
  }
}