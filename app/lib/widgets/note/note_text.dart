import 'package:flutter/material.dart';

import '../../models/note.dart';

class NoteText extends StatelessWidget {
  const NoteText({
    Key key,
    @required this.element,
  }) : super(key: key);

  final NoteTextElement element;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Text(
        this.element.text,
        textAlign: TextAlign.center,
        style: TextStyle(
            fontSize: this.element.level.toDouble(),
            fontWeight: FontWeight.bold),
      ),
    );
  }
}
