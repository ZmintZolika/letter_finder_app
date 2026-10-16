import 'package:flutter/material.dart';
import 'package:letter_finder_app/second_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void navigateToLetterGridScreen(BuildContext context, int count) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => FlipNextLetter(boardSize: count)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Az én appom',
          style: TextStyle(color: Color.fromARGB(255, 51, 159, 248)),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize
              .min, // Összehúzza az oszlopot, hogy pont középre kerüljön
          children: [
            const Text('Működik az App alapja'),
            const SizedBox(
              height: 16,
            ), // Kis távolság a szöveg és a gomb között
            ElevatedButton(
              onPressed: () => navigateToLetterGridScreen(context, 10),
              child: const Text('10 letters'),
            ),
            const SizedBox(
              height: 16,
            ), // Kis távolság a szöveg és a gomb között
            ElevatedButton(
              onPressed: () => navigateToLetterGridScreen(context, 18),
              child: const Text('18 letters'),
            ),
            const SizedBox(
              height: 16,
            ), // Kis távolság a szöveg és a gomb között
            ElevatedButton(
              onPressed: () => navigateToLetterGridScreen(context, 26),
              child: const Text('Full ABC'),
            ),
          ],
        ),
      ),
    );
  }
}
