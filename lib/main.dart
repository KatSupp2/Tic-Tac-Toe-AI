import 'ai_module_screen.dart';
import 'splash_screen.dart';
import 'login_screen.dart';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const TicTacToeApp());
}

// ── Colors ────────────────────────────────────────────────────────────────────
const Color kBg        = Color(0xFF0F0305);
const Color kBgCard    = Color(0xFF1A0508);
const Color kBgDeep    = Color(0xFF2A0A10);
const Color kBorder    = Color(0xFF6B1A22);
const Color kCrimson   = Color(0xFF8B0000);
const Color kGold      = Color(0xFFC8A800);
const Color kTextLight = Color(0xFFF0E6E6);
const Color kTextMuted = Color(0xFF8A5A5A);
const Color kTextBody  = Color(0xFFC8A0A0);
const Color kWin       = Color(0xFFC8A800);
const Color kLose      = Color(0xFFFF6060);

// ── AI Logic ──────────────────────────────────────────────────────────────────
const List<List<int>> kWins = [
  [0,1,2],[3,4,5],[6,7,8],
  [0,3,6],[1,4,7],[2,5,8],
  [0,4,8],[2,4,6],
];

int? findWinningMove(List<String> board, String mark) {
  for (final line in kWins) {
    final cells = line.map((i) => board[i]).toList();
    if (cells.where((c) => c == mark).length == 2 &&
        cells.contains('')) {
      return line[cells.indexOf('')];
    }
  }
  return null;
}

class AiResult {
  final int index;
  final String reason;
  const AiResult(this.index, this.reason);
}

AiResult aiMove(List<String> board) {
  final rng = Random();
  // 1. Win
  int? m = findWinningMove(board, 'O');
  if (m != null) return AiResult(m, 'WIN DETECTED — executing winning move');
  // 2. Block
  m = findWinningMove(board, 'X');
  if (m != null) return AiResult(m, 'THREAT DETECTED — blocking player');
  // 3. Center
  if (board[4] == '') return const AiResult(4, 'STRATEGIC — claiming center');
  // 4. Corners
  final corners = [0,2,6,8].where((i) => board[i] == '').toList();
  if (corners.isNotEmpty) {
    return AiResult(corners[rng.nextInt(corners.length)], 'STRATEGIC — occupying corner');
  }
  // 5. Any
  final empty = List.generate(9, (i) => i).where((i) => board[i] == '').toList();
  return AiResult(empty[rng.nextInt(empty.length)], 'FALLBACK — selecting available cell');
}

String? checkWinner(List<String> board) {
  for (final line in kWins) {
    final a = board[line[0]], b = board[line[1]], c = board[line[2]];
    if (a != '' && a == b && b == c) return a;
  }
  return null;
}

Set<int> winningCells(List<String> board) {
  for (final line in kWins) {
    final a = board[line[0]], b = board[line[1]], c = board[line[2]];
    if (a != '' && a == b && b == c) return line.toSet();
  }
  return {};
}

String posLabel(int i) {
  final row = i ~/ 3 + 1;
  final col = i % 3 + 1;
  return 'R${row}C$col';
}

// ── Data ──────────────────────────────────────────────────────────────────────
enum MsgType { info, win, lose, draw }

class LogEntry {
  final int n;
  final String playerPos;
  final String? aiPos;
  final String? aiReason;
  LogEntry({required this.n, required this.playerPos, this.aiPos, this.aiReason});
}

// ── App ───────────────────────────────────────────────────────────────────────
class TicTacToeApp extends StatelessWidget {
  const TicTacToeApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TicTacToe AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: kBg,
        fontFamily: 'monospace',
        colorScheme: const ColorScheme.dark(
          primary: kGold,
          surface: kBgCard,
        ),
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Scaffold(
              backgroundColor: kBg,
              body: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(kGold),
                ),
              ),
            );
          }
          if (snapshot.hasData && snapshot.data != null) {
            // User is logged in
            return const SplashScreen();
          }
          // User is not logged in
          return const LoginScreen();
        },
      ),
      routes: {
        '/game': (context) => const GameScreen(isGuest: false),
        '/game-guest': (context) => const GameScreen(isGuest: true),
        '/login': (context) => const LoginScreen(),
      },
    );
  }
}

// ── Game Screen ───────────────────────────────────────────────────────────────
class GameScreen extends StatefulWidget {
  final bool isGuest;
  const GameScreen({super.key, required this.isGuest});
  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  List<String> board = List.filled(9, '');
  bool gameOver = false;
  MsgType msgType = MsgType.info;
  String msgText = 'YOUR MOVE — SELECT A CELL';
  List<LogEntry> log = [];
  int scoreX = 0, scoreO = 0, scoreD = 0;
  int moveN = 0;
  Set<int> winCells = {};
  int? _lastAiIndex;

