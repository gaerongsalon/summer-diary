import 'package:flutter/material.dart';

import '../../models/note.dart';

class NotePadding extends StatelessWidget {
  const NotePadding({
    Key key,
    @required this.element,
  }) : super(key: key);

  final NotePaddingElement element;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: this.element.height),
    );
  }
}
