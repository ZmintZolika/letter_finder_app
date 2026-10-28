import 'package:flutter/material.dart';

void SummaryScreen(BuildContext context) {
  showModalBottomSheet(
    context: context,
    builder: ((context) => Text('Congratulations!')),
  );
}
