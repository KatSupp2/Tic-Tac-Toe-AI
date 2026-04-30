import 'package:flutter/material.dart';


const Color kBg        = Color(0xFFFAF8F5);
const Color kBgCard    = Color(0xFFFFFFFF);
const Color kBgDeep    = Color(0xFFF2EDE9);
const Color kBorder    = Color(0xFFE0D5CF);
const Color kNavy      = Color(0xFF1C1C2E);
const Color kGold      = Color(0xFFB8960C);
const Color kGoldLight = Color(0xFFF5EDD0);
const Color kTextDark  = Color(0xFF1C1C2E);
const Color kTextMuted = Color(0xFF9E8E8E);
const Color kTextBody  = Color(0xFF5C4F4F);
const Color kAccentRed = Color(0xFFC0392B);

class _PriorityRule {
  final int tier;
  final String label;
  final String description;
  const _PriorityRule(this.tier, this.label, this.description);
}

const List<_PriorityRule> kPriorityRules = [
  _PriorityRule(1, 'WIN',      'Execute any available winning move immediately.'),
  _PriorityRule(2, 'BLOCK',    "Block the player's potential winning move if no immediate win exists."),
  _PriorityRule(3, 'CENTER',   'Prioritize the center cell — the most strategically valuable position.'),
  _PriorityRule(4, 'CORNER',   'Occupy available corners to create multiple winning opportunities.'),
  _PriorityRule(5, 'FALLBACK', 'Select any remaining available cell when no better option exists.'),
];

class AiModuleScreen extends StatelessWidget {
  final List<String> board;
  final int? lastAiIndex;
  final String? lastAiReason;
  final int moveCount;

  const AiModuleScreen({
    super.key,
    required this.board,
    this.lastAiIndex,
    this.lastAiReason,
    required this.moveCount,
  });

  String _posLabel(int i) {
    final row = i ~/ 3 + 1;
    final col = i % 3 + 1;
    return 'R${row}C$col';
  }

  int get _emptyCells => board.where((c) => c == '').length;

