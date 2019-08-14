import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

@immutable
abstract class NoteListEvent extends Equatable {
  NoteListEvent([List props = const []]) : super(props);
}

class LoadNoteList extends NoteListEvent {}

// TODO ChangeTitle

class AddNote extends NoteListEvent {
  final String title;

  AddNote({@required this.title})
      : assert(title != null),
        super([title]);
}

class MarkNoteAsDeleted extends NoteListEvent {
  final String noteId;
  final bool deleted;

  MarkNoteAsDeleted({@required this.noteId, @required this.deleted})
      : assert(noteId != null),
        assert(deleted != null),
        super([noteId, deleted]);
}

class PurgeNote extends NoteListEvent {
  final String noteId;

  PurgeNote({@required this.noteId})
      : assert(noteId != null),
        super([noteId]);
}
