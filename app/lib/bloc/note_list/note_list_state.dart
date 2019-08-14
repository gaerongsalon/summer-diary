import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

import '../../models/note_list.dart';

@immutable
abstract class NoteListState extends Equatable {
  NoteListState([List props = const []]) : super(props);
}

class UnInitNoteListState extends NoteListState {}

class NoteListLoadedState extends NoteListState {
  final List<NoteListItemElement> items;

  NoteListLoadedState({@required this.items})
      : assert(items != null),
        super([items]);
}
