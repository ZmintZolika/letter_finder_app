import 'package:flutter/material.dart';
import 'package:letter_finder_app/second_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

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
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (ctx) => const LetterGridScreen()),
                );
              },
              child: const Text('Kattints ide!'),
            ),
          ],
        ),
      ),
    );
  }
}
