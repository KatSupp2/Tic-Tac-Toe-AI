import 'ai_module_screen.dart';
import 'splash_screen.dart';
import 'login_screen.dart';
import 'dart:math';
import 'dart:convert';
import 'package:http/http.dart' as http;
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
const Color kBg        = Color(0xFFFAF8F5);
const Color kBgCard    = Color(0xFFFFFFFF);
const Color kBgDeep    = Color(0xFFF2EDE9);
const Color kBorder    = Color(0xFFE0D5CF);
const Color kCrimson   = Color(0xFFB22222);
const Color kGold      = Color(0xFFB8960C);
const Color kGoldLight = Color(0xFFF5EDD0);
const Color kNavy      = Color(0xFF1C1C2E);
const Color kTextLight = Color(0xFF1C1C2E);
const Color kTextMuted = Color(0xFF9E8E8E);
const Color kTextBody  = Color(0xFF5C4F4F);
const Color kWin       = Color(0xFFB8960C);
const Color kLose      = Color(0xFFC0392B);
const String kQwenApiKey = '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';
const String kQwenApiUrl =
    'https://openrouter.ai/api/v1/chat/completions';
const String kQwenModel = 'openrouter/auto';

enum AiDifficulty { easy, medium, hard }

AiDifficulty difficultyFromStreak(int streak) {
  if (streak >= 3) return AiDifficulty.hard;
  if (streak >= 1) return AiDifficulty.medium;
  return AiDifficulty.easy;
}

String difficultyLabel(AiDifficulty d) {
  switch (d) {
    case AiDifficulty.easy:   return 'EASY';
    case AiDifficulty.medium: return 'MEDIUM';
    case AiDifficulty.hard:   return 'HARD';
  }
}

Color difficultyColor(AiDifficulty d) {
  switch (d) {
    case AiDifficulty.easy:   return const Color(0xFF4CAF50);
    case AiDifficulty.medium: return kGold;
    case AiDifficulty.hard:   return const Color(0xFFFF6B35);
  }
}

const List<List<int>> kWins = [
  [0,1,2],[3,4,5],[6,7,8],
  [0,3,6],[1,4,7],[2,5,8],
  [0,4,8],[2,4,6],
];

