import 'card_finder_screen.dart';

import 'package:shared_preferences/shared_preferences.dart';

String scoreKey(GameType gameType, int boardSize) {
  return ('${gameType.name}_$boardSize');
}

Future<int> checkAndSaveBestTime(
  GameType gameType,
  int boardSize,
  int currentSeconds,
) async {
  final prefs = await SharedPreferences.getInstance();
  final key = scoreKey(gameType, boardSize);
  final bestTime = prefs.getInt(
    key,
  ); // Visszaolvassa a régit (vagy null, ha még nincs)

  if (bestTime == null || currentSeconds < bestTime) {
    await prefs.setInt(
      key,
      currentSeconds,
    ); // Csak akkor írja felül, ha új rekord!
    return currentSeconds;
  }
  return bestTime;
}

Future<int?> getBestTime(GameType gameType, int boardSize) async {
  final prefs = await SharedPreferences.getInstance();
  final key = scoreKey(gameType, boardSize);
  return prefs.getInt(
    key,
  ); // Visszaadja a másodpercet, vagy null-t, ha még nem játszották
}
