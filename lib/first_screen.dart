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
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Next to Numbers'),
                    const SizedBox(
                      height: 16,
                    ), // Kis távolság a szöveg és a gomb között
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => navigateToCardFinderScreen(
                        context,
                        10,
                        GameType.numberGame,
                      ),
                      child: Text(
                        '10 Numbers - Best: ${formatBestTime(bestTimes[scoreKey(GameType.numberGame, 10)])}',
                      ),
                    ),
                    const SizedBox(
                      height: 16,
                    ), // Kis távolság a szöveg és a gomb között
                    ElevatedButton(
                      onPressed: () => navigateToCardFinderScreen(
                        context,
                        18,
                        GameType.numberGame,
                      ),
                      child: Text(
                        '18 Numbers - Best: ${formatBestTime(bestTimes[scoreKey(GameType.numberGame, 18)])}',
                      ),
                    ),
                    const SizedBox(
                      height: 16,
                    ), // Kis távolság a szöveg és a gomb között
                    ElevatedButton(
                      onPressed: () => navigateToCardFinderScreen(
                        context,
                        26,
                        GameType.numberGame,
                      ),
                      child: Text(
                        '26 Numbers - Best: ${formatBestTime(bestTimes[scoreKey(GameType.numberGame, 26)])}',
                      ),
                    ),
                    const SizedBox(
                      height: 30,
                    ), // Kis távolság a szöveg és a gomb között
                    const Text('Next to Letters'),
                    const SizedBox(
                      height: 16,
                    ), // Kis távolság a szöveg és a gomb között
                    ElevatedButton(
                      onPressed: () => navigateToCardFinderScreen(
                        context,
                        10,
                        GameType.letterGame,
                      ),
                      child: Text(
                        '10 Letters - Best: ${formatBestTime(bestTimes[scoreKey(GameType.letterGame, 10)])}',
                      ),
                    ),
                    const SizedBox(
                      height: 16,
                    ), // Kis távolság a szöveg és a gomb között
                    ElevatedButton(
                      onPressed: () => navigateToCardFinderScreen(
                        context,
                        18,
                        GameType.letterGame,
                      ),
                      child: Text(
                        '18 Letters - Best: ${formatBestTime(bestTimes[scoreKey(GameType.letterGame, 18)])}',
                      ),
                    ),
                    const SizedBox(
                      height: 16,
                    ), // Kis távolság a szöveg és a gomb között
                    ElevatedButton(
                      onPressed: () => navigateToCardFinderScreen(
                        context,
                        26,
                        GameType.letterGame,
                      ),
                      child: Text(
                        'Full ABC - Best: ${formatBestTime(bestTimes[scoreKey(GameType.letterGame, 26)])}',
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
