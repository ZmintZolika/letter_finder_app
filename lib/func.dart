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
    builder: (dialogContext) => AlertDialog(
      backgroundColor: Colors.grey.shade900,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: Colors.blueAccent.withValues(alpha: 0.7),
          width: 2,
        ),
      ),
      title: const Row(
        children: [
          Icon(Icons.help_outline_rounded, color: Colors.amberAccent, size: 28),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Game Rules',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildRuleItem(
              Icons.filter_1_rounded,
              'Classic Numbers & Letters',
              'Find and tap the cards sequentially in ascending order (Numbers: 1 to 10/18/26, Letters: A to Z).',
            ),
            const SizedBox(height: 14),
            _buildRuleItem(
              Icons.all_inclusive_rounded,
              'Next to Infinity Mode',
              'Pair up adjacent numbers differing by 1, or tap lonely cards for bonus points. Endless replacements under a 5-minute timer!',
            ),
            const SizedBox(height: 14),
            _buildRuleItem(
              Icons.timer_outlined,
              'Timer & Best Scores',
              'The timer starts automatically on your first tap. Beat your best time and set new score records!',
            ),
          ],
        ),
      ),
      actions: [
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueAccent,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text(
            'Got it!',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    ),
  );
}

Widget _buildRuleItem(IconData icon, String title, String description) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.blueAccent.withValues(alpha: 0.25),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Colors.amberAccent, size: 18),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              description,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}
