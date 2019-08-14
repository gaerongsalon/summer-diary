import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import '../../models/note.dart';

class NoteImage extends StatelessWidget {
  const NoteImage({
    Key key,
    @required this.element,
  }) : super(key: key);

  final NoteImageElement element;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Container(
          margin: const EdgeInsets.only(bottom: 24.0),
          decoration:
              BoxDecoration(color: Colors.white /* No border */, boxShadow: [
            BoxShadow(
                color: const Color(0x88000000),
                offset: Offset(2.0, 2.0),
                blurRadius: 4),
          ]),
          child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: 320),
              child: this.element.sourceType == NoteImageSourceType.url
                  ? CachedNetworkImage(imageUrl: this.element.url)
                  : Image.file(File(this.element.url))),
        ),
      ],
    );
  }
}
