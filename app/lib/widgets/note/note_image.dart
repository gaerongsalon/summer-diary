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
            margin: const EdgeInsets.only(bottom: 36.0),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                  maxHeight: 480,
                  maxWidth: MediaQuery.of(context).size.width - 24),
              child: ClipRRect(
                  borderRadius: BorderRadius.circular(16.0),
                  child: this.element.sourceType == NoteImageSourceType.url
                      ? CachedNetworkImage(
                          imageUrl: this.element.url,
                          placeholder: (context, url) =>
                              CircularProgressIndicator(),
                          errorWidget: (context, url, error) =>
                              Icon(Icons.error),
                        )
                      : Image.file(File(this.element.url))),
            )),
      ],
    );
  }
}
