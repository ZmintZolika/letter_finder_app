import 'package:flutter/material.dart';

import 'dart:async';

import 'func.dart';
import 'theme_color_picker.dart';
import 'summary_screen.dart';

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
  // 1. Az 'A'-tól 'Z'-ig tartó lista

  late final List<String> cards = List.generate(
    widget.boardSize,
    (index) => widget.gameType == GameType.numberGame
        ? (index + 1).toString()
        : String.fromCharCode(65 + index),
  );

  @override
  void initState() {
    super.initState();
    cards.shuffle();
  }

  //ebben a Set-ben tároljuk azokat a betűket, amiket már felfordított a játékos
  final Set<String> revealedCards = {};
  String? firstSelectedCard;
  String? secondSelectedCard;
  bool isChecking = false;
  bool isError = false;

  //játék színeinek beállítása

  late Color cardThemeColor = getLighterColorHSL(widget.themeColor);
  late Color cardLetterColor = widget.themeColor;
  Color selectedColor = Colors.red;
  Color get shadedBox => cardLetterColor;

  //időmérő előkészítése
  final Stopwatch stopwatch = Stopwatch();
  Timer? refreshTimer;

  bool hasGameStarted = false;

  //IDŐZÍTŐ LOGIKA
  //időzítő indítás
  void startGameTimer() {
    if (hasGameStarted) return;

    hasGameStarted = true;
    stopwatch.start();

    refreshTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {});
    });
  }

  //időzítő leállítás
  void stopGameTimer() {
    stopwatch.stop();
    refreshTimer?.cancel();
  }

  //eltelt idő kijelzése getter
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

  @override
  Widget build(BuildContext context) {
    // Lekérdezzük a képernyő tájolását
    final orientation = MediaQuery.orientationOf(context);

    // Eldöntjük az oszlopok számát:
    final int columnCount = (orientation == Orientation.portrait) ? 4 : 9;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.gameType == GameType.numberGame
              ? 'NextFinder - Numbers'
              : 'NextFinder - Letters',
        ),
        backgroundColor: cardLetterColor,
        centerTitle: true,
        actions: [
          ThemeColorPicker(
            onColorSelected: (onColorSelected) {
              setState(() {
                cardThemeColor = onColorSelected;
              });
            },
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
          children: cards.map((card) {
            // Megnézzük, hogy az adott betű már fel van-e fordítva
            final bool isRevealed = revealedCards.contains(card);

            return InkWell(
              onTap: () {
                // Ha nem értelmes helyre nyomnak akkor ne csináljon semmit
                if (isChecking || isRevealed || card == firstSelectedCard)
                  return;

                startGameTimer();

                //Ha még nem választott első betűt
                if (firstSelectedCard == null) {
                  setState(() {
                    firstSelectedCard = card;
                    //revealedLetters.add(firstSelectedLetter!);
                  });

                  //Itt nézem meg van-e az először felfordított betűnek szomszédja
                  if ((firstSelectedCard != null) &&
                      !isHaveNextCard(
                        firstSelectedCard!,
                        revealedCards,
                        widget.boardSize,
                        widget.gameType,
                      )) {
                    setState(() {
                      revealedCards.add(firstSelectedCard!);
                      firstSelectedCard = null;
                    });
                  }
                  //session vége vizsgálat, és összegző megjelenítése
                  if (revealedCards.length != widget.boardSize) {
                    return;
                  } else {
                    stopGameTimer();
                    SummaryScreen(context);
                  }
                }

                //Ha már van első betű
                if (firstSelectedCard != null && secondSelectedCard == null) {
                  setState(() {
                    secondSelectedCard = card;
                    //revealedLetters.add(secondSelectedLetter!);
                  });

                  if (widget.gameType == GameType.letterGame) {
                    if (firstSelectedCard != null &&
                        secondSelectedCard != null &&
                        (secondSelectedCard!.codeUnitAt(0) -
                                    firstSelectedCard!.codeUnitAt(0))
                                .abs() ==
                            1) {
                      setState(() {
                        revealedCards.add(firstSelectedCard!);
                        revealedCards.add(secondSelectedCard!);
                        firstSelectedCard = null;
                        secondSelectedCard = null;
                        //session vége vizsgálat, és összegző megjelenítése
                        if (revealedCards.length != cards.length) {
                          return;
                        } else {
                          stopGameTimer();
                          SummaryScreen(context);
                        }
                      });
                    } else if (secondSelectedCard != null) {
                      isChecking = true; //védelem a késleltetés ideje alatti kattintgatásra
                      Future.delayed(const Duration(seconds: 2), () {
                        setState(() {
                          revealedCards.remove(firstSelectedCard);
                          revealedCards.remove(secondSelectedCard);
                          firstSelectedCard = null;
                          secondSelectedCard = null;
                          isChecking = false; //védelem a késleltetés ideje alatti kattintgatásra
                        });
                      });
                    }
                  } else if (firstSelectedCard != null &&
                      secondSelectedCard != null &&
                      (int.parse(secondSelectedCard!) -
                                  int.parse(firstSelectedCard!))
                              .abs() ==
                          1) {
                    setState(() {
                      revealedCards.add(firstSelectedCard!);
                      revealedCards.add(secondSelectedCard!);
                      firstSelectedCard = null;
                      secondSelectedCard = null;
                      //session vége vizsgálat, és összegző megjelenítése
                      if (revealedCards.length != cards.length) {
                        return;
                      } else {
                        stopGameTimer();
                        SummaryScreen(context);
                      }
                    });
                  } else if (secondSelectedCard != null) {
                    isChecking = true; //védelem a késleltetés ideje alatti kattintgatásra
                    Future.delayed(const Duration(seconds: 2), () {
                      setState(() {
                        revealedCards.remove(firstSelectedCard);
                        revealedCards.remove(secondSelectedCard);
                        firstSelectedCard = null;
                        secondSelectedCard = null;
                        isChecking = false; //védelem a késleltetés ideje alatti kattintgatásra
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
                          isThisCard(
                            firstSelectedCard,
                            secondSelectedCard,
                            card,
                          )
                      ? Colors.deepPurple.shade50
                      : cardThemeColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isRevealed
                        ? cardThemeColor
                        : isThisCard(
                            firstSelectedCard,
                            secondSelectedCard,
                            card,
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
                        isThisCard(firstSelectedCard, secondSelectedCard, card)
                    ? Text(
                        card,
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
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Elapsed Time: $elapsedTimeText',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
