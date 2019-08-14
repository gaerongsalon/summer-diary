import 'package:meta/meta.dart';

import '../utils/json_utils.dart';

class NoteVO {
  final String noteId;
  final String title;
  final Map<String, NoteProfileVO> profiles;
  final Map<String, NoteElementVO> elements;
  final DateTime created;
  final DateTime modified;

  NoteVO(
      {@required this.noteId,
      @required this.title,
      @required this.profiles,
      @required this.elements,
      @required this.created,
      @required this.modified});
}

NoteVO jsonToNoteVO(dynamic json) {
  return NoteVO(
    noteId: json['noteId'],
    title: json['title'],
    created: DateTime.parse(json['created']),
    modified: DateTime.parse(json['modified']),
    profiles: jsonToMapOfNoteProfileVO(json['profiles']),
    elements: jsonToMapOfNoteElementVO(json['elements']),
  );
}

class NoteProfileVO {
  final String name;
  final String imageUrl;

  NoteProfileVO({@required this.name, @required this.imageUrl});
}

NoteProfileVO jsonToNoteProfileVO(dynamic json) =>
    NoteProfileVO(name: json['name'] as String, imageUrl: json['imageUrl']);

Map<String, NoteProfileVO> jsonToMapOfNoteProfileVO(Map<String, dynamic> json) {
  final profiles = <String, NoteProfileVO>{};
  for (final each in json.entries) {
    profiles[each.key] = jsonToNoteProfileVO(each.value);
  }
  return profiles;
}

abstract class NoteElementVO {
  final int index;

  NoteElementVO({@required this.index});

  NoteElementVO reorder(int newIndex);

  Map<String, dynamic> toJson();
}

class NotePaddingVO extends NoteElementVO {
  final double height;

  NotePaddingVO({@required int index, @required this.height})
      : super(index: index);

  @override
  NotePaddingVO reorder(int newIndex) =>
      NotePaddingVO(index: newIndex, height: height);

  @override
  Map<String, dynamic> toJson() =>
      {"_type": "padding", "index": this.index, "height": this.height};
}

class NoteImageVO extends NoteElementVO {
  final String url;

  NoteImageVO({@required int index, @required this.url}) : super(index: index);

  @override
  NoteImageVO reorder(int newIndex) => NoteImageVO(index: newIndex, url: url);

  @override
  Map<String, dynamic> toJson() =>
      {"_type": "padding", "index": this.index, "url": this.url};
}

class NoteTextVO extends NoteElementVO {
  final String text;
  final int level;

  NoteTextVO({@required int index, @required this.text, @required this.level})
      : super(index: index);

  @override
  NoteTextVO reorder(int newIndex) =>
      NoteTextVO(index: newIndex, text: text, level: level);

  @override
  Map<String, dynamic> toJson() => {
        "_type": "padding",
        "index": this.index,
        "text": this.text,
        "level": this.level
      };
}

class NoteChatVO extends NoteElementVO {
  final String userId;
  final String text;
  final int level;

  NoteChatVO(
      {@required int index,
      @required this.userId,
      @required this.text,
      @required this.level})
      : super(index: index);

  @override
  NoteChatVO reorder(int newIndex) =>
      NoteChatVO(index: newIndex, userId: userId, text: text, level: level);

  @override
  Map<String, dynamic> toJson() => {
        "_type": "padding",
        "index": this.index,
        "userId": this.userId,
        "text": this.text,
        "level": this.level
      };
}

NoteElementVO jsonToNoteElementVO(dynamic element) {
  final elementType = element['_type'];
  switch (elementType) {
    case 'padding':
      return NotePaddingVO(index: element['index'], height: element['height']);
    case 'image':
      return NoteImageVO(index: element['index'], url: element['url']);
    case 'text':
      return NoteTextVO(
          index: element['index'],
          text: element['text'],
          level: element['level']);
    case 'chat':
      return NoteChatVO(
          index: element['index'],
          userId: element['userId'],
          text: element['text'],
          level: element['level']);
    default:
      throw new Exception('No mapping for $elementType');
  }
}

