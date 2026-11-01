import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'card_finder_screen.dart';
import 'func.dart';
import 'high_score.dart';
import 'next_to_infinity_screen.dart';
import 'theme_color_picker.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Color appThemeColor = Colors.blueAccent;
  Map<String, int?> bestTimes = {};
  int infinityBestScore = 0;

  @override
  void initState() {
    super.initState();
    loadScore();
  }

  Future<void> navigateToCardFinderScreen(
    BuildContext context,
    int count,
    GameType gameType,
  ) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FlipNextCard(
          boardSize: count,
          themeColor: appThemeColor,
          gameType: gameType,
        ),
      ),
    );
    loadScore();
  }

  Future<void> navigateToInfinityScreen(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NextToInfinityScreen(themeColor: appThemeColor),
      ),
    );
    loadScore();
  }

  Future<void> loadScore() async {
    final Map<String, int?> loadedScores = {};

    for (final type in GameType.values) {
      for (final size in [10, 18, 26]) {
        final key = scoreKey(type, size);
        loadedScores[key] = await getBestTime(type, size);
      }
    }

    final prefs = await SharedPreferences.getInstance();
    final loadedInfinityScore = prefs.getInt('infinity_best_score') ?? 0;

    if (!mounted) return;
    setState(() {
      bestTimes = loadedScores;
      infinityBestScore = loadedInfinityScore;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: appThemeColor.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.4),
                  width: 1,
                ),
              ),
              child: const Icon(
                Icons.style_rounded,
                size: 20,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [Colors.white, Colors.white70],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ).createShader(bounds),
                child: const Text(
                  'NextFinder',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: Colors.black45,
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline_rounded, color: Colors.white),
            onPressed: () => showGameRules(context),
            tooltip: 'Game Rules',
          ),
          ThemeColorPicker(
            onColorSelected: (selectedColor) {
              setState(() {
                appThemeColor = selectedColor;
              });
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // 1. RÉTEG: Háttérkép
          Positioned.fill(
            child: ColorFiltered(
              colorFilter: ColorFilter.mode(appThemeColor, BlendMode.modulate),
              child: Image.asset(
                'assets/images/nextFinderBG.png',
                fit: BoxFit.cover,
              ),
            ),
          ),

          // 2. RÉTEG: Tartalom
          Positioned.fill(
            child: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      vertical: 20,
                      horizontal: 16,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight - 40,
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 720),
                          child: _buildOrganizedMenu(
                            MediaQuery.orientationOf(context) ==
                                Orientation.landscape,
                          ),
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

  Widget _buildOrganizedMenu(bool isLandscape) {
    final numbersColumn = _GameModeGroup(
      header: const _GroupTitle(title: 'Numbers', icon: Icons.filter_1_rounded),
      buttons: [
        _modeButton(10, GameType.numberGame, '10 Numbers'),
        _modeButton(18, GameType.numberGame, '18 Numbers'),
        _modeButton(26, GameType.numberGame, '26 Numbers'),
      ],
      themeColor: appThemeColor,
    );

    final lettersColumn = _GameModeGroup(
      header: const _GroupTitle(
        title: 'Letters',
        icon: Icons.sort_by_alpha_rounded,
      ),
      buttons: [
        _modeButton(10, GameType.letterGame, '10 Letters'),
        _modeButton(18, GameType.letterGame, '18 Letters'),
        _modeButton(26, GameType.letterGame, 'Full ABC'),
      ],
      themeColor: appThemeColor,
    );

    // Kiemelt Végtelen Mód kártya alulra
    final infinityCard = _SpecialInfinityCard(
      scoreText: '$infinityBestScore pts',
      themeColor: appThemeColor,
      onPressed: () => navigateToInfinityScreen(context),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isLandscape)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: numbersColumn),
              const SizedBox(width: 16),
              Expanded(child: lettersColumn),
            ],
          )
        else ...[
          numbersColumn,
          const SizedBox(height: 20),
          lettersColumn,
        ],
        const SizedBox(height: 24),
        infinityCard,
      ],
    );
  }

  Widget _modeButton(int count, GameType gameType, String label) {
    final bestTime = bestTimes[scoreKey(gameType, count)];
    final timeText = bestTime != null ? formatBestTime(bestTime) : '-:-';

    return _ModernGameButton(
      label: label,
      badgeText: timeText,
      badgeIcon: Icons.emoji_events_rounded,
      themeColor: appThemeColor,
      onPressed: () => navigateToCardFinderScreen(context, count, gameType),
    );
  }
}

class _GameModeGroup extends StatelessWidget {
  const _GameModeGroup({
    required this.header,
    required this.buttons,
    required this.themeColor,
  });

  final Widget header;
  final List<Widget> buttons;
  final Color themeColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: themeColor.withValues(alpha: 0.35), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          header,
          const SizedBox(height: 12),
          for (var i = 0; i < buttons.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            buttons[i],
          ],
        ],
      ),
    );
  }
}

class _GroupTitle extends StatelessWidget {
  const _GroupTitle({required this.title, required this.icon});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.amberAccent),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

class _ModernGameButton extends StatelessWidget {
  const _ModernGameButton({
    required this.label,
    required this.badgeText,
    required this.badgeIcon,
    required this.themeColor,
    required this.onPressed,
  });

  final String label;
  final String badgeText;
  final IconData badgeIcon;
  final Color themeColor;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: themeColor.withValues(alpha: 0.5),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: themeColor.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(badgeIcon, size: 13, color: Colors.amberAccent),
                    const SizedBox(width: 5),
                    Text(
                      badgeText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Kiemelt Végtelen Mód kártya alulra
class _SpecialInfinityCard extends StatelessWidget {
  const _SpecialInfinityCard({
    required this.scoreText,
    required this.themeColor,
    required this.onPressed,
  });

  final String scoreText;
  final Color themeColor;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.black.withValues(alpha: 0.6),
                themeColor.withValues(alpha: 0.35),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.amberAccent.withValues(alpha: 0.7),
              width: 1.8,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.amberAccent.withValues(alpha: 0.2),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.all_inclusive_rounded,
                    color: Colors.amberAccent,
                    size: 26,
                  ),
                  SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Next to Infinity',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        '2-Min Endless Challenge',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.amberAccent.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.amberAccent.withValues(alpha: 0.5),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.stars_rounded,
                      size: 14,
                      color: Colors.amberAccent,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      scoreText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
