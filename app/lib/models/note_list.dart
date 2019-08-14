import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

class NoteListItemElement extends Equatable {
  final String noteId;
  final String title;
  final DateTime created;
  final DateTime modified;

  NoteListItemElement(
      {@required this.noteId,
      @required this.title,
      @required this.created,
      @required this.modified})
      : assert(noteId != null),
        assert(title != null),
        assert(created != null),
        assert(modified != null),
        super([title, created, modified]);
}