Map<String, NoteElementVO> jsonToMapOfNoteElementVO(
    Map<String, dynamic> elementsJson) {
  final elements = <String, NoteElementVO>{};
  for (final each in elementsJson.entries) {
    elements[each.key] = jsonToNoteElementVO(each.value);
  }
  return elements;
}

// Operation
abstract class Operation {
  Map<String, dynamic> toJson();
}

class AddOperation extends Operation {
  final int indexToInsert;
  final List<NoteElementVO> elements;

  AddOperation({this.indexToInsert, @required this.elements})
      : assert(elements != null);

  @override
  Map<String, dynamic> toJson() => {
        "_type": "add",
        "indexToInsert": this.indexToInsert,
        "elements": elements.map((each) => each.toJson()).toList()
      };
}

class MoveOperation extends Operation {
  final int toIndex;
  final List<String> elementIds;

  MoveOperation({@required this.toIndex, @required this.elementIds})
      : assert(toIndex != null),
        assert(elementIds != null);

  @override
  Map<String, dynamic> toJson() =>
      {"_type": "move", "toIndex": this.toIndex, "elementIds": this.elementIds};
}

class DeleteOperation extends Operation {
  final List<String> elementIds;

  DeleteOperation({@required this.elementIds}) : assert(elementIds != null);

  @override
  Map<String, dynamic> toJson() =>
      {"_type": "delete", "elementIds": this.elementIds};
}

class ChangeProfileOperation extends Operation {
  final String userId;
  final String name;
  final String imageUrl;

  ChangeProfileOperation(
      {@required this.userId, @required this.name, @required this.imageUrl})
      : assert(userId != null),
        assert(name != null),
        assert(imageUrl != null);

  @override
  Map<String, dynamic> toJson() => {
        "_type": "changeProfile",
        "userId": this.userId,
        "name": this.name,
        "imageUrl": this.imageUrl,
      };
}

List operationsToJson(List<Operation> operations) =>
    operations.map((each) => each.toJson()).toList();

// Completion
abstract class Completion {
  final DateTime modified;

  Completion({@required this.modified}) : assert(modified != null);
}

class AddCompletion extends Completion {
  final Map<String, NoteElementVO> elements;

  AddCompletion({DateTime modified, @required this.elements})
      : assert(elements != null),
        super(modified: modified);
}

class MoveCompletion extends Completion {
  final Map<String, int> newIndices;

  MoveCompletion({DateTime modified, @required this.newIndices})
      : assert(newIndices != null),
        super(modified: modified);
}

class DeleteCompletion extends Completion {
  final List<String> elementIds;

  DeleteCompletion({DateTime modified, @required this.elementIds})
      : assert(elementIds != null),
        super(modified: modified);
}

class ChangeProfileCompletion extends Completion {
  final Map<String, NoteProfileVO> profiles;

  ChangeProfileCompletion({DateTime modified, @required this.profiles})
      : assert(profiles != null),
        super(modified: modified);
}

Completion jsonToCompletion(dynamic json) {
  final completionType = json['_type'];
  final modified = DateTime.parse(json['modified']);
  switch (completionType) {
    case 'add':
      return AddCompletion(
          modified: modified,
          elements: jsonToMapOfNoteElementVO(json['elements']));
    case 'move':
      return MoveCompletion(
          modified: modified,
          newIndices: JsonUtils.asMap<String, int>(json['newIndices']));
    case 'delete':
      return DeleteCompletion(
          modified: modified,
          elementIds: JsonUtils.asList<String>(json['elementIds']));
    case 'changeProfile':
      return ChangeProfileCompletion(
          modified: modified,
          profiles: jsonToMapOfNoteProfileVO(json['profiles']));
    default:
      throw new Exception('Unknown completion $completionType');
  }
}

List<Completion> jsonToCompletions(List json) =>
    json.map((each) => jsonToCompletion(each)).toList();
