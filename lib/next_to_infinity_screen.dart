import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'theme_color_picker.dart';

class NextToInfinityScreen extends StatefulWidget {
  final Color themeColor;

  const NextToInfinityScreen({super.key, required this.themeColor});

  @override
  State<NextToInfinityScreen> createState() => _NextToInfinityScreenState();
}

class _NextToInfinityScreenState extends State<NextToInfinityScreen>
    with TickerProviderStateMixin {
  static const int boardSize = 12;
  static const int initialTimeSeconds = 120; // 2 perc = 120 másodperc
  static const String highScorePrefKey = 'infinity_best_score';

  // ÚJ: a kártyaforgatás ideje, ennyit várunk a színváltás előtt
  static const int flipDurationMs = 320;

  late List<int> cards;
  int nextNumberToGenerate = 13;

  int? firstSelectedIndex;
  int? secondSelectedIndex;
  Set<int> poppingIndices = {};
  Set<int> spawningIndices = {};
  bool isChecking = false;
  bool isMismatch = false; // ÚJ: rossz pár esetén a várakozás idejére igaz

  int score = 0;
  int bestScore = 0;
  int remainingSeconds = initialTimeSeconds;
  Timer? countdownTimer;
  bool hasGameStarted = false;

  int? lastEarnedPoints;
  late AnimationController _floatingScoreController;
  late Animation<double> _floatingScaleAnimation;
  late Animation<double> _floatingOpacityAnimation;

  late Color cardThemeColor = widget.themeColor;
  Color selectedColor = Colors.amberAccent;

  bool isSoundEnabled = true;
  bool isVibrationEnabled = true;

  @override
  void initState() {
    super.initState();
    _initBoard();
    _loadSettingsAndBestScore();

    _floatingScoreController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _floatingScaleAnimation = Tween<double>(begin: 0.6, end: 1.25).animate(
      CurvedAnimation(
        parent: _floatingScoreController,
        curve: Curves.easeOutBack,
      ),
    );

    _floatingOpacityAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _floatingScoreController,
        curve: const Interval(0.5, 1.0, curve: Curves.easeIn),
      ),
    );
  }

  void _initBoard() {
    cards = List.generate(boardSize, (index) => index + 1)..shuffle();
    nextNumberToGenerate = boardSize + 1;
    firstSelectedIndex = null;
    secondSelectedIndex = null;
    poppingIndices.clear();
    spawningIndices.clear();
    isChecking = false;
    isMismatch = false;
    score = 0;
    remainingSeconds = initialTimeSeconds;
    hasGameStarted = false;
    lastEarnedPoints = null;
  }

  Future<void> _loadSettingsAndBestScore() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      isSoundEnabled = prefs.getBool('sound_enabled') ?? true;
      isVibrationEnabled = prefs.getBool('vibration_enabled') ?? true;
      bestScore = prefs.getInt(highScorePrefKey) ?? 0;
    });
  }

  Future<void> _saveBestScore() async {
    if (score > bestScore) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(highScorePrefKey, score);
      if (mounted) {
        setState(() {
          bestScore = score;
        });
      }
    }
  }

  Future<void> _toggleSound() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isSoundEnabled = !isSoundEnabled;
    });
    await prefs.setBool('sound_enabled', isSoundEnabled);
  }

  Future<void> _toggleVibration() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isVibrationEnabled = !isVibrationEnabled;
    });
    await prefs.setBool('vibration_enabled', isVibrationEnabled);
    if (isVibrationEnabled) {
      HapticFeedback.lightImpact();
    }
  }

  void _triggerHaptic({bool isMatch = false}) {
    if (!isVibrationEnabled) return;
    if (isMatch) {
      HapticFeedback.mediumImpact();
    } else {
      HapticFeedback.lightImpact();
    }
  }

  void _playSparkleSound() {
    if (!isSoundEnabled) return;
    SystemSound.play(SystemSoundType.click);
  }

  void _startCountdown() {
    if (hasGameStarted) return;
    hasGameStarted = true;

    countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (remainingSeconds > 1) {
        setState(() {
          remainingSeconds--;
        });
      } else {
        setState(() {
          remainingSeconds = 0;
        });
        _endGame();
      }
    });
  }

  void _stopCountdown() {
    countdownTimer?.cancel();
  }

  Future<void> _endGame() async {
    _stopCountdown();
    isChecking = true;
    await _saveBestScore();
    if (!mounted) return;
    _showInfinitySummaryDialog();
  }

  String get remainingTimeText {
    final minutes = (remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (remainingSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  bool _hasNeighborOnBoard(int number) {
    return cards.contains(number - 1) || cards.contains(number + 1);
  }

  void _handleLonelyCard(int index) {
    _triggerHaptic(isMatch: true);
    _playSparkleSound();

    final int cardValue = cards[index];
    final int earnedPoints = 50 + (cardValue * 5);

    setState(() {
      firstSelectedIndex = index;
      isChecking = true;
    });

    Future.delayed(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      setState(() {
        score += earnedPoints;
        lastEarnedPoints = earnedPoints;
        poppingIndices.add(index);
      });

      _floatingScoreController.forward(from: 0.0);

      if (score > bestScore) {
        _saveBestScore();
      }

      Future.delayed(const Duration(milliseconds: 250), () {
        if (!mounted) return;
        setState(() {
          poppingIndices.clear();

          for (int i = 0; i < cards.length; i++) {
            spawningIndices.add(i);
          }

          cards[index] = nextNumberToGenerate++;
          cards.shuffle();

          firstSelectedIndex = null;
          isChecking = false;
        });

        Future.delayed(const Duration(milliseconds: 150), () {
          if (!mounted) return;
          setState(() {
            spawningIndices.clear();
          });
        });
      });
    });
  }

  void _handleMatch(List<int> matchedIndices) {
    _triggerHaptic(isMatch: true);
    _playSparkleSound();

    final int maxMatchedValue = matchedIndices
        .map((idx) => cards[idx])
        .reduce(math.max);
    final int earnedPoints = 100 + (maxMatchedValue * 10);

    setState(() {
      score += earnedPoints;
      lastEarnedPoints = earnedPoints;
      poppingIndices.addAll(matchedIndices);
      isChecking = true;
    });

    _floatingScoreController.forward(from: 0.0);

    if (score > bestScore) {
      _saveBestScore();
    }

    Future.delayed(const Duration(milliseconds: 250), () {
      if (!mounted) return;
      setState(() {
        poppingIndices.clear();

        for (int i = 0; i < cards.length; i++) {
          spawningIndices.add(i);
        }

        for (final idx in matchedIndices) {
          cards[idx] = nextNumberToGenerate++;
        }
        cards.shuffle();

        firstSelectedIndex = null;
        secondSelectedIndex = null;
        isChecking = false;
      });

      Future.delayed(const Duration(milliseconds: 150), () {
        if (!mounted) return;
        setState(() {
          spawningIndices.clear();
        });
      });
    });
  }

  // ÚJ: rossz pár kezelése lépésről lépésre
  Future<void> _handleMismatch() async {
    // 1. Megvárjuk, amíg a második kártya teljesen felfordul
    await Future.delayed(const Duration(milliseconds: flipDurationMs));
    if (!mounted) return;

    // 2. Csak ezután festjük át a belsejét
    setState(() {
      isMismatch = true;
    });

    // 3. Utána jön a várakozás, hogy a játékos lássa a hibát
    await Future.delayed(const Duration(milliseconds: 950));
    if (!mounted) return;

    // 4. Visszaállítás: a kártyák visszafordulnak
    setState(() {
      firstSelectedIndex = null;
      secondSelectedIndex = null;
      isChecking = false;
      isMismatch = false;
    });
  }

  void _onCardTap(int index) {
    if (isChecking ||
        remainingSeconds <= 0 ||
        index == firstSelectedIndex ||
        poppingIndices.contains(index) ||
        spawningIndices.contains(index)) {
      return;
    }

    _startCountdown();
    _triggerHaptic(isMatch: false);

    if (firstSelectedIndex == null) {
      final int selectedNumber = cards[index];

      if (!_hasNeighborOnBoard(selectedNumber)) {
        _handleLonelyCard(index);
        return;
      }

      setState(() {
        firstSelectedIndex = index;
      });
      return;
    }

    if (firstSelectedIndex != null && secondSelectedIndex == null) {
      setState(() {
        secondSelectedIndex = index;
      });

      final int firstNumber = cards[firstSelectedIndex!];
      final int secondNumber = cards[secondSelectedIndex!];
      final bool isMatch = (firstNumber - secondNumber).abs() == 1;

      if (isMatch) {
        // 450ms késleltetés, hogy a játékos lássa a második kártyát is
        isChecking = true;
        Future.delayed(const Duration(milliseconds: 450), () {
          if (mounted) {
            _handleMatch([firstSelectedIndex!, secondSelectedIndex!]);
          }
        });
      } else {
        isChecking = true;
        _handleMismatch(); // ÚJ
      }
    }
  }

  void _restartGame() {
    _stopCountdown();
    setState(() {
      _initBoard();
    });
  }

  void _showInfinityRules() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: cardThemeColor.withValues(alpha: 0.7),
            width: 2,
          ),
        ),
        title: Row(
          children: [
            Icon(Icons.all_inclusive_rounded, color: cardThemeColor, size: 28),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Infinity Rules',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildRuleItem(
                Icons.filter_2_rounded,
                'Find Neighboring Numbers',
                'Flip two cards whose values differ by exactly 1 (for example: 4 and 5, or 12 and 11).',
              ),
              const SizedBox(height: 14),
              _buildRuleItem(
                Icons.autorenew_rounded,
                'Endless Replacements & Shuffle',
                'Matched cards disappear and new numbers appear, shuffled into the board with a smooth effect!',
              ),
              const SizedBox(height: 14),
              _buildRuleItem(
                Icons.bolt_rounded,
                'Lonely Cards Bonus',
                'If you flip a card that has no neighbor, it flips, pauses, clears with an animation, and awards bonus points!',
              ),
              const SizedBox(height: 14),
              _buildRuleItem(
                Icons.trending_up_rounded,
                'Scaling Score & 2-Min Timer',
                'Higher numbers grant more points per match. Race against the 5:00 countdown to set a new record!',
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: cardThemeColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text(
              'Got it!',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRuleItem(IconData icon, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: cardThemeColor.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.amberAccent, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                description,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showInfinitySummaryDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: cardThemeColor.withValues(alpha: 0.7),
            width: 2,
          ),
        ),
        title: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.all_inclusive_rounded,
              color: Colors.amberAccent,
              size: 28,
            ),
            SizedBox(width: 10),
            Text(
              'Time is Up!',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Next to Infinity',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 20,
                ),
                decoration: BoxDecoration(
                  color: cardThemeColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white24),
                ),
                child: Column(
                  children: [
                    const Text(
                      'FINAL SCORE',
                      style: TextStyle(
                        color: Colors.amberAccent,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$score',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Best Score: $bestScore',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Highest Card Reached: ${nextNumberToGenerate - 1}',
                style: const TextStyle(color: Colors.white54, fontSize: 13),
              ),
            ],
          ),
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              Navigator.pop(context);
            },
            child: const Text(
              'Main Menu',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: cardThemeColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              Navigator.pop(dialogContext);
              _restartGame();
            },
            icon: const Icon(Icons.replay_rounded, size: 18),
            label: const Text('Play Again'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    countdownTimer?.cancel();
    _floatingScoreController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final orientation = MediaQuery.orientationOf(context);
    final int columnCount = (orientation == Orientation.portrait) ? 3 : 6;
    final bool isLowTime = remainingSeconds <= 30;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            'Next to Infinity',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
        ),
        actions: [
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            icon: Icon(
              isSoundEnabled
                  ? Icons.volume_up_rounded
                  : Icons.volume_off_rounded,
              color: isSoundEnabled ? Colors.white : Colors.white54,
              size: 20,
            ),
            onPressed: _toggleSound,
          ),
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            icon: Icon(
              isVibrationEnabled
                  ? Icons.vibration_rounded
                  : Icons.smartphone_rounded,
              color: isVibrationEnabled ? Colors.white : Colors.white54,
              size: 20,
            ),
            onPressed: _toggleVibration,
          ),
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            icon: const Icon(
              Icons.help_outline_rounded,
              color: Colors.white,
              size: 20,
            ),
            onPressed: _showInfinityRules,
          ),
          ThemeColorPicker(
            onColorSelected: (newColor) {
              setState(() {
                cardThemeColor = newColor;
              });
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: ColorFiltered(
              colorFilter: ColorFilter.mode(cardThemeColor, BlendMode.modulate),
              child: Image.asset(
                'assets/images/nextFinderBG.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
          Positioned.fill(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    // STÁTUSZSÁV (IDŐ ÉS PONTOZÁS)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: cardThemeColor.withValues(alpha: 0.5),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: cardThemeColor.withValues(alpha: 0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.timer_outlined,
                                size: 18,
                                color: isLowTime
                                    ? Colors.redAccent
                                    : Colors.amberAccent,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                remainingTimeText,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: isLowTime
                                      ? Colors.redAccent
                                      : Colors.white,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 30),
                          Row(
                            children: [
                              const Icon(
                                Icons.stars_rounded,
                                size: 18,
                                color: Colors.amberAccent,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '$score pts',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    // LEBEGŐ PONTSZÁM ANIMÁCIÓ
                    SizedBox(
                      height: 28,
                      child: Center(
                        child: lastEarnedPoints != null
                            ? AnimatedBuilder(
                                animation: _floatingScoreController,
                                builder: (context, child) {
                                  return Opacity(
                                    opacity:
                                        1.0 - _floatingOpacityAnimation.value,
                                    child: Transform.scale(
                                      scale: _floatingScaleAnimation.value,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.amberAccent.withValues(
                                            alpha: 0.25,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          border: Border.all(
                                            color: Colors.amberAccent,
                                            width: 1,
                                          ),
                                        ),
                                        child: Text(
                                          '+$lastEarnedPoints pts',
                                          style: const TextStyle(
                                            color: Colors.amberAccent,
                                            fontWeight: FontWeight.w900,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              )
                            : const SizedBox.shrink(),
                      ),
                    ),
                    const SizedBox(height: 4),
                    // KÁRTYA RÁCS
                    Expanded(
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 560),
                          child: GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: boardSize,
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: columnCount,
                                  mainAxisSpacing: 12,
                                  crossAxisSpacing: 12,
                                  childAspectRatio: 1.0,
                                ),
                            itemBuilder: (context, index) {
                              final int cardValue = cards[index];
                              final bool isSelected =
                                  index == firstSelectedIndex ||
                                  index == secondSelectedIndex;
                              final bool isPopping = poppingIndices.contains(
                                index,
                              );
                              final bool isSpawning = spawningIndices.contains(
                                index,
                              );

                              return _InfinityAnimatedCard(
                                key: ValueKey('slot_${index}_val_$cardValue'),
                                label: cardValue.toString(),
                                isFaceUp:
                                    (isSelected || isPopping) && !isSpawning,
                                isSelected: isSelected,
                                isPopping: isPopping,
                                isSpawning: isSpawning,
                                isMismatch: isMismatch && isSelected,
                                themeColor: cardThemeColor,
                                selectedBorderColor: selectedColor,
                                onTap: () => _onCardTap(index),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfinityAnimatedCard extends StatelessWidget {
  const _InfinityAnimatedCard({
    super.key,
    required this.label,
    required this.isFaceUp,
    required this.isSelected,
    required this.isPopping,
    required this.isSpawning,
    required this.isMismatch,
    required this.themeColor,
    required this.selectedBorderColor,
    required this.onTap,
  });

  final String label;
  final bool isFaceUp;
  final bool isSelected;
  final bool isPopping;
  final bool isSpawning;
  final bool isMismatch;
  final Color themeColor;
  final Color selectedBorderColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final double scale = isPopping ? 0.2 : (isSpawning ? 0.3 : 1.0);
    final double opacity = isPopping ? 0.0 : 1.0;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedScale(
        scale: scale,
        duration: Duration(milliseconds: isSpawning ? 280 : 200),
        curve: isSpawning ? Curves.easeOutBack : Curves.easeIn,
        child: AnimatedOpacity(
          opacity: opacity,
          duration: const Duration(milliseconds: 180),
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: isFaceUp ? math.pi : 0),
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOutCubic,
            builder: (context, angle, child) {
              final bool showFront = angle >= (math.pi / 2);

              return Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.0012)
                  ..rotateY(angle),
                child: showFront
                    ? Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.identity()..rotateY(math.pi),
                        child: _buildFrontFace(),
                      )
                    : _buildBackFace(),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildBackFace() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: themeColor.withValues(alpha: 0.98), width: 4),
        boxShadow: [
          BoxShadow(
            color: themeColor.withValues(alpha: 0.25),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Icon(
        Icons.all_inclusive_rounded,
        size: 22,
        color: Colors.white.withValues(alpha: 0.25),
      ),
    );
  }

  Widget _buildFrontFace() {
    return Container(
      decoration: BoxDecoration(
        color: isMismatch
            ? Colors.redAccent.withValues(alpha: 0.7)
            : Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSpawning ? Colors.amberAccent : selectedBorderColor,
          width: isSelected ? 7.0 : 5.0,
        ),
        boxShadow: [
          BoxShadow(
            color: isPopping
                ? Colors.amberAccent.withValues(alpha: 0.7)
                : themeColor.withValues(alpha: 0.35),
            blurRadius: isPopping ? 14 : 6,
            spreadRadius: isPopping ? 2 : 0,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: themeColor,
              shadows: const [
                Shadow(
                  color: Colors.black,
                  blurRadius: 2,
                  offset: Offset(1, 2),
                ),
              ],
            ),
          ),
          if (isFaceUp)
            Positioned(
              top: 5,
              right: 5,
              child: Icon(
                Icons.auto_awesome,
                size: isPopping ? 20 : 15,
                color: isPopping ? Colors.amberAccent : Colors.white,
              ),
            ),
        ],
      ),
    );
  }
}
