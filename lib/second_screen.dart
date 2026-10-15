import 'package:flutter/material.dart';

import 'func.dart';

class LetterGridScreen extends StatefulWidget {
  const LetterGridScreen({super.key, required this.boardSize});

  final int boardSize;

  @override
  State<LetterGridScreen> createState() => _LetterGridScreenState();
}

class _LetterGridScreenState extends State<LetterGridScreen> {
  // 1. Az 'A'-tól 'Z'-ig tartó lista
  late final List<String> letters = List.generate(
    widget.boardSize,
    (index) => String.fromCharCode(65 + index),
  );

  @override
  void initState() {
    super.initState();
    letters.shuffle();
  }

  // 2. Ebben a Set-ben (halmazban) tároljuk azokat a betűket, amiket már felfordított a játékos
  final Set<String> revealedLetters = {};
  String? firstSelectedLetter;
  String? secondSelectedLetter;
  bool isChecking = false;
  bool isError = false;

  Color cardLetterColor = Colors.blueAccent;
  Color cardFrameColor = Colors.lightBlue;
  Color selectedColor = Colors.red;
  Color get shadedBox => cardLetterColor;

  // Inverz háttérhez függcény
  Color getInvertedColor(Color color) {
    final int alpha = (color.a * 255).round();
    final int red = (color.r * 255).round();
    final int green = (color.g * 255).round();
    final int blue = (color.b * 255).round();

    return Color.fromARGB(alpha, 255 - red, 255 - green, 255 - blue);
  }

  @override
  Widget build(BuildContext context) {
    // Lekérdezzük a képernyő tájolását
    final orientation = MediaQuery.orientationOf(context);

    // Eldöntjük az oszlopok számát:
    final int columnCount = (orientation == Orientation.portrait) ? 4 : 9;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Letter Finder Grid'),
        backgroundColor: cardLetterColor,
        centerTitle: true,
        actions: [
          PopupMenuButton<Color>(
            icon: const Icon(Icons.palette),
            onSelected: (Color selectedColor) {
              setState(() {
                cardLetterColor = selectedColor;
                cardFrameColor = selectedColor;
              });
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem(
                value: Colors.blueAccent,
                child: Row(
                  children: [
                    Icon(Icons.circle, color: Colors.blueAccent, size: 16),
                    SizedBox(width: 10),
                    Text('Blue'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: Colors.teal,
                child: Row(
                  children: [
                    Icon(Icons.circle, color: Colors.teal, size: 16),
                    SizedBox(width: 10),
                    Text('Teal'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: Colors.deepPurple,
                child: Row(
                  children: [
                    Icon(Icons.circle, color: Colors.deepPurple, size: 16),
                    SizedBox(width: 10),
                    Text('Purple'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: Colors.amber,
                child: Row(
                  children: [
                    Icon(Icons.circle, color: Colors.amber, size: 16),
                    SizedBox(width: 10),
                    Text('Amber'),
                  ],
                ),
              ),
            ],
          ),
        ],
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
              onTap: () async {
                // Ha nem értelmes helyre nyomnak akkor ne csináljon semmit
                if (isRevealed || letter == firstSelectedLetter) return;

                //Ha még nem választott első betűt
                if (firstSelectedLetter == null) {
                  setState(() {
                    firstSelectedLetter = letter;
                    //revealedLetters.add(firstSelectedLetter!);
                  });
                  return;
                }

                //Ha már van első betű
                if (firstSelectedLetter != null &&
                    secondSelectedLetter == null) {
                  setState(() {
                    secondSelectedLetter = letter;
                    //revealedLetters.add(secondSelectedLetter!);
                  });

                  if (firstSelectedLetter != null &&
                      secondSelectedLetter != null &&
                      (secondSelectedLetter!.codeUnitAt(0) -
                                  firstSelectedLetter!.codeUnitAt(0))
                              .abs() ==
                          1) {
                    setState(() {
                      revealedLetters.add(firstSelectedLetter!);
                      revealedLetters.add(secondSelectedLetter!);
                      firstSelectedLetter = null;
                      secondSelectedLetter = null;
                      return;
                    });
                  } else if (secondSelectedLetter != null) {
                    Future.delayed(const Duration(seconds: 1), () {
                      setState(() {
                        revealedLetters.remove(firstSelectedLetter);
                        revealedLetters.remove(secondSelectedLetter);
                        firstSelectedLetter = null;
                        secondSelectedLetter = null;
                      });
                    });
                  }
                }
              },
              borderRadius: BorderRadius.circular(12),
              child: AnimatedContainer(
                duration: const Duration(
                  milliseconds: 250,
                ), // szép, sima színátmenet kattintáskor
                decoration: BoxDecoration(
                  // Lefordítva fekete, felfordítva színes
                  color:
                      isRevealed ||
                          isThisLetter(
                            firstSelectedLetter,
                            secondSelectedLetter,
                            letter,
                          )
                      ? Colors.deepPurple.shade50
                      : cardFrameColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isRevealed
                        ? cardFrameColor
                        : isThisLetter(
                            firstSelectedLetter,
                            secondSelectedLetter,
                            letter,
                          )
                        ? selectedColor
                        : shadedBox,
                    width: 5,
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
                child:
                    isRevealed ||
                        isThisLetter(
                          firstSelectedLetter,
                          secondSelectedLetter,
                          letter,
                        )
                    ? Text(
                        letter,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: cardLetterColor,
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