  @override
  void initState() {
    super.initState();
    _loadScores();
  }

  void resetBoard() {
    setState(() {
      board = List.filled(9, '');
      gameOver = false;
      msgType = MsgType.info;
      msgText = 'YOUR MOVE — SELECT A CELL';
      log = [];
      moveN = 0;
      winCells = {};
      _lastAiIndex = null;
    });
  }

  void fullReset() {
    setState(() {
      scoreX = 0; scoreO = 0; scoreD = 0;
      resetBoard();
    });
  }

  Future<void> _loadScores() async {
    if (widget.isGuest) return;

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (doc.exists) {
          final data = doc.data()!;
          setState(() {
            scoreX = data['scoreX'] ?? 0;
            scoreO = data['scoreO'] ?? 0;
            scoreD = data['scoreD'] ?? 0;
          });
        }
      }
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> _saveScores() async {
    if (widget.isGuest) return;
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set({
          'scoreX': scoreX,
          'scoreO': scoreO,
          'scoreD': scoreD,
          'lastUpdated': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    } catch (e) {
      // Handle error silently
    }
  }

  void makeMove(int idx) {
    if (gameOver || board[idx] != '') return;
    setState(() {
      moveN++;
      board[idx] = 'X';
      final entry = LogEntry(n: moveN, playerPos: posLabel(idx));

      // Check player win
      final winner = checkWinner(board);
      if (winner != null) {
        winCells = winningCells(board);
        msgType = MsgType.win;
        msgText = '◈ VICTORY — YOU WIN';
        scoreX++;
        gameOver = true;
        log.insert(0, entry);
        _saveScores();
        return;
      }
      // Check draw
      if (!board.contains('')) {
        msgType = MsgType.draw;
        msgText = '◈ DRAW — STALEMATE';
        scoreD++;
        gameOver = true;
        log.insert(0, entry);
        _saveScores();
        return;
      }

      // AI move
      final ai = aiMove(board);
      board[ai.index] = 'O';
      _lastAiIndex = ai.index;  // ← store AI move

      final fullEntry = LogEntry(
        n: moveN,
        playerPos: posLabel(idx),
        aiPos: posLabel(ai.index),
        aiReason: ai.reason,
      );

      final winner2 = checkWinner(board);
      if (winner2 != null) {
        winCells = winningCells(board);
        msgType = MsgType.lose;
        msgText = '◈ DEFEAT — AI WINS';
        scoreO++;
        gameOver = true;
      } else if (!board.contains('')) {
        msgType = MsgType.draw;
        msgText = '◈ DRAW — STALEMATE';
        scoreD++;
        gameOver = true;
      } else {
        msgType = MsgType.info;
        msgText = 'AI → ${posLabel(ai.index)} | ${ai.reason}';
      }
      log.insert(0, fullEntry);
      if (gameOver) _saveScores();
    });
  }

  // ── Build ──────────────────────────────────────────────────────────────────
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
                _buildHeader(),
                const SizedBox(height: 20),
                _buildDivider(),
                const SizedBox(height: 30),
                _buildScoreboard(),
                const SizedBox(height: 30),
                _buildStatusMessage(),
                const SizedBox(height: 25),
                _buildBoard(),
                const SizedBox(height: 30),
                _buildControls(),
                if (log.isNotEmpty) ...[
                  _buildDivider(),
                  _buildMoveLog(),
                ],
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              const Text(
                'TIC-TAC-TOE\nAI SYSTEM',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  height: 1.1,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: widget.isGuest ? _backToLogin : _logout,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(color: kBorder, width: 1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                Icon(widget.isGuest ? Icons.arrow_back : Icons.logout, color: kTextMuted, size: 16),
                const SizedBox(width: 6),
                Text(
                  widget.isGuest ? 'BACK TO LOGIN' : 'LOGOUT',
                  style: const TextStyle(
                    color: kTextMuted,
                    fontSize: 11,
                    letterSpacing: 1,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: kBgCard,
        title: const Text(
          'LOGOUT',
          style: TextStyle(color: kGold, letterSpacing: 1),
        ),
        content: const Text(
          'Are you sure you want to logout?',
          style: TextStyle(color: kTextBody),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL', style: TextStyle(color: kGold)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('LOGOUT', style: TextStyle(color: kLose)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await AuthService().signOut();
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    }
  }

  void _backToLogin() {
    Navigator.of(context).pushReplacementNamed('/login');
  }

  // ── Divider ────────────────────────────────────────────────────────────────
  Widget _buildDivider() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 20),
      height: 1,
      color: kBorder,
    );
  }

  // ── Scoreboard ─────────────────────────────────────────────────────────────
  Widget _buildScoreboard() {
    return Container(
      decoration: BoxDecoration(border: Border.all(color: kBorder)),
      child: Row(
        children: [
          _scoreCell('PLAYER (X)', scoreX, highlight: true),
          Container(width: 1, color: kBorder),
          _scoreCell('DRAW', scoreD),
          Container(width: 1, color: kBorder),
          _scoreCell('AI (O)', scoreO),
        ],
      ),
    );
  }

  Widget _scoreCell(String label, int val, {bool highlight = false}) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          children: [
            Text(label,
                style: const TextStyle(color: kTextMuted, fontSize: 9, letterSpacing: 2)),
            const SizedBox(height: 4),
            Text(val.toString().padLeft(2, '0'),
                style: TextStyle(
                  color: highlight ? kGold : kTextLight,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                )),
          ],
        ),
      ),
    );
  }

  // ── Status Message ─────────────────────────────────────────────────────────
  Widget _buildStatusMessage() {
    Color bg, border, textColor;
    switch (msgType) {
      case MsgType.win:
        bg = const Color(0xFF100D00); border = const Color(0xFF8A6A00); textColor = kGold;
        break;
      case MsgType.lose:
        bg = const Color(0xFF1A0505); border = kCrimson; textColor = kLose;
        break;
      case MsgType.draw:
        bg = const Color(0xFF150508); border = kBorder; textColor = kTextLight;
        break;
      default:
        bg = const Color(0xFF0F0305); border = kBorder; textColor = kGold;
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: border),
      ),
      child: Text(
        msgText,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 2,
        ),
      ),
    );
  }

  // ── Board ──────────────────────────────────────────────────────────────────
  Widget _buildBoard() {
    return Center(
      child: Column(
        children: List.generate(3, (row) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(3, (col) {
              final idx = row * 3 + col;
              return _buildCell(idx);
            }),
          );
        }),
      ),
    );
  }

  Widget _buildCell(int idx) {
    final val = board[idx];
    final isWin = winCells.contains(idx);
    Color textColor;
    if (isWin) {
      textColor = Colors.white;
    } else if (val == 'X') {
      textColor = kCrimson;
    } else if (val == 'O') {
      textColor = kGold;
    } else {
      textColor = kBorder;
    }

    final canTap = val == '' && !gameOver;

    return GestureDetector(
      onTap: canTap ? () => makeMove(idx) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 90,
        height: 90,
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: isWin ? kBgDeep : kBgCard,
          border: Border.all(
            color: isWin ? kGold : kBorder,
            width: isWin ? 1.5 : 1,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          val == '' ? '·' : val,
          style: TextStyle(
            color: textColor,
            fontSize: val == '' ? 22 : 32,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }

  // ── Controls ───────────────────────────────────────────────────────────────
  Widget _buildControls() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _ctrlButton('⟳  NEW GAME', resetBoard)),
            const SizedBox(width: 10),
            Expanded(flex: 2, child: _ctrlButton('⊗  FULL RESET (SCORES)', fullReset)),
          ],
        ),
        const SizedBox(height: 10),
        // ── AI Module Button ──────────────────────────────────────────────────
        SizedBox(
          width: double.infinity,
          child: _ctrlButton('◈  AI MODULE', () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AiModuleScreen(
                  board: List.from(board),
                  lastAiIndex: _lastAiIndex,
                  lastAiReason: log.isEmpty ? null : log.first.aiReason,
                  moveCount: moveN,
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _ctrlButton(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: kBorder),
        ),
        alignment: Alignment.center,
        child: Text(label,
            style: const TextStyle(color: kGold, fontSize: 10, letterSpacing: 2)),
      ),
    );
  }

  // ── Move Log ───────────────────────────────────────────────────────────────
  Widget _buildMoveLog() {
    return Container(
      width: double.infinity,
      height: 150,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F0305),
        border: Border.all(color: kBorder),
      ),
      child: ListView.builder(
        itemCount: log.length > 8 ? 8 : log.length,
        itemBuilder: (_, i) {
          final e = log[i];
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                Text('#${e.n.toString().padLeft(2, '0')} ',
                    style: const TextStyle(color: kBorder, fontSize: 11)),
                Text('P→${e.playerPos}  ',
                    style: const TextStyle(color: kCrimson, fontSize: 11)),
                if (e.aiPos != null)
                  Expanded(
                    child: Text(
                      'AI→${e.aiPos} (${e.aiReason})',
                      style: const TextStyle(color: kGold, fontSize: 11),
                      overflow: TextOverflow.ellipsis,
                    ),
                  )
                else
                  const Text('—', style: TextStyle(color: kBorder, fontSize: 11)),
              ],
            ),
          );
        },
      ),
    );
  }
}