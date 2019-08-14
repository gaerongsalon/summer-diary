import 'package:meta/meta.dart';

class PageNames {
  static const splash = '/splash';
  static const noteList = '/noteList';
  static const note = '/note';
}

class NotePageArguments {
  final String noteId;

  NotePageArguments({@required this.noteId}) : assert(noteId != null);
}
