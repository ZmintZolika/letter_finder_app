import 'package:flutter/material.dart';

class ABC_game extends StatefulWidget {
  const ABC_game({super.key});

  @override
  State<ABC_game> createState() => _ABC_gameState();
}

class _ABC_gameState extends State<ABC_game> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kirakós'),
        centerTitle: true,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: const Center(child: Text('Kezdőlap')),
    );
  }
}
