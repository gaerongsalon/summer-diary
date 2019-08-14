import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

import '../../models/backend.dart';

@immutable
abstract class NoteEvent extends Equatable {
  NoteEvent([List props = const []]) : super(props);
}

class LoadNote extends NoteEvent {
  final String noteId;

  LoadNote({@required this.noteId})
      : assert(noteId != null),
        super([noteId]);
}

// TODO ChangeTitle
// TODO DeleteNote

class ChangeUserProfile extends NoteEvent {
  final String name;
  final String fileLocation;

  ChangeUserProfile({@required this.name, @required this.fileLocation})
      : assert(name != null),
        assert(fileLocation != null),
        super([name, fileLocation]);
}

class AddPadding extends NoteEvent {
  final double height;

  AddPadding({@required this.height})
      : assert(height > 0),
        super([height]);
}

class AddImage extends NoteEvent {
  final List<String> fileLocations;

  AddImage({@required this.fileLocations})
      : assert(fileLocations != null),
        super([fileLocations]);
}

class AddText extends NoteEvent {
  final String text;
  final int level;

  AddText({@required this.text, @required this.level})
      : assert(text != null),
        assert(level != null),
        super([text, level]);
}

class AddChat extends NoteEvent {
  final String text;
  final int level;

  AddChat({@required this.text, @required this.level})
      : assert(text != null),
        assert(level != null),
        super([text, level]);
}

class MarkElementAsDeleted extends NoteEvent {
  final List<String> elementIds;
  final bool deleted;

  MarkElementAsDeleted({@required this.elementIds, @required this.deleted})
      : assert(elementIds != null),
        assert(deleted != null),
        super([elementIds, deleted]);
}

class PurgeElement extends NoteEvent {
  final List<String> elementIds;

  PurgeElement({@required this.elementIds})
      : assert(elementIds != null),
        super([elementIds]);
}

class ApplyCompletion extends NoteEvent {
  final List<Completion> completions;

  ApplyCompletion({@required this.completions})
      : assert(completions != null),
        super([completions]);
}
