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
  Map<String, int?> bestTimes = {}; // A 6 alap játékmód ideje
  int infinityBestScore = 0; // A Next to Infinity mód rekord pontszáma

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
            ShaderMask(
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
          // 1. RÉTEG: A színezhető háttérkép
          Positioned.fill(
            child: ColorFiltered(
              colorFilter: ColorFilter.mode(appThemeColor, BlendMode.modulate),
              child: Image.asset(
                'assets/images/nextFinderBG.png',
                fit: BoxFit.cover,
              ),
            ),
          ),

          // 2. RÉTEG: Függőlegesen és vízszintesen középre rendezett tartalom
          Positioned.fill(
            child: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      vertical: 24,
                      horizontal: 16,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight - 48,
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 720),
                          child: _buildGameModes(
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

  Widget _buildGameModes(bool isLandscape) {
    final numbersColumn = _GameModeColumn(
      header: _SectionHeader(
        leading: _MiniCardStack(
          labels: const ['1', '2', '3'],
          themeColor: appThemeColor,
        ),
        title: 'Next to Numbers',
      ),
      buttons: [
        _modeButton(10, GameType.numberGame, '10 Numbers'),
        _modeButton(18, GameType.numberGame, '18 Numbers'),
        _modeButton(26, GameType.numberGame, '26 Numbers'),
      ],
    );

    final lettersColumn = _GameModeColumn(
      header: _SectionHeader(
        leading: _MiniCardStack(
          labels: const ['A', 'B', 'C'],
          themeColor: appThemeColor,
        ),
        title: 'Next to Letters',
      ),
      buttons: [
        _modeButton(10, GameType.letterGame, '10 Letters'),
        _modeButton(18, GameType.letterGame, '18 Letters'),
        _modeButton(26, GameType.letterGame, 'Full ABC'),
      ],
    );

    final infinitySection = _GameModeColumn(
      header: _SectionHeader(
        leading: _MiniCardStack(
          labels: const ['12', '13', '∞'],
          themeColor: appThemeColor,
        ),
        title: 'Next to Infinity',
      ),
      buttons: [_infinityButton()],
    );

    if (isLandscape) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: numbersColumn),
              const SizedBox(width: 16),
              Expanded(child: lettersColumn),
            ],
          ),
          const SizedBox(height: 28),
          infinitySection,
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        numbersColumn,
        const SizedBox(height: 30),
        lettersColumn,
        const SizedBox(height: 30),
        infinitySection,
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

  Widget _infinityButton() {
    return _ModernGameButton(
      label: '5-Min Endless Challenge',
      badgeText: '$infinityBestScore pts',
      badgeIcon: Icons.stars_rounded,
      themeColor: appThemeColor,
      onPressed: () => navigateToInfinityScreen(context),
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
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: themeColor.withValues(alpha: 0.6),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: themeColor.withValues(alpha: 0.25),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // A gomb felirata középre igazítva a szabad térben
              Expanded(
                child: Center(
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
              // Rekord idő vagy pontszám badge a jobb szélen
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: themeColor.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(badgeIcon, size: 14, color: Colors.amberAccent),
                    const SizedBox(width: 6),
                    Text(
                      badgeText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
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

class _GameModeColumn extends StatelessWidget {
  const _GameModeColumn({required this.header, required this.buttons});

  final Widget header;
  final List<Widget> buttons;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        header,
        const SizedBox(height: 16),
        for (var i = 0; i < buttons.length; i++) ...[
          if (i > 0) const SizedBox(height: 16),
          SizedBox(width: double.infinity, child: buttons[i]),
        ],
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.leading, required this.title});

  final Widget leading;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 16, 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          leading,
          const SizedBox(width: 10),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniCardStack extends StatelessWidget {
  const _MiniCardStack({required this.labels, required this.themeColor});

  final List<String> labels;
  final Color themeColor;

  @override
  Widget build(BuildContext context) {
    final onTheme =
        ThemeData.estimateBrightnessForColor(themeColor) == Brightness.dark
        ? Colors.white
        : Colors.black87;

    return SizedBox(
      width: 40,
      height: 34,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (var i = 0; i < labels.length; i++)
            Positioned(
              left: i * 8.0,
              top: i == 1 ? 1 : 3,
              child: Transform.rotate(
                angle: (i - 1) * 0.18,
                child: _cardFace(
                  label: labels[i],
                  background: Color.lerp(
                    Colors.white,
                    themeColor,
                    0.18 + (i * 0.41),
                  )!,
                  foreground: i == labels.length - 1
                      ? onTheme
                      : Color.lerp(Colors.black87, themeColor, 0.55)!,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _cardFace({
    required String label,
    required Color background,
    required Color foreground,
  }) {
    return Container(
      width: 22,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.white.withValues(alpha: 0.75)),
        boxShadow: [
          BoxShadow(
            color: themeColor.withValues(alpha: 0.38),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foreground,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          height: 1,
        ),
      ),
    );
  }
}
