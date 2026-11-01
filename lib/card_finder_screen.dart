import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'func.dart';
import 'high_score.dart';
import 'summary_screen.dart';
import 'theme_color_picker.dart';

enum GameType { numberGame, letterGame }

class FlipNextCard extends StatefulWidget {
  final int boardSize;
  final Color themeColor;
  final GameType gameType;

  const FlipNextCard({
    super.key,
    required this.boardSize,
    required this.themeColor,
    required this.gameType,
  });

  @override
  State<FlipNextCard> createState() => _FlipNextCardState();
}

class _FlipNextCardState extends State<FlipNextCard> {
  // ÚJ: a kártyaforgatás ideje (a kártya animációja 380 ms, ezért kicsit több)
  static const int flipDurationMs = 400;

  late final List<String> cards = List.generate(
    widget.boardSize,
    (index) => widget.gameType == GameType.numberGame
        ? (index + 1).toString()
        : String.fromCharCode(65 + index),
  );

  Set<String> revealedCards = {};
  Set<String> poppingCards = {};
  String? firstSelectedCard;
  String? secondSelectedCard;
  bool isChecking = false;
  bool isMismatch = false; // ÚJ: rossz pár esetén a várakozás idejére igaz

  late Color cardThemeColor = widget.themeColor;
  late Color cardLetterColor = widget.themeColor;
  Color selectedColor = Colors.amberAccent;

  final Stopwatch stopwatch = Stopwatch();
  Timer? refreshTimer;
  bool hasGameStarted = false;

  bool isSoundEnabled = true;
  bool isVibrationEnabled = true;

