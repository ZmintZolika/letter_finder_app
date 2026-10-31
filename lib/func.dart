import 'package:flutter/material.dart';
import 'package:letter_finder_app/card_finder_screen.dart';

//Valamelyik betű megegyezik-e az aktuálissal
bool isThisCard(String? a, String? b, String? letter) =>
    a == letter || b == letter;

//Van-e a kártyának szomszédja (ha van olyan ami nem szerepel a Set-ben ami tárolja a felfordított betűket és szomszédos)
bool isHaveNextCard(String a, Set<String> list, boardSize, gameType) {
  //betűjátékvizsgálat
  if (gameType == GameType.letterGame) {
    int aCode = a.codeUnitAt(0);
    Set<int> codeList = {};

    for (var i in list) {
      codeList.add(i.codeUnitAt(0));
    }

    if (aCode == 65) return !codeList.contains(aCode + 1);
    if (aCode == 65 + boardSize - 1) return !codeList.contains(aCode - 1);
    return !codeList.contains(aCode - 1) || !codeList.contains(aCode + 1);
  } else {
    //számjátékvizsgálat
    int aNum = int.parse(a);
    Set<int> numList = {};

    for (var i in list) {
      numList.add(int.parse(i));
    }

    if (aNum == 1) return !numList.contains(aNum + 1);
    if (aNum == boardSize) return !numList.contains(aNum - 1);
    return !numList.contains(aNum - 1) || !numList.contains(aNum + 1);
  }
}

// Inverz háttérhez függcény
Color getInvertedColor(Color color) {
  final int alpha = (color.a * 255).round();
  final int red = (color.r * 255).round();
  final int green = (color.g * 255).round();
  final int blue = (color.b * 255).round();

  return Color.fromARGB(alpha, 255 - red, 255 - green, 255 - blue);
}

// HSL modell: a szín tónusa megmarad, csak a fényereje nő
Color getLighterColorHSL(Color color, [double amount = 0.2]) {
  final hslColor = HSLColor.fromColor(color);

  // A fényerőt (0.0 - 1.0 között) növeljük, maximum 1.0-ig (fehér)
  final double newLightness = (hslColor.lightness + amount).clamp(0.0, 1.0);

  return hslColor.withLightness(newLightness).toColor();
}

// 1. Játékszabályzat felugró ablak (AlertDialog)
void showGameRules(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.help_outline_rounded, color: Colors.deepPurple),
          SizedBox(width: 8),
          Text('How to Play'),
        ],
      ),
      content: const Text(
        'Find and tap the cards sequentially in ascending order!\n\n'
        '• Numbers: Tap from 1 to 10, 18, or 26.\n'
        '• Letters: Tap from A to Z.\n\n'
        'The timer starts on your first tap. Beat your best time!',
        style: TextStyle(fontSize: 15, height: 1.4),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Got it!'),
        ),
      ],
    ),
  );
}