int? findWinningMove(List<String> board, String mark) {
  for (final line in kWins) {
    final cells = line.map((i) => board[i]).toList();
    if (cells.where((c) => c == mark).length == 2 && cells.contains('')) {
      return line[cells.indexOf('')];
    }
  }
  return null;
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

String posLabel(int i) => 'R${i ~/ 3 + 1}C${i % 3 + 1}';

class AiResult {
  final int index;
  final String reason;
  final AiDifficulty difficulty;
  const AiResult(this.index, this.reason, this.difficulty);
}
AiResult localAiMove(
    List<String> board,
    String aiMark,
    String playerMark,
    AiDifficulty difficulty,
    ) {
  final rng   = Random();
  final empty = List.generate(9, (i) => i).where((i) => board[i] == '').toList();

  if (difficulty == AiDifficulty.easy && rng.nextDouble() < 0.6) {
    return AiResult(
      empty[rng.nextInt(empty.length)],
      'EASY — random move',
      difficulty,
    );
  }

  final win = findWinningMove(board, aiMark);
  if (win != null) {
    return AiResult(win, 'WIN — executing winning move', difficulty);
  }

  final block = findWinningMove(board, playerMark);
  if (block != null) {
    if (difficulty != AiDifficulty.easy || rng.nextDouble() < 0.3) {
      return AiResult(block, 'BLOCK — neutralizing player threat', difficulty);
    }
  }

  if (board[4] == '') {
    return AiResult(4, 'STRATEGIC — claiming center', difficulty);
  }

  if (difficulty == AiDifficulty.hard) {
    final corners = [0, 2, 6, 8].where((i) => board[i] == '').toList();
    if (corners.isNotEmpty) {
      return AiResult(
        corners[rng.nextInt(corners.length)],
        'STRATEGIC — occupying corner',
        difficulty,
      );
    }
  }

  return AiResult(
    empty[rng.nextInt(empty.length)],
    'FALLBACK — selecting available cell',
    difficulty,
  );
}

Future<AiResult> qwenAiMove(
    List<String> board,
    String aiMark,
    String playerMark,
    AiDifficulty difficulty,
    ) async {
  if (difficulty == AiDifficulty.hard || difficulty == AiDifficulty.medium) {
    final win = findWinningMove(board, aiMark);
    if (win != null) {
      return AiResult(win, 'WIN — immediate threat executed (local)', difficulty);
    }
    final block = findWinningMove(board, playerMark);
    if (block != null && difficulty == AiDifficulty.hard) {
      return AiResult(block, 'BLOCK — player threat neutralized (local)', difficulty);
    }
    // Medium blocks ~70% of the time
    if (block != null && Random().nextDouble() < 0.7) {
      return AiResult(block, 'BLOCK — player threat neutralized (local)', difficulty);
    }
  }

  final cells = List.generate(
    9,
        (i) => board[i] == '' ? i.toString() : board[i],
  );
  final boardViz =
      ' ${cells[0]} | ${cells[1]} | ${cells[2]} \n'
      '---+---+---\n'
      ' ${cells[3]} | ${cells[4]} | ${cells[5]} \n'
      '---+---+---\n'
      ' ${cells[6]} | ${cells[7]} | ${cells[8]} ';

  final emptyCells = List.generate(9, (i) => i)
      .where((i) => board[i] == '')
      .toList();

  final diffInstructions = switch (difficulty) {
    AiDifficulty.easy =>
    'You are playing EASY mode. Pick mostly random cells. '
        'Only take an obvious winning move — never block the player.',
    AiDifficulty.medium =>
    'You are playing MEDIUM mode. Take winning moves when available. '
        'Sometimes miss blocks. Be imperfect — make a suboptimal move occasionally.',
    AiDifficulty.hard =>
    'You are playing HARD mode. Always take a winning move. '
        'Always block the player from winning. Prefer center, then corners.',
  };

  final prompt =
      'You are a Tic-Tac-Toe AI playing as "$aiMark". '
      'The human plays as "$playerMark".\n\n'
      'Board (number = empty cell index, letter = occupied):\n'
      '$boardViz\n\n'
      '$diffInstructions\n\n'
      'Valid moves (empty cell indices): $emptyCells\n\n'
      'Respond with ONLY a raw JSON object — no markdown, no backticks, '
      'no explanation outside it:\n'
      '{"move":<integer from $emptyCells>,"reason":"<10 words max>"}\n\n'
      'The "move" value MUST be one of $emptyCells. '
      'If you return an invalid index the game will crash.';

  try {
    final resp = await http
        .post(
      Uri.parse(kQwenApiUrl),
      headers: {
        'Authorization': 'Bearer $kQwenApiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': kQwenModel,
        'messages': [
          {
            'role': 'system',
            'content':
            'You are a Tic-Tac-Toe engine. '
                'Always respond with raw JSON only. No markdown.',
          },
          {'role': 'user', 'content': prompt},
        ],
        'max_tokens': 60,
        'temperature': difficulty == AiDifficulty.easy ? 1.2 : 0.3,
      }),
    )
        .timeout(const Duration(seconds: 8));

    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      final content =
      (data['choices'] as List).first['message']['content'] as String;

      // Strip any accidental markdown fences
      final clean = content
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();

      final parsed = jsonDecode(clean) as Map<String, dynamic>;
      final int move = (parsed['move'] as num).toInt();
      final String reason = parsed['reason'] as String? ?? 'Qwen decision';

      if (move >= 0 && move <= 8 && board[move] == '') {
        return AiResult(
          move,
          'QWEN [${difficultyLabel(difficulty)}] — $reason',
          difficulty,
        );
      }
    } else {
      debugPrint('Qwen API error ${resp.statusCode}: ${resp.body}');
    }
  } catch (e) {
    debugPrint('Qwen API exception: $e');
  }

  final fb = localAiMove(board, aiMark, playerMark, difficulty);
  return AiResult(fb.index, 'LOCAL FALLBACK — ${fb.reason}', difficulty);
}

enum MsgType { info, win, lose, draw }

