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
  late final List<String> cards = List.generate(
    widget.boardSize,
    (index) => widget.gameType == GameType.numberGame
        ? (index + 1).toString()
        : String.fromCharCode(65 + index),
  );

  Set<String> revealedCards = {};
  Set<String> poppingCards =
      {}; // A frissen megtalált pár átmeneti nagyításához
  String? firstSelectedCard;
  String? secondSelectedCard;
  bool isChecking = false;

  late Color cardThemeColor = widget.themeColor;
  late Color cardLetterColor = widget.themeColor;
  Color selectedColor = Colors.amberAccent;

  final Stopwatch stopwatch = Stopwatch();
  Timer? refreshTimer;
  bool hasGameStarted = false;

  // Hang és rezgés állapotok (alapértelmezetten bekapcsolva, a telefon profilját követve)
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

  // Apró rezgés visszajelzés
  void _triggerHaptic({bool isMatch = false}) {
    if (!isVibrationEnabled) return;
    if (isMatch) {
      HapticFeedback.mediumImpact();
    } else {
      HapticFeedback.lightImpact();
    }
  }

  // Hangeffekt lejátszása
  void _playSparkleSound() {
    if (!isSoundEnabled) return;
    // Alapértelmezett rendszerhang (tiszteletben tartja a telefon néma módját):
    SystemSound.play(SystemSoundType.click);

    // TIPP: Ha hozzáadod az 'audioplayers' csomagot és egy 'assets/sounds/sparkle.mp3'-at,
    // itt tudod lejátszani:
    // AudioPlayer().play(AssetSource('sounds/sparkle.mp3'));
  }

  // Pár megtalálásakor: 112%-ra nő, majd 90%-ra zsugorodik
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

  void _onCardTap(String card) {
    final bool isRevealed = revealedCards.contains(card);
    if (isChecking || isRevealed || card == firstSelectedCard) {
      return;
    }

    startGameTimer();
    _triggerHaptic(isMatch: false);

    // 1. Ha még nincs elsőnek kiválasztott kártya
    if (firstSelectedCard == null) {
      setState(() {
        firstSelectedCard = card;
      });

      // Ha nincs szabad szomszédja, azonnal megtaláltnak számít
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

    // 2. Ha már van első kártya, és most választjuk a másodikat
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
        Future.delayed(const Duration(milliseconds: 1200), () {
          if (mounted) {
            setState(() {
              firstSelectedCard = null;
              secondSelectedCard = null;
              isChecking = false;
            });
          }
        });
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
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        title: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Ide maradhat a meglévő ShaderMask cím és alatta a timer/score Row...
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [Colors.white, Colors.white70],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ).createShader(bounds),
                child: Text(
                  widget.gameType == GameType.numberGame
                      ? 'NextFinder • Numbers'
                      : 'NextFinder • Letters',
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
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.25),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.timer_outlined,
                      size: 13,
                      color: Colors.amberAccent,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      elapsedTimeText,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: Icon(
              isSoundEnabled
                  ? Icons.volume_up_rounded
                  : Icons.volume_off_rounded,
              color: isSoundEnabled ? Colors.white : Colors.white54,
              size: 22,
            ),
            onPressed: _toggleSound,
            tooltip: isSoundEnabled ? 'Sound On' : 'Sound Off',
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: Icon(
              isVibrationEnabled
                  ? Icons.vibration_rounded
                  : Icons.smartphone_rounded,
              color: isVibrationEnabled ? Colors.white : Colors.white54,
              size: 22,
            ),
            onPressed: _toggleVibration,
            tooltip: isVibrationEnabled ? 'Vibration On' : 'Vibration Off',
          ),
          IconButton(
            icon: const Icon(
              Icons.help_outline_rounded,
              color: Colors.white,
              size: 22,
            ),
            onPressed: () => showGameRules(context),
            tooltip: 'Game Rules',
          ),
          ThemeColorPicker(
            onColorSelected: (selectedColor) {
              setState(() {
                cardThemeColor = selectedColor;
                cardLetterColor = selectedColor;
              });
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // 1. RÉTEG: Dinamikus háttérkép
          Positioned.fill(
            child: ColorFiltered(
              colorFilter: ColorFilter.mode(cardThemeColor, BlendMode.modulate),
              child: Image.asset(
                'assets/images/nextFinderBG.png',
                fit: BoxFit.cover,
              ),
            ),
          ),

          // 2. RÉTEG: Középre rendezett kártyarács
          Positioned.fill(
            child: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(14.0),
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
                            final bool isPopping = poppingCards.contains(card);

                            // Méretezés:
                            // - Ha épp most találták meg: 1.12x (megnagyobbodik)
                            // - Ha már megtalált pár: 0.90x (90%-os méret)
                            // - Alaphelyzetben: 1.0x
                            final double targetScale = isPopping
                                ? 1.12
                                : (isRevealed ? 0.90 : 1.0);

                            return _AnimatedGameCard(
                              label: card,
                              isFaceUp: isRevealed || isSelected,
                              isRevealed: isRevealed,
                              isSelected: isSelected,
                              isPopping: isPopping,
                              scale: targetScale,
                              themeColor: cardThemeColor,
                              selectedBorderColor: selectedColor,
                              onTap: () => _onCardTap(card),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  );
                },
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
                ..setEntry(3, 2, 0.0012) // 3D perspektíva
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

  // Kártya hátlapja (lefordított állapot - sötét üveghatás)
  Widget _buildBackFace() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.48),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: themeColor.withValues(alpha: 0.65), width: 2),
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
        Icons.auto_awesome_rounded, // Vagy Icons.question_mark_rounded
        size: 20,
        color: Colors.white.withValues(alpha: 0.22),
      ),
    );
  }

  // Kártya előlapja (felfordított állapot)
  Widget _buildFrontFace() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isRevealed
              ? [
                  Colors.white.withValues(alpha: 0.88),
                  Color.lerp(Colors.white, themeColor, 0.25)!,
                ]
              : [Colors.white, Color.lerp(Colors.white, themeColor, 0.15)!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSelected
              ? selectedBorderColor
              : (isRevealed ? themeColor.withValues(alpha: 0.8) : themeColor),
          width: isSelected ? 3.5 : 2.5,
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
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: Color.lerp(Colors.black87, themeColor, 0.65),
            ),
          ),
          // Vizuális csillám ikon a sarokban, ha már megtalált pár
          if (isRevealed)
            Positioned(
              top: 5,
              right: 5,
              child: Icon(
                Icons.auto_awesome,
                size: isPopping ? 18 : 13,
                color: isPopping
                    ? Colors.amber.shade700
                    : themeColor.withValues(alpha: 0.65),
              ),
            ),
        ],
      ),
    );
  }
}
