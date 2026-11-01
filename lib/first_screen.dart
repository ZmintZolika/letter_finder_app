import 'package:flutter/material.dart';
import 'package:letter_finder_app/card_finder_screen.dart';
import 'package:letter_finder_app/func.dart';

import 'theme_color_picker.dart';
import 'high_score.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Future<void> navigateToCardFinderScreen(
    BuildContext context,
    int count,
    gameType,
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

  Color appThemeColor = Colors.blueAccent;
  Map<String, int?> bestTimes = {}; // Ebben lesz mind a 6 játékmód ideje

  @override
  void initState() {
    super.initState();
    loadScore();
  }

  Future<void> loadScore() async {
    final Map<String, int?> loadedScores = {};

    // Végigmegyünk a 2 játéktípuson és a 3 táblaméreten (2 x 3 = 6 mód)
    for (final type in GameType.values) {
      for (final size in [10, 18, 26]) {
        final key = scoreKey(type, size);
        loadedScores[key] = await getBestTime(type, size);
      }
    }

    setState(() {
      bestTimes = loadedScores;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: appThemeColor,
        title: Text(
          'NextFinder',
          style: TextStyle(
            color:
                ThemeData.estimateBrightnessForColor(appThemeColor) ==
                    Brightness.dark
                ? Colors.white
                : Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline_rounded),
            onPressed: () => showGameRules(context),
            tooltip: 'Game Rules',
          ),
          ThemeColorPicker(
            onColorSelected: (selectedColor) {
              setState(() {
                appThemeColor = selectedColor!;
              });
            },
          ),
        ],
      ),
      // A body helyére egy Stack kerül:
      body: Stack(
        children: [
          // 1. RÉTEG: A színezhető háttérkép alul
          Positioned.fill(
            child: ColorFiltered(
              colorFilter: ColorFilter.mode(
                appThemeColor, // Ez reagál a ThemeColorPicker-re!
                BlendMode.modulate,
              ),
              child: Image.asset(
                'assets/images/nextFinderBG.png',
                fit: BoxFit.cover,
              ),
            ),
          ),

          // 2. RÉTEG: A görgethető tartalom felül (gombok, feliratok)
          Positioned.fill(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              child: Center(
                child: _buildGameModes(
                  MediaQuery.orientationOf(context) == Orientation.landscape,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameModes(bool isLandscape) {
    final numbersColumn = _GameModeColumn(
      header: const _SectionHeader(
        icon: Icons.looks_one_outlined,
        title: 'Next to Numbers',
      ),
      buttons: [
        _modeButton(10, GameType.numberGame, '10 Numbers'),
        _modeButton(18, GameType.numberGame, '18 Numbers'),
        _modeButton(26, GameType.numberGame, '26 Numbers'),
      ],
    );
    final lettersColumn = _GameModeColumn(
      header: const _SectionHeader(
        icon: Icons.sort_by_alpha,
        title: 'Next to Letters',
      ),
      buttons: [
        _modeButton(10, GameType.letterGame, '10 Letters'),
        _modeButton(18, GameType.letterGame, '18 Letters'),
        _modeButton(26, GameType.letterGame, 'Full ABC'),
      ],
    );

    if (isLandscape) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: numbersColumn),
          const SizedBox(width: 16),
          Expanded(child: lettersColumn),
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        numbersColumn,
        const SizedBox(height: 30),
        lettersColumn,
      ],
    );
  }

  Widget _modeButton(int count, GameType gameType, String label) {
    return ElevatedButton(
      onPressed: () => navigateToCardFinderScreen(context, count, gameType),
      child: Text(
        '$label - Best: ${formatBestTime(bestTimes[scoreKey(gameType, count)])}',
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
  const _SectionHeader({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 22),
          const SizedBox(width: 8),
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