  @override
  void initState() {
    super.initState();
    cards.shuffle();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isSoundEnabled = prefs.getBool('sound_enabled') ?? true;
      isVibrationEnabled = prefs.getBool('vibration_enabled') ?? true;
    });
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

  void _triggerMatchEffect(List<String> matchedCards) {
    _triggerHaptic(isMatch: true);
    _playSparkleSound();

    setState(() {
      for (final c in matchedCards) {
        revealedCards.add(c);
        poppingCards.add(c);
      }
      firstSelectedCard = null;
      secondSelectedCard = null;
    });

    Future.delayed(const Duration(milliseconds: 260), () {
      if (mounted) {
        setState(() {
          for (final c in matchedCards) {
            poppingCards.remove(c);
          }
        });
      }
    });
  }

  void startGameTimer() {
    if (hasGameStarted) return;
    hasGameStarted = true;
    stopwatch.start();
    refreshTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {});
    });
  }

  void stopGameTimer() {
    stopwatch.stop();
    refreshTimer?.cancel();
  }

  void resetGameTimer() {
    stopwatch
      ..stop()
      ..reset();
    refreshTimer?.cancel();
    hasGameStarted = false;
    setState(() {});
  }

  String get elapsedTimeText {
    final elapsed = stopwatch.elapsed;
    final minutes = elapsed.inMinutes.toString().padLeft(2, '0');
    final seconds = (elapsed.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  void dispose() {
    refreshTimer?.cancel();
    stopwatch.stop();
    super.dispose();
  }

  void onPlayAgain() {
    resetGameTimer();
    setState(() {
      revealedCards.clear();
      poppingCards.clear();
      firstSelectedCard = null;
      secondSelectedCard = null;
      isChecking = false; // ÚJ
      isMismatch = false; // ÚJ
      cards.shuffle();
    });
    Navigator.pop(context);
  }

  void _checkGameEnd() {
    if (revealedCards.length == cards.length) {
      stopGameTimer();
      checkAndSaveBestTime(
        widget.gameType,
        widget.boardSize,
        stopwatch.elapsed.inSeconds,
      );
      Future.delayed(const Duration(milliseconds: 450), () {
        if (mounted) {
          summaryScreen(context, elapsedTimeText, onPlayAgain);
        }
      });
    }
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
    await Future.delayed(const Duration(milliseconds: 1000));
    if (!mounted) return;

    // 4. Visszaállítás: a kártyák visszafordulnak
    setState(() {
      firstSelectedCard = null;
      secondSelectedCard = null;
      isChecking = false;
      isMismatch = false;
    });
  }

  void _onCardTap(String card) {
    final bool isRevealed = revealedCards.contains(card);
    if (isChecking || isRevealed || card == firstSelectedCard) {
      return;
    }

    startGameTimer();
    _triggerHaptic(isMatch: false);

    if (firstSelectedCard == null) {
      setState(() {
        firstSelectedCard = card;
      });

      if (!isHaveNextCard(
        firstSelectedCard!,
        revealedCards,
        widget.boardSize,
        widget.gameType,
      )) {
        _triggerMatchEffect([firstSelectedCard!]);
        _checkGameEnd();
      }
      return;
    }

    if (firstSelectedCard != null && secondSelectedCard == null) {
      setState(() {
        secondSelectedCard = card;
      });

      bool isMatch = false;
      if (widget.gameType == GameType.letterGame) {
        isMatch =
            (secondSelectedCard!.codeUnitAt(0) -
                    firstSelectedCard!.codeUnitAt(0))
                .abs() ==
            1;
      } else {
        isMatch =
            (int.parse(secondSelectedCard!) - int.parse(firstSelectedCard!))
                .abs() ==
            1;
      }

      if (isMatch) {
        _triggerMatchEffect([firstSelectedCard!, secondSelectedCard!]);
        _checkGameEnd();
      } else {
        isChecking = true;
        _handleMismatch(); // ÚJ
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final orientation = MediaQuery.orientationOf(context);
    final int columnCount = (orientation == Orientation.portrait) ? 4 : 9;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: cardThemeColor.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.4),
                  width: 1,
                ),
              ),
              child: const Icon(
                Icons.grid_view_rounded,
                size: 18,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 10),
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [Colors.white, Colors.white70],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ).createShader(bounds),
              child: Text(
                widget.gameType == GameType.numberGame ? 'Numbers' : 'Letters',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      color: Colors.black45,
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
          ],
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
            tooltip: isSoundEnabled ? 'Sound On' : 'Sound Off',
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
            tooltip: isVibrationEnabled ? 'Vibration On' : 'Vibration Off',
          ),
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            icon: const Icon(
              Icons.help_outline_rounded,
              color: Colors.white,
              size: 20,
            ),
            onPressed: () => showGameRules(context),
            tooltip: 'Game Rules',
          ),
          ThemeColorPicker(
            onColorSelected: (newColor) {
              setState(() {
                cardThemeColor = newColor;
                cardLetterColor = newColor;
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
                          const Icon(
                            Icons.timer_outlined,
                            size: 18,
                            color: Colors.amberAccent,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Elapsed Time: $elapsedTimeText',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 680),
                          child: GridView.count(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisCount: columnCount,
                            mainAxisSpacing: 10,
                            crossAxisSpacing: 10,
                            childAspectRatio: 1.0,
                            children: cards.map((card) {
                              final bool isRevealed = revealedCards.contains(
                                card,
                              );
                              final bool isSelected = isThisCard(
                                firstSelectedCard,
                                secondSelectedCard,
                                card,
                              );
                              final bool isPopping = poppingCards.contains(
                                card,
                              );

                              final double targetScale = isPopping
                                  ? 1.12
                                  : (isRevealed ? 0.90 : 1.0);

                              return _AnimatedGameCard(
                                label: card,
                                isFaceUp: isRevealed || isSelected,
                                isRevealed: isRevealed,
                                isSelected: isSelected,
                                isPopping: isPopping,
                                isMismatch: isMismatch && isSelected, // ÚJ
                                scale: targetScale,
                                themeColor: cardThemeColor,
                                selectedBorderColor: selectedColor,
                                onTap: () => _onCardTap(card),
                              );
                            }).toList(),
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

class _AnimatedGameCard extends StatelessWidget {
  const _AnimatedGameCard({
    required this.label,
    required this.isFaceUp,
    required this.isRevealed,
    required this.isSelected,
    required this.isPopping,
    required this.isMismatch, // ÚJ
    required this.scale,
    required this.themeColor,
    required this.selectedBorderColor,
    required this.onTap,
  });

  final String label;
  final bool isFaceUp;
  final bool isRevealed;
  final bool isSelected;
  final bool isPopping;
  final bool isMismatch; // ÚJ
  final double scale;
  final Color themeColor;
  final Color selectedBorderColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedScale(
        scale: scale,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutBack,
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: isFaceUp ? math.pi : 0),
          duration: const Duration(milliseconds: 380),
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
    );
  }

  Widget _buildBackFace() {
    return Container(
      decoration: BoxDecoration(
        color: isSelected
            ? getLighterColorHSL(themeColor)
            : Colors.black.withValues(alpha: 0.48),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: themeColor.withValues(alpha: 0.9), width: 4),
        boxShadow: [
          BoxShadow(
            color: themeColor.withValues(alpha: 0.25),
            blurRadius: 8,
            offset: const Offset(1, 3),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Icon(
        Icons.auto_awesome_rounded,
        size: 20,
        color: Colors.white.withValues(alpha: 0.75),
      ),
    );
  }

  Widget _buildFrontFace() {
    return Container(
      decoration: BoxDecoration(
        // ÚJ: rossz pár esetén piros, egyébként a megszokott színek
        color: isMismatch
            ? Colors.redAccent.withValues(alpha: 0.85)
            : (isSelected ? themeColor : Colors.white.withValues(alpha: 0.7)),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isRevealed
              ? getLighterColorHSL(themeColor)
              : selectedBorderColor,
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
              color: isSelected ? Colors.white : themeColor,
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