  String _tierOf(String? reason) {
    if (reason == null) return '—';
    if (reason.startsWith('WIN'))                                      return 'WIN';
    if (reason.startsWith('THREAT'))                                   return 'BLOCK';
    if (reason.startsWith('STRATEGIC') && reason.contains('center'))  return 'CENTER';
    if (reason.startsWith('STRATEGIC') && reason.contains('corner'))  return 'CORNER';
    return 'FALLBACK';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: Stack(
        children: [
          // Subtle warm radial backdrop
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(-0.8, -0.9),
                  radius: 1.0,
                  colors: [Color(0xFFFFF8ED), kBg],
                ),
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context),
                  const SizedBox(height: 20),
                  _buildStatusBadge(),
                  const SizedBox(height: 18),
                  _buildBoardStateRow(),
                  const SizedBox(height: 18),
                  _buildPriorityRules(),
                  const SizedBox(height: 18),
                  _buildDecisionTrace(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Back button
        GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            margin: const EdgeInsets.only(right: 14),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: kBgCard,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: kBorder),
              boxShadow: [
                BoxShadow(
                  color: kNavy.withOpacity(0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded,
                color: kNavy, size: 16),
          ),
        ),

        // Icon badge
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: kNavy,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: kNavy.withOpacity(0.2),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: const Icon(Icons.memory_rounded,
              color: Color(0xFFF5EDD0), size: 22),
        ),
        const SizedBox(width: 12),

        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'AI Module',
              style: TextStyle(
                color: kTextDark,
                fontSize: 20,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Decision Engine',
              style: TextStyle(
                color: kTextMuted,
                fontSize: 12,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),

        const Spacer(),

        // Adversarial chip
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: kGoldLight,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: kGold.withOpacity(0.4)),
          ),
          child: Text(
            'Adversarial',
            style: TextStyle(
              color: kGold,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ],
    );
  }

  // ── Status Badge ───────────────────────────────────────────────────────────

  Widget _buildStatusBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: kBgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kBorder),
        boxShadow: [
          BoxShadow(
            color: kNavy.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          _PulseDot(),
          const SizedBox(width: 10),
          const Text(
            'Neural engine active — evaluating board state',
            style: TextStyle(
              color: kTextBody,
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }

  // ── Board State Row ────────────────────────────────────────────────────────

  Widget _buildBoardStateRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _buildBoardStats()),
        const SizedBox(width: 14),
        _buildMiniGrid(),
      ],
    );
  }

  Widget _buildBoardStats() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('Board State'),
          const SizedBox(height: 12),
          _statRow('Move count',   moveCount.toString().padLeft(2, '0'), gold: true),
          _statRow('Empty cells',  _emptyCells.toString().padLeft(2, '0')),
          _statRow('AI last cell', lastAiIndex != null ? _posLabel(lastAiIndex!) : '—', gold: true),
          _statRow('Player marks', board.where((c) => c == 'X').length.toString()),
          _statRow('AI marks',     board.where((c) => c == 'O').length.toString()),
        ],
      ),
    );
  }

  Widget _statRow(String label, String val, {bool gold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  color: kTextMuted,
                  fontSize: 12,
                  letterSpacing: 0.1)),
          Text(val,
              style: TextStyle(
                  color: gold ? kGold : kTextDark,
                  fontSize: 14,
                  fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _buildMiniGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('Grid'),
        const SizedBox(height: 10),
        Container(
          width: 96,
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: kBgCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: kBorder),
            boxShadow: [
              BoxShadow(
                color: kNavy.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            children: List.generate(3, (row) {
              return Row(
                children: List.generate(3, (col) {
                  final idx = row * 3 + col;
                  final val = board[idx];
                  return Expanded(
                    child: Container(
                      margin: const EdgeInsets.all(2),
                      height: 24,
                      decoration: BoxDecoration(
                        color: val == '' ? kBgDeep : kGoldLight.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(
                          color: val == '' ? kBorder : kGold.withOpacity(0.4),
                          width: 0.8,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        val == '' ? '·' : val,
                        style: TextStyle(
                          color: val == 'X'
                              ? kAccentRed
                              : val == 'O'
                              ? kGold
                              : kBorder,
                          fontSize: val == '' ? 8 : 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  );
                }),
              );
            }),
          ),
        ),
      ],
    );
  }

  // ── Priority Rules ─────────────────────────────────────────────────────────

  Widget _buildPriorityRules() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('AI Priority Rules'),
          const SizedBox(height: 14),
          ...kPriorityRules.map((rule) => _buildRuleItem(rule)),
        ],
      ),
    );
  }

  Widget _buildRuleItem(_PriorityRule rule) {
    final isActive = _tierOf(lastAiReason) == rule.label;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isActive ? kGoldLight : kBgDeep,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isActive ? kGold.withOpacity(0.5) : kBorder,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tier badge
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: isActive ? kGold : kBgCard,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isActive ? kGold : kBorder,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              '${rule.tier}',
              style: TextStyle(
                color: isActive ? Colors.white : kTextMuted,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      rule.label,
                      style: TextStyle(
                        color: isActive ? kGold : kTextBody,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                    if (isActive) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: kGold,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Active',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  rule.description,
                  style: const TextStyle(
                    color: kTextMuted,
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Decision Trace ─────────────────────────────────────────────────────────

  Widget _buildDecisionTrace() {
    final tier = _tierOf(lastAiReason);
    final hasData = lastAiReason != null && lastAiIndex != null;

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('Last Decision Trace'),
          const SizedBox(height: 14),
          if (!hasData)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              alignment: Alignment.center,
              child: Text(
                'No move recorded yet',
                style: TextStyle(
                  color: kTextMuted,
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                ),
              ),
            )
          else ...[
            _traceRow('Reason',         lastAiReason ?? '—'),
            _traceRow('Target cell',    _posLabel(lastAiIndex!), gold: true),
            _traceRow('Strategy tier',  tier,
                color: tier == 'WIN'
                    ? kGold
                    : tier == 'BLOCK'
                    ? kAccentRed
                    : kTextDark),
          ],
        ],
      ),
    );
  }

  Widget _traceRow(String label, String val,
      {bool gold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label,
                style: const TextStyle(
                    color: kTextMuted,
                    fontSize: 12,
                    letterSpacing: 0.1)),
          ),
          Expanded(
            child: Text(val,
                style: TextStyle(
                    color: color ?? (gold ? kGold : kTextDark),
                    fontSize: 13,
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kBgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kBorder),
        boxShadow: [
          BoxShadow(
            color: kNavy.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: kTextBody,
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
      ),
    );
  }
}

// ── Pulse Dot ─────────────────────────────────────────────────────────────────

class _PulseDot extends StatefulWidget {
  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.25, end: 1.0).animate(
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
    return FadeTransition(
      opacity: _anim,
      child: Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          color: kGold,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}