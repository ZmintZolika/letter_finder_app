import 'package:flutter/material.dart';
import 'package:letter_finder_app/card_finder_screen.dart';

import 'theme_color_picker.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  void navigateToCardFinderScreen(BuildContext context, int count, gameType) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FlipNextCard(
          boardSize: count,
          themeColor: appThemeColor,
          gameType: gameType,
        ),
      ),
    );
  }

  Color appThemeColor = Colors.blueAccent;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appThemeColor,
      appBar: AppBar(
        title: const Text(
          'NextFinder',
          style: TextStyle(color: Color.fromARGB(255, 51, 159, 248)),
        ),
        centerTitle: true,
        actions: [
          ThemeColorPicker(
            onColorSelected: (selectedColor) {
              setState(() {
                appThemeColor = selectedColor;
              });
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize
              .min, // Összehúzza az oszlopot, hogy pont középre kerüljön
          children: [
            const Text('Next to Numbers'),
            const SizedBox(
              height: 16,
            ), // Kis távolság a szöveg és a gomb között
            ElevatedButton(
              onPressed: () =>
                  navigateToCardFinderScreen(context, 10, GameType.numberGame),
              child: const Text('10 numbers'),
            ),
            const SizedBox(
              height: 16,
            ), // Kis távolság a szöveg és a gomb között
            ElevatedButton(
              onPressed: () =>
                  navigateToCardFinderScreen(context, 18, GameType.numberGame),
              child: const Text('18 numbers'),
            ),
            const SizedBox(
              height: 16,
            ), // Kis távolság a szöveg és a gomb között
            ElevatedButton(
              onPressed: () =>
                  navigateToCardFinderScreen(context, 26, GameType.numberGame),
              child: const Text('26 numbers'),
            ),
            const SizedBox(
              height: 30,
            ), // Kis távolság a szöveg és a gomb között
            const Text('Next to Letters'),
            const SizedBox(
              height: 16,
            ), // Kis távolság a szöveg és a gomb között
            ElevatedButton(
              onPressed: () =>
                  navigateToCardFinderScreen(context, 10, GameType.letterGame),
              child: const Text('10 letters'),
            ),
            const SizedBox(
              height: 16,
            ), // Kis távolság a szöveg és a gomb között
            ElevatedButton(
              onPressed: () =>
                  navigateToCardFinderScreen(context, 18, GameType.letterGame),
              child: const Text('18 letters'),
            ),
            const SizedBox(
              height: 16,
            ), // Kis távolság a szöveg és a gomb között
            ElevatedButton(
              onPressed: () =>
                  navigateToCardFinderScreen(context, 26, GameType.letterGame),
              child: const Text('Full ABC'),
            ),
          ],
        ),
      ),
    );
  }
}
