import 'package:flutter/material.dart';

class ThemeColorPicker extends StatelessWidget {
  final Function(Color) onColorSelected;

  const ThemeColorPicker({super.key, required this.onColorSelected});

  @override
  Widget build(BuildContext context) {
    final colors = [
      {'color': Colors.blueAccent, 'name': 'Ocean Blue'},
      {'color': Colors.teal, 'name': 'Emerald Teal'},
      {'color': Colors.deepPurple, 'name': 'Royal Purple'},
      {'color': Colors.amber, 'name': 'Sunset Amber'},
    ];

    return PopupMenuButton<Color>(
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      icon: const Icon(Icons.palette_rounded, color: Colors.white, size: 22),
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 8,
      onSelected: onColorSelected,
      itemBuilder: (context) => colors.map((item) {
        final color = item['color'] as Color;
        final name = item['name'] as String;

        return PopupMenuItem<Color>(
          value: color,
          child: Row(
            mainAxisSize:
                MainAxisSize.min, // Megakadályozza a menün belüli túlcsordulást
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.5),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  name,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
