import 'package:flutter/material.dart';

class LetterGridScreen extends StatefulWidget {
  const LetterGridScreen({super.key});

  @override
  State<LetterGridScreen> createState() => _LetterGridScreenState();
}

class _LetterGridScreenState extends State<LetterGridScreen> {
  // 1. Az 'A'-tól 'Z'-ig tartó lista
  final List<String> letters = List.generate(
    26,
    (index) => String.fromCharCode(65 + index),
  );

  // 2. Ebben a Set-ben (halmazban) tároljuk azokat a betűket, amiket már felfordított a játékos
  final Set<String> revealedLetters = {};

  @override
  Widget build(BuildContext context) {
    // Megnézzük, hogy a telefon éppen álló (portrait) vagy fekvő (landscape) helyzetben van-e:
    final isPortrait =
        MediaQuery.of(context).orientation == Orientation.portrait;

    // Álló módban 5 oszlop, fekvő módban 9 oszlop:
    final int columnCount = isPortrait ? 5 : 9;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Letter Finder Grid'),
        backgroundColor: Colors.blueAccent,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: GridView.count(
          crossAxisCount: columnCount,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.0,
          children: letters.map((letter) {
            // Megnézzük, hogy az adott betű már fel van-e fordítva
            final bool isRevealed = revealedLetters.contains(letter);

            return InkWell(
              onTap: () {
                // Ha még nincs felfordítva, hozzáadjuk és újrarajzoljuk a képernyőt
                if (!isRevealed) {
                  setState(() {
                    revealedLetters.add(letter);
                  });
                }
              },
              borderRadius: BorderRadius.circular(12),
              child: AnimatedContainer(
                duration: const Duration(
                  milliseconds: 250,
                ), // szép, sima színátmenet kattintáskor
                decoration: BoxDecoration(
                  // Lefordítva fekete, felfordítva világos lila
                  color: isRevealed
                      ? Colors.deepPurple.shade50
                      : Colors.black87,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isRevealed ? Colors.deepPurple : Colors.black,
                    width: 2,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 4,
                      offset: Offset(2, 2),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                // Ha fel van fedve, megjelenik a betű, ha nincs, üres marad
                child: isRevealed
                    ? Text(
                        letter,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple,
                        ),
                      )
                    : null,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