class LogEntry {
  final int n;
  final String playerPos;
  final String? aiPos;
  final String? aiReason;
  LogEntry({
    required this.n,
    required this.playerPos,
    this.aiPos,
    this.aiReason,
  });
}

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
        colorScheme: const ColorScheme.light(primary: kNavy, surface: kBgCard),
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              backgroundColor: kBg,
              body: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(kGold),
                ),
              ),
            );
          }
          return snapshot.hasData && snapshot.data != null
              ? const SplashScreen()
              : const LoginScreen();
        },
      ),
      routes: {
        '/splash':           (ctx) => const SplashScreen(),
        '/game':             (ctx) => const GameScreen(isGuest: false, isMultiplayer: false),
        '/game-multi':       (ctx) => const GameScreen(isGuest: false, isMultiplayer: true),
        '/game-guest':       (ctx) => const GameScreen(isGuest: true,  isMultiplayer: false),
        '/game-guest-multi': (ctx) => const GameScreen(isGuest: true,  isMultiplayer: true),
        '/login':            (ctx) => const LoginScreen(),
      },
    );
  }
}

class GameScreen extends StatefulWidget {
  final bool isGuest;
  final bool isMultiplayer;
  const GameScreen({
    super.key,
    required this.isGuest,
    required this.isMultiplayer,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  List<String> board = List.filled(9, '');
  bool gameOver      = false;
  bool _aiThinking   = false;
  MsgType msgType    = MsgType.info;
  String msgText     = '';
  List<LogEntry> log = [];
  int scoreX = 0, scoreO = 0, scoreD = 0;
  int moveN          = 0;
  Set<int> winCells  = {};
  int? _lastAiIndex;

  int _playerWinStreak     = 0;
  AiDifficulty _difficulty = AiDifficulty.easy;

  late String playerMark;
  late String aiMark;

  String _currentTurn = 'X';

  @override
  void initState() {
    super.initState();
    _assignMarks();
    _loadScores();
    _updateInitialMessage();
    if (!widget.isMultiplayer && aiMark == 'X') {
      WidgetsBinding.instance.addPostFrameCallback(
            (_) => _triggerAiOpeningMove(),
      );
    }
  }

  void _assignMarks() {
    final rng = Random(DateTime.now().microsecondsSinceEpoch);
    if (rng.nextBool()) {
      playerMark = 'X';
      aiMark     = 'O';
    } else {
      playerMark = 'O';
      aiMark     = 'X';
    }
    _currentTurn = 'X';
  }

  void _updateInitialMessage() {
    if (widget.isMultiplayer) {
      msgText = 'PLAYER X — SELECT A CELL';
    } else {
      msgText = 'YOU ARE $playerMark — SELECT A CELL';
    }
  }

  Future<void> _triggerAiOpeningMove() async {
    setState(() {
      _aiThinking = true;
      msgText     = 'AI IS THINKING...';
    });
    final result = await qwenAiMove(
      List.from(board),
      aiMark,
      playerMark,
      _difficulty,
    );
    if (!mounted) return;
    setState(() {
      board[result.index] = aiMark;
      _lastAiIndex        = result.index;
      _aiThinking         = false;
      _currentTurn        = playerMark;
      moveN++;
      log.insert(
        0,
        LogEntry(
          n:        moveN,
          playerPos:'—',
          aiPos:    posLabel(result.index),
          aiReason: result.reason,
        ),
      );
      msgText = 'YOU ARE $playerMark — AI opened at ${posLabel(result.index)}';
    });
  }

  void resetBoard() {
    setState(() {
      board        = List.filled(9, '');
      gameOver     = false;
      _aiThinking  = false;
      msgType      = MsgType.info;
      log          = [];
      moveN        = 0;
      winCells     = {};
      _lastAiIndex = null;
      _currentTurn = 'X';
    });
    _assignMarks();
    _updateInitialMessage();
    if (!widget.isMultiplayer && aiMark == 'X') {
      WidgetsBinding.instance.addPostFrameCallback(
            (_) => _triggerAiOpeningMove(),
      );
    }
  }

  void fullReset() {
    setState(() {
      scoreX           = 0;
      scoreO           = 0;
      scoreD           = 0;
      _playerWinStreak = 0;
      _difficulty      = AiDifficulty.easy;
    });
    _assignMarks();
    _updateInitialMessage();
    setState(() {
      board        = List.filled(9, '');
      gameOver     = false;
      _aiThinking  = false;
      msgType      = MsgType.info;
      log          = [];
      moveN        = 0;
      winCells     = {};
      _lastAiIndex = null;
      _currentTurn = 'X';
    });
    if (!widget.isMultiplayer && aiMark == 'X') {
      WidgetsBinding.instance.addPostFrameCallback(
            (_) => _triggerAiOpeningMove(),
      );
    }
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
          final d = doc.data()!;
          setState(() {
            scoreX           = d['scoreX']    ?? 0;
            scoreO           = d['scoreO']    ?? 0;
            scoreD           = d['scoreD']    ?? 0;
            _playerWinStreak = d['winStreak'] ?? 0;
            _difficulty      = difficultyFromStreak(_playerWinStreak);
          });
        }
      }
    } catch (_) {}
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
          'scoreX':      scoreX,
          'scoreO':      scoreO,
          'scoreD':      scoreD,
          'winStreak':   _playerWinStreak,
          'lastUpdated': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    } catch (_) {}
  }

  void makeMove(int idx) {
    if (gameOver || board[idx] != '' || _aiThinking) return;
    if (widget.isMultiplayer) {
      _makeMultiplayerMove(idx);
    } else {
      _makeSinglePlayerMove(idx);
    }
  }

  Future<void> _makeSinglePlayerMove(int idx) async {
    if (_currentTurn != playerMark) return;

    setState(() {
      moveN++;
      board[idx]   = playerMark;
      _currentTurn = aiMark;
    });

    final winner = checkWinner(board);
    if (winner != null) {
      setState(() {
        winCells         = winningCells(board);
        msgType          = MsgType.win;
        _playerWinStreak++;
        _difficulty      = difficultyFromStreak(_playerWinStreak);
        msgText =
        '◈ VICTORY — YOU WIN  🔥 '
            'Streak: $_playerWinStreak  •  '
            'Next: ${difficultyLabel(_difficulty)}';
        if (winner == 'X') scoreX++; else scoreO++;
        gameOver = true;
        log.insert(0, LogEntry(n: moveN, playerPos: posLabel(idx)));
      });
      _saveScores();
      return;
    }

    if (!board.contains('')) {
      setState(() {
        msgType = MsgType.draw;
        msgText = '◈ DRAW — STALEMATE';
        scoreD++;
        gameOver = true;
        log.insert(0, LogEntry(n: moveN, playerPos: posLabel(idx)));
      });
      _saveScores();
      return;
    }

    setState(() {
      _aiThinking = true;
      msgText     = 'AI IS THINKING...';
    });
    final result = await qwenAiMove(
      List.from(board),
      aiMark,
      playerMark,
      _difficulty,
    );
    if (!mounted) return;

    setState(() {
      board[result.index] = aiMark;
      _lastAiIndex        = result.index;
      _aiThinking         = false;
      _currentTurn        = playerMark;

      final fullEntry = LogEntry(
        n:         moveN,
        playerPos: posLabel(idx),
        aiPos:     posLabel(result.index),
        aiReason:  result.reason,
      );

      final winner2 = checkWinner(board);
      if (winner2 != null) {
        winCells         = winningCells(board);
        msgType          = MsgType.lose;
        msgText          = '◈ DEFEAT — AI WINS';
        if (winner2 == 'X') scoreX++; else scoreO++;
        _playerWinStreak = 0;
        _difficulty      = difficultyFromStreak(0);
        gameOver         = true;
      } else if (!board.contains('')) {
        msgType = MsgType.draw;
        msgText = '◈ DRAW — STALEMATE';
        scoreD++;
        // draw: streak unchanged
        gameOver = true;
      } else {
        msgType = MsgType.info;
        msgText = 'AI → ${posLabel(result.index)} | ${result.reason}';
      }
      log.insert(0, fullEntry);
    });
    if (gameOver) _saveScores();
  }

  void _makeMultiplayerMove(int idx) {
    setState(() {
      moveN++;
      final mark = _currentTurn;
      board[idx] = mark;
      log.insert(0, LogEntry(n: moveN, playerPos: posLabel(idx)));

      final winner = checkWinner(board);
      if (winner != null) {
        winCells = winningCells(board);
        if (winner == 'X') {
          msgType = MsgType.win;
          msgText = '◈ PLAYER X WINS!';
          scoreX++;
        } else {
          msgType = MsgType.lose;
          msgText = '◈ PLAYER O WINS!';
          scoreO++;
        }
        gameOver = true;
        _saveScores();
        return;
      }
      if (!board.contains('')) {
        msgType  = MsgType.draw;
        msgText  = '◈ DRAW — STALEMATE';
        scoreD++;
        gameOver = true;
        _saveScores();
        return;
      }
      _currentTurn = mark == 'X' ? 'O' : 'X';
      msgType = MsgType.info;
      msgText = 'PLAYER $_currentTurn — SELECT A CELL';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: Stack(
        children: [
          Positioned(
            top: -60, right: -60,
            child: Container(
              width: 220, height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: kGoldLight.withOpacity(0.5),
              ),
            ),
          ),
          Positioned(
            bottom: -80, left: -50,
            child: Container(
              width: 200, height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFE8DDD5).withOpacity(0.4),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 8),
                  _buildModeBadge(),
                  if (!widget.isMultiplayer) ...[
                    const SizedBox(height: 10),
                    _buildDifficultyBadge(),
                  ],
                  const SizedBox(height: 14),
                  _buildDivider(),
                  const SizedBox(height: 20),
                  _buildScoreboard(),
                  const SizedBox(height: 20),
                  _buildStatusMessage(),
                  const SizedBox(height: 24),
                  _buildBoard(),
                  const SizedBox(height: 24),
                  _buildControls(),
                  if (log.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    _buildDivider(),
                    const SizedBox(height: 4),
                    _buildMoveLog(),
                  ],
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: _backToSplash,
          child: Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              color: kBgCard,
              border: Border.all(color: kBorder),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: kNavy.withOpacity(0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(Icons.arrow_back_rounded, color: kTextBody, size: 18),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          width: 42, height: 42,
          decoration: BoxDecoration(
            color: kNavy,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: kNavy.withOpacity(0.18),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(Icons.grid_3x3_rounded, color: kGoldLight, size: 22),
        ),
        const SizedBox(width: 14),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tic-Tac-Toe',
                style: TextStyle(
                  color: kTextLight, fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3, height: 1.1,
                ),
              ),
              Text(
                'AI SYSTEM',
                style: TextStyle(
                  color: kGold, fontSize: 11,
                  fontWeight: FontWeight.w700, letterSpacing: 2,
                ),
              ),
            ],
          ),
        ),
        _buildHeaderAction(),
      ],
    );
  }

  void _backToSplash() =>
      Navigator.of(context).pushReplacementNamed('/splash');

  Widget _buildHeaderAction() {
    return GestureDetector(
      onTap: widget.isGuest ? _backToLogin : _logout,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: kBgCard,
          border: Border.all(color: kBorder),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: kNavy.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              widget.isGuest ? Icons.arrow_back_rounded : Icons.logout_rounded,
              color: kTextMuted, size: 15,
            ),
            const SizedBox(width: 6),
            Text(
              widget.isGuest ? 'Login' : 'Logout',
              style: const TextStyle(
                color: kTextBody, fontSize: 12,
                fontWeight: FontWeight.w600, letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeBadge() {
    final isMulti = widget.isMultiplayer;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isMulti ? kNavy : kGoldLight,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isMulti ? Icons.people_rounded : Icons.smart_toy_rounded,
            size: 13,
            color: isMulti ? kGoldLight : kGold,
          ),
          const SizedBox(width: 6),
          Text(
            isMulti
                ? 'Multiplayer — Pass & Play'
                : 'vs AI  •  You: $playerMark  AI: $aiMark',
            style: TextStyle(
              color: isMulti ? kGoldLight : kGold,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDifficultyBadge() {
    final color = difficultyColor(_difficulty);
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            border: Border.all(color: color.withOpacity(0.4)),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.bolt_rounded, size: 13, color: color),
              const SizedBox(width: 5),
              Text(
                'AI: ${difficultyLabel(_difficulty)}',
                style: TextStyle(
                  color: color, fontSize: 10,
                  fontWeight: FontWeight.w700, letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: kBgDeep,
            border: Border.all(color: kBorder),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.local_fire_department_rounded,
                size: 13, color: kTextMuted,
              ),
              const SizedBox(width: 5),
              Text(
                'STREAK: $_playerWinStreak',
                style: const TextStyle(
                  color: kTextBody, fontSize: 10,
                  fontWeight: FontWeight.w700, letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kBgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Sign Out',
          style: TextStyle(
            color: kTextLight, fontWeight: FontWeight.w700, fontSize: 18,
          ),
        ),
        content: const Text(
          'Are you sure you want to sign out?',
          style: TextStyle(color: kTextBody, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: kTextMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Sign Out',
              style: TextStyle(color: kLose, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await AuthService().signOut();
      if (mounted) Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  void _backToLogin() => Navigator.of(context).pushReplacementNamed('/login');

  Widget _buildDivider() => Container(height: 1, color: kBorder);

  Widget _buildScoreboard() {
    final xLabel = widget.isMultiplayer
        ? 'Player X'
        : (playerMark == 'X' ? 'You (X)' : 'AI (X)');
    final oLabel = widget.isMultiplayer
        ? 'Player O'
        : (playerMark == 'O' ? 'You (O)' : 'AI (O)');

    const xColor = kCrimson;
    const oColor = kGold;

    return Container(
      decoration: BoxDecoration(
        color: kBgCard,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: kNavy.withOpacity(0.07),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          _scoreCell(xLabel, scoreX,
              color: xColor, isActive: !gameOver && _currentTurn == 'X'),
          _scoreDivider(),
          _scoreCell('Draw', scoreD, color: kTextMuted),
          _scoreDivider(),
          _scoreCell(oLabel, scoreO,
              color: oColor, isActive: !gameOver && _currentTurn == 'O'),
        ],
      ),
    );
  }

  Widget _scoreDivider() =>
      Container(width: 1, height: 60, color: kBorder);

  Widget _scoreCell(
      String label,
      int val, {
        required Color color,
        bool isActive = false,
      }) {
    return Expanded(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isActive ? color.withOpacity(0.06) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                color: isActive ? color : kTextMuted,
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              val.toString().padLeft(2, '0'),
              style: TextStyle(
                color: isActive ? color : kTextBody,
                fontSize: 28,
                fontWeight: FontWeight.w800,
                height: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusMessage() {
    final playerColor = playerMark == 'X' ? kCrimson : kGold;
    final playerBg    = playerMark == 'X'
        ? const Color(0xFFFFF5F5)
        : kGoldLight;
    final playerTextColor = playerMark == 'X'
        ? kCrimson
        : const Color(0xFF7A6200);

    Color bg, border, textColor;
    switch (msgType) {
      case MsgType.win:
        bg        = playerBg;
        border    = playerColor.withOpacity(0.5);
        textColor = playerTextColor;
      case MsgType.lose:
        bg        = const Color(0xFFFFF0F0);
        border    = kLose.withOpacity(0.4);
        textColor = kLose;
      case MsgType.draw:
        bg        = kBgDeep;
        border    = kBorder;
        textColor = kTextBody;
      default:
        bg        = kBgDeep;
        border    = kBorder;
        textColor = kTextBody;
    }
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (_aiThinking) ...[
            SizedBox(
              width: 12, height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(textColor),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Text(
              msgText,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: textColor, fontSize: 12,
                fontWeight: FontWeight.w700, letterSpacing: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBoard() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: kBgCard,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: kNavy.withOpacity(0.08),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(
            3,
                (row) => Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(
                3,
                    (col) => _buildCell(row * 3 + col),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCell(int idx) {
    final val      = board[idx];
    final isWin    = winCells.contains(idx);
    final isAiLast = !widget.isMultiplayer && _lastAiIndex == idx && !isWin;
    final canTap   = val == '' &&
        !gameOver &&
        !_aiThinking &&
        (widget.isMultiplayer || _currentTurn == playerMark);

    Color markColor(String mark) => mark == 'X' ? kCrimson : kGold;
    Color markBg(String mark)    => mark == 'X'
        ? const Color(0xFFFFF5F5)
        : kGoldLight.withOpacity(0.5);

    Color cellBg, textColor, borderColor;
    if (isWin) {
      final wColor = markColor(val);
      cellBg      = markBg(val);
      borderColor = wColor.withOpacity(0.6);
      textColor   = wColor;
    } else if (isAiLast) {
      final aiColor = markColor(aiMark);
      cellBg      = markBg(aiMark);
      borderColor = aiColor.withOpacity(0.5);
      textColor   = aiColor;
    } else if (val == 'X') {
      cellBg      = const Color(0xFFFFF5F5);
      borderColor = kCrimson.withOpacity(0.25);
      textColor   = kCrimson;
    } else if (val == 'O') {
      cellBg      = kGoldLight.withOpacity(0.5);
      borderColor = kGold.withOpacity(0.3);
      textColor   = kGold;
    } else {
      cellBg      = kBgDeep;
      borderColor = kBorder;
      textColor   = kBorder;
    }

    final winGlowColor = val.isNotEmpty ? markColor(val) : kGold;

    return GestureDetector(
      onTap: canTap ? () => makeMove(idx) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 88, height: 88,
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: cellBg,
          border: Border.all(
            color: borderColor,
            width: isWin ? 1.5 : 1.0,
          ),
          borderRadius: BorderRadius.circular(10),
          boxShadow: isWin
              ? [BoxShadow(color: winGlowColor.withOpacity(0.2), blurRadius: 8)]
              : null,
        ),
        alignment: Alignment.center,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 150),
          child: Text(
            val.isEmpty ? '' : val,
            key: ValueKey(val),
            style: TextStyle(
              color: textColor,
              fontSize: val.isEmpty ? 20 : 34,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildControls() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _ctrlButton(
                'New Game', Icons.refresh_rounded, resetBoard, primary: true,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: _ctrlButton(
                'Full Reset', Icons.restart_alt_rounded, fullReset,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (!widget.isMultiplayer)
          _ctrlButton(
            '◈  AI Module',
            Icons.psychology_rounded,
                () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AiModuleScreen(
                    board:        List.from(board),
                    lastAiIndex:  _lastAiIndex,
                    lastAiReason: log.isEmpty ? null : log.first.aiReason,
                    moveCount:    moveN,
                  ),
                ),
              );
            },
            fullWidth: true,
          ),
      ],
    );
  }

  Widget _ctrlButton(
      String label,
      IconData icon,
      VoidCallback onTap, {
        bool primary  = false,
        bool fullWidth = false,
      }) {
    return SizedBox(
      width: fullWidth ? double.infinity : null,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 12),
          decoration: BoxDecoration(
            color: primary ? kNavy : kBgCard,
            border: Border.all(color: primary ? kNavy : kBorder),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: kNavy.withOpacity(primary ? 0.2 : 0.05),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 15, color: primary ? kGoldLight : kTextBody),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: primary ? kGoldLight : kTextBody,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMoveLog() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 10, top: 4),
          child: Text(
            'Move History',
            style: TextStyle(
              color: kTextBody, fontSize: 12,
              fontWeight: FontWeight.w700, letterSpacing: 0.5,
            ),
          ),
        ),
        Container(
          width: double.infinity,
          height: 150,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: kBgCard,
            border: Border.all(color: kBorder),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: kNavy.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ListView.builder(
            itemCount: log.length > 8 ? 8 : log.length,
            itemBuilder: (_, i) {
              final e = log[i];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2.5),
                child: Row(
                  children: [
                    Text(
                      '#${e.n.toString().padLeft(2, '0')} ',
                      style: TextStyle(
                        color: kTextMuted.withOpacity(0.7), fontSize: 11,
                      ),
                    ),
                    Text(
                      'P→${e.playerPos}  ',
                      style: const TextStyle(
                        color: kCrimson, fontSize: 11, fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (e.aiPos != null)
                      Expanded(
                        child: Text(
                          'AI→${e.aiPos} (${e.aiReason})',
                          style: const TextStyle(color: kGold, fontSize: 11),
                          overflow: TextOverflow.ellipsis,
                        ),
                      )
                    else
                      Text(
                        '—',
                        style: TextStyle(
                          color: kTextMuted.withOpacity(0.6), fontSize: 11,
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}