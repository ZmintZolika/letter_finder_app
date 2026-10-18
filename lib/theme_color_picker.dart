import 'package:flutter/material.dart';

class ThemeColorPicker extends StatelessWidget {
  final Function(Color) onColorSelected;

  const ThemeColorPicker({super.key, required this.onColorSelected});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<Color>(
      icon: const Icon(Icons.palette),
      onSelected: onColorSelected,
      itemBuilder: (context) => const [
        PopupMenuItem(
          value: Colors.blueAccent,
          child: Row(
            children: [
              Icon(Icons.circle, color: Colors.blueAccent, size: 16),
              SizedBox(width: 10),
              Text('Blue'),
            ],
          ),
        ),
        PopupMenuItem(
          value: Colors.teal,
          child: Row(
            children: [
              Icon(Icons.circle, color: Colors.teal, size: 16),
              SizedBox(width: 10),
              Text('Teal'),
            ],
          ),
        ),
        PopupMenuItem(
          value: Colors.deepPurple,
          child: Row(
            children: [
              Icon(Icons.circle, color: Colors.deepPurple, size: 16),
              SizedBox(width: 10),
              Text('Purple'),
            ],
          ),
        ),
        PopupMenuItem(
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
    );
  }
}
