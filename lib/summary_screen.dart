import 'package:flutter/material.dart';

void SummaryScreen(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: ((context) => const FractionallySizedBox(
      heightFactor: 0.5,
      widthFactor: 1.0,
      child: Text('Congratulations!'),
    )),
  );
}
