import 'package:flutter/material.dart';

void summaryScreen(
  BuildContext context,
  String elapsedTime,
  VoidCallback onPlayAgain, {
  Color themeColor = Colors.deepPurple,
}) {
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: Colors.grey.shade900,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: themeColor.withValues(alpha: 0.7), width: 2),
      ),
      title: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.emoji_events_rounded, color: Colors.amberAccent, size: 28),
          SizedBox(width: 10),
          Text(
            'Congratulations!',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'You revealed all the cards!',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
              decoration: BoxDecoration(
                color: themeColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white24),
              ),
              child: Column(
                children: [
                  const Text(
                    'YOUR TIME',
                    style: TextStyle(
                      color: Colors.amberAccent,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.timer_outlined,
                        color: Colors.amberAccent,
                        size: 26,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        elapsedTime,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actionsAlignment: MainAxisAlignment.spaceEvenly,
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(dialogContext); // bezárja a dialógust
            Navigator.pop(context); // kilép a játékból a főképernyőre
          },
          child: const Text(
            'Main Menu',
            style: TextStyle(color: Colors.white70),
          ),
        ),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: themeColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: onPlayAgain,
          icon: const Icon(Icons.replay_rounded, size: 18),
          label: const Text('Play Again'),
        ),
      ],
    ),
  );
}
