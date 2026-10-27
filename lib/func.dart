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

    list.forEach((i) => codeList.add(i.codeUnitAt(0)));

    if (aCode == 65) return !codeList.contains(aCode + 1);
    if (aCode == 65 + boardSize - 1) return !codeList.contains(aCode - 1);
    return !codeList.contains(aCode - 1) || !codeList.contains(aCode + 1);
  } else {
    //számjátékvizsgálat
    int aNum = int.parse(a);
    Set<int> numList = {};

    list.forEach((i) => numList.add(int.parse(i)));

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
