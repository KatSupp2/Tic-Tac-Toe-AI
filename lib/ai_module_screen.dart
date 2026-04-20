import 'package:flutter/material.dart';

const Color kBg        = Color(0xFF0F0305);
const Color kBgCard    = Color(0xFF1A0508);
const Color kBgDeep    = Color(0xFF2A0A10);
const Color kBorder    = Color(0xFF6B1A22);
const Color kCrimson   = Color(0xFF8B0000);
const Color kGold      = Color(0xFFC8A800);
const Color kTextLight = Color(0xFFF0E6E6);
const Color kTextMuted = Color(0xFF8A5A5A);
const Color kTextBody  = Color(0xFFC8A0A0);

class _PriorityRule {
  final int tier;
  final String label;
  final String description;
  const _PriorityRule(this.tier, this.label, this.description);
}

const List<_PriorityRule> kPriorityRules = [
  _PriorityRule(1, 'WIN',     'Execute any available winning move immediately.'),
  _PriorityRule(2, 'BLOCK',   "Block the player's potential winning move if no immediate win exists."),
  _PriorityRule(3, 'CENTER',  'Prioritize the center cell — the most strategically valuable position.'),
  _PriorityRule(4, 'CORNER',  'Occupy available corners to create multiple winning opportunities.'),
  _PriorityRule(5, 'FALLBACK','Select any remaining available cell when no better option exists.'),
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
    if (reason.startsWith('WIN'))      return 'WIN';
    if (reason.startsWith('THREAT'))   return 'BLOCK';
    if (reason.startsWith('STRATEGIC') && reason.contains('center')) return 'CENTER';
    if (reason.startsWith('STRATEGIC') && reason.contains('corner')) return 'CORNER';
    return 'FALLBACK';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -1),
            radius: 1.2,
            colors: [Color(0xFF2A0A0F), kBg],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context),
                const SizedBox(height: 20),
                _buildDivider(),
                _buildAiBadge(),
                const SizedBox(height: 16),
                _buildBoardStateRow(),
                const SizedBox(height: 16),
                _buildPriorityRules(),
                const SizedBox(height: 16),
                _buildDecisionTrace(),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Back button
        GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            margin: const EdgeInsets.only(top: 4, right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(border: Border.all(color: kBorder)),
            child: const Text('←',
                style: TextStyle(color: kGold, fontSize: 14)),
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: const BoxDecoration(
                border: Border(left: BorderSide(color: kGold, width: 3)),
              ),
              padding: const EdgeInsets.only(left: 10),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('AI MODULE',
                      style: TextStyle(
                          color: kTextLight,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 4,
                          fontFamily: 'monospace')),
                  SizedBox(height: 2),
                  Text('DECISION ENGINE',
                      style: TextStyle(
                          color: kTextMuted,
                          fontSize: 9,
                          letterSpacing: 3,
                          fontFamily: 'monospace')),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(border: Border.all(color: kBorder)),
              child: const Text('▸ ADVERSARIAL SEARCH',
                  style: TextStyle(
                      color: kGold,
                      fontSize: 8,
                      letterSpacing: 2,
                      fontFamily: 'monospace')),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
        margin: const EdgeInsets.symmetric(vertical: 16),
        height: 1,
        color: kBorder);
  }

  Widget _buildAiBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
          color: kBgDeep, border: Border.all(color: kBorder)),
      child: Row(
        children: [
          _PulseDot(),
          const SizedBox(width: 10),
          const Text('NEURAL ENGINE ACTIVE — EVALUATING BOARD STATE',
              style: TextStyle(
                  color: kGold,
                  fontSize: 9,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace')),
        ],
      ),
    );
  }

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
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: kBgCard, border: Border.all(color: kBorder)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('BOARD STATE'),
          const SizedBox(height: 10),
          _statRow('MOVE COUNT',   moveCount.toString().padLeft(2, '0'), gold: true),
          _statRow('EMPTY CELLS',  _emptyCells.toString().padLeft(2, '0')),
          _statRow('AI LAST CELL', lastAiIndex != null ? _posLabel(lastAiIndex!) : '—', gold: true),
          _statRow('PLAYER MARKS', board.where((c) => c == 'X').length.toString()),
          _statRow('AI MARKS',     board.where((c) => c == 'O').length.toString()),
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
                  fontSize: 9,
                  letterSpacing: 1.5,
                  fontFamily: 'monospace')),
          Text(val,
              style: TextStyle(
                  color: gold ? kGold : kTextLight,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace')),
        ],
      ),
    );
  }

  Widget _buildMiniGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('GRID'),
        const SizedBox(height: 8),
        SizedBox(
          width: 90,
          child: Column(
            children: List.generate(3, (row) {
              return Row(
                children: List.generate(3, (col) {
                  final idx = row * 3 + col;
                  final val = board[idx];
                  return Expanded(
                    child: Container(
                      margin: const EdgeInsets.all(1.5),
                      height: 26,
                      decoration: BoxDecoration(
                        color: kBgCard,
                        border: Border.all(color: kBorder, width: 0.8),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        val == '' ? '·' : val,
                        style: TextStyle(
                          color: val == 'X'
                              ? kCrimson
                              : val == 'O'
                              ? kGold
                              : kBorder,
                          fontSize: val == '' ? 8 : 12,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'monospace',
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

  Widget _buildPriorityRules() {
    return Container(
      decoration: BoxDecoration(
          color: kBgCard, border: Border.all(color: kBorder)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: _sectionLabel('AI PRIORITY RULES'),
          ),
          Container(height: 1, color: kBgDeep),
          ...kPriorityRules.map((rule) => _buildRuleItem(rule)),
        ],
      ),
    );
  }

  Widget _buildRuleItem(_PriorityRule rule) {
    final isActive = _tierOf(lastAiReason) == rule.label;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        border: const Border(bottom: BorderSide(color: kBgDeep)),
        color: isActive ? const Color(0xFF1F0508) : Colors.transparent,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            margin: const EdgeInsets.only(top: 1),
            decoration: BoxDecoration(
              color: isActive ? kCrimson : kBgDeep,
              border: Border.all(color: isActive ? kGold : kBorder),
            ),
            alignment: Alignment.center,
            child: Text('${rule.tier}',
                style: TextStyle(
                    color: isActive ? kGold : kGold,
                    fontSize: 9,
                    fontFamily: 'monospace')),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(rule.label,
                        style: TextStyle(
                            color: isActive ? kGold : kTextMuted,
                            fontSize: 8,
                            letterSpacing: 2,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace')),
                    if (isActive) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 1),
                        decoration:
                        BoxDecoration(border: Border.all(color: kGold)),
                        child: const Text('ACTIVE',
                            style: TextStyle(
                                color: kGold,
                                fontSize: 6,
                                letterSpacing: 1.5,
                                fontFamily: 'monospace')),
                      )
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(rule.description,
                    style: const TextStyle(
                        color: kTextBody,
                        fontSize: 11,
                        height: 1.5,
                        fontFamily: 'monospace')),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDecisionTrace() {
    final tier = _tierOf(lastAiReason);
    final hasData = lastAiReason != null && lastAiIndex != null;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: kBgCard, border: Border.all(color: kBorder)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('LAST DECISION TRACE'),
          const SizedBox(height: 12),
          if (!hasData)
            const Text('— NO MOVE RECORDED YET —',
                style: TextStyle(
                    color: kTextMuted,
                    fontSize: 10,
                    letterSpacing: 2,
                    fontFamily: 'monospace'))
          else ...[
            _traceRow('REASON',       lastAiReason ?? '—'),
            _traceRow('TARGET CELL',  _posLabel(lastAiIndex!), gold: true),
            _traceRow('STRATEGY TIER', tier,
                color: tier == 'WIN'
                    ? kGold
                    : tier == 'BLOCK'
                    ? const Color(0xFFFF6060)
                    : kTextLight),
          ],
        ],
      ),
    );
  }

  Widget _traceRow(String label, String val,
      {bool gold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label,
                style: const TextStyle(
                    color: kTextMuted,
                    fontSize: 9,
                    letterSpacing: 1.5,
                    fontFamily: 'monospace')),
          ),
          Expanded(
            child: Text(val,
                style: TextStyle(
                    color: color ?? (gold ? kGold : kTextLight),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace')),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(text,
        style: const TextStyle(
            color: kTextMuted,
            fontSize: 8,
            letterSpacing: 2.5,
            fontFamily: 'monospace'));
  }
}

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
    _anim = Tween<double>(begin: 0.2, end: 1.0).animate(_ctrl);
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