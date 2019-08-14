import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

import '../../models/note.dart';

@immutable
abstract class NoteState extends Equatable {
  NoteState([List props = const []]) : super(props);
}

class UnInitNoteState extends NoteState {}

class NoteLoadedState extends NoteState {
  final NoteDocument document;

  NoteLoadedState({@required this.document})
      : assert(document != null),
        super([document]);
}
