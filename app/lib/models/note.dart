import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

class NoteDocument with EquatableMixinBase, EquatableMixin {
  final String noteId;
  final String title;
  final List<NoteElement> elements;

  final DateTime created;
  final DateTime modified;

  NoteDocument(
      {@required this.noteId,
      @required this.title,
      @required this.elements,
      @required this.created,
      @required this.modified});

  @override
  List get props {
    return [
      this.noteId,
      this.title,
      this.elements,
      this.created,
      this.modified
    ];
  }
}

abstract class NoteElement with EquatableMixinBase, EquatableMixin {
  final String elementId;

  NoteElement({@required this.elementId}) : assert(elementId != null);

  @override
  List get props {
    return [this.elementId];
  }
}

class NotePaddingElement extends NoteElement {
  final double height;

  NotePaddingElement({@required String elementId, @required this.height})
      : assert(height != null),
        super(elementId: elementId);

  @override
  List get props {
    return super.props..addAll([this.height]);
  }
}

enum NoteImageSourceType { file, url, memory }

class NoteImageElement extends NoteElement {
  final NoteImageSourceType sourceType;
  final String url;

  NoteImageElement({
    @required String elementId,
    @required this.sourceType,
    this.url,
  }) : super(elementId: elementId);

  @override
  List get props {
    return super.props..addAll([this.sourceType, this.url]);
  }
}

class NoteTextElement extends NoteElement {
  final String text;
  final int level;

  NoteTextElement(
      {@required String elementId, @required this.text, @required this.level})
      : assert(text != null),
        assert(level != null),
        super(elementId: elementId);

  @override
  List get props {
    return super.props..addAll([this.text, this.level]);
  }
}

class NoteChatElement extends NoteElement {
  final String name;
  final String imageUrl;
  final String text;
  final int level;

  NoteChatElement(
      {@required String elementId,
      @required this.name,
      @required this.imageUrl,
      @required this.text,
      @required this.level})
      : assert(name != null),
        assert(imageUrl != null),
        assert(text != null),
        assert(level != null),
        super(elementId: elementId);

  @override
  List get props {
    return super.props
      ..addAll([this.name, this.imageUrl, this.text, this.level]);
  }
}
