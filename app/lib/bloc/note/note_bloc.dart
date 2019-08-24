import 'dart:async';

import 'package:meta/meta.dart';

import '../../models/note.dart';
import '../../models/backend.dart';
import '../../store/preference.dart';
import '../../proxy/backend.dart';
import '../simple_state_machine.dart';
import 'bloc.dart';

enum NoteSideState {
  noDocument,
  startToLoadDocument,
  documentLoaded,
  joinDocument,
  startToUpdateProfile,
  cannotUpdateProfile,
  profileUpdated,
  requestRefresh,
  startToUploadImage,
  uploadImageProgress,
  uploadCompleted,
  cannotUploadImages,
  cannotConnectToServer,
  elementAdded,
}

class NoteSide {
  final NoteSideState state;
  final dynamic arguments;

  NoteSide(this.state, {this.arguments});
}

class NoteContext {
  final String noteId;
  final DateTime created;

  String title;
  Map<String, NoteProfileVO> profiles;
  Map<String, NoteElementVO> elements;
  DateTime modified;

  NoteContext(
      {@required this.noteId,
      @required this.created,
      this.title,
      this.profiles,
      this.elements,
      this.modified});
}

class NoteBloc extends SimpleBlocStateMachine<NoteEvent, NoteState, NoteSide> {
  NoteContext _context;
  List<String> _hiddenElementIds = [];
  CallbackSocket _callbackSocket;

  @override
  NoteState get initialState => UnInitNoteState();

  @override
  Map<Type, Future<void> Function(NoteEvent)> get routes => {
        LoadNote: (event) => this._onLoadNote(event),
        ChangeUserProfile: (event) => this._onChangeUserProfile(event),
        AddPadding: (event) => this._onAddPadding(event),
        AddImage: (event) => this._onAddImage(event),
        AddText: (event) => this._onAddText(event),
        AddChat: (event) => this._onAddChat(event),
        MarkElementAsDeleted: (event) => this._onMarkElementAsDeleted(event),
        PurgeElement: (event) => this._onPurgeElement(event),
        ApplyCompletion: (event) => this._onApplyCompletion(event),
      };

  @override
  NoteState buildCurrentState() => this._context != null
      ? NoteLoadedState(
          document: NoteDocument(
              noteId: this._context.noteId,
              title: this._context.title,
              elements: this._buildElementsFromContext(),
              created: this._context.created,
              modified: this._context.modified))
      : UnInitNoteState();

  int get elementCount {
    return this._context != null ? this._context.elements.length : 0;
  }

  @override
  void dispose() {
    if (this._callbackSocket != null) {
      this._callbackSocket.close();
      this._callbackSocket = null;
    }
    super.dispose();
  }

  Future<void> _onLoadNote(LoadNote event) async {
    print('Start to load a note.');
    this.publishSide(NoteSide(NoteSideState.startToLoadDocument));
    final vo = await loadNoteDocument(event.noteId);
    if (vo == null) {
      this.publishSide(NoteSide(NoteSideState.noDocument));
      return;
    }

    this._context = NoteContext(
        noteId: vo.noteId,
        title: vo.title,
        profiles: vo.profiles,
        elements: vo.elements,
        created: vo.created,
        modified: vo.modified);
    this._hiddenElementIds = [];
    this.publishSide(NoteSide(NoteSideState.documentLoaded));

    // Upload this user profile if it is absent.
    final pref = Preference();
    if (!this._context.profiles.containsKey(getUserId()) &&
        pref.userName != null &&
        pref.userImageUrl != null) {
      this.publishSide(NoteSide(NoteSideState.joinDocument));
      await this._requestOperation([
        ChangeProfileOperation(
            userId: pref.userId,
            name: pref.userName,
            imageUrl: pref.userImageUrl)
      ]);
    }
    print('A note is loaded completely.');
  }

  Future<void> _onChangeUserProfile(ChangeUserProfile event) async {
    assert(this._context != null);
    final userId = getUserId();
    String url;
    try {
      this.publishSide(NoteSide(NoteSideState.startToUpdateProfile));
      url = await uploadNoteProfileImage(
          userId, this._context.noteId, event.fileLocation);
    } catch (error) {
      print(error);
      this.publishSide(NoteSide(NoteSideState.cannotUpdateProfile));
      return;
    }
    await this._requestOperation([
      ChangeProfileOperation(userId: userId, name: event.name, imageUrl: url)
    ]);
  }

  Future<void> _onAddPadding(AddPadding event) async {
    await this._requestOperation([
      AddOperation(indexToInsert: this.elementCount, elements: [
        NotePaddingVO(index: this.elementCount, height: event.height)
      ]),
    ]);
  }

  Future<void> _onAddImage(AddImage event) async {
    this.publishSide(NoteSide(NoteSideState.startToUploadImage,
        arguments: {"totalCount": event.fileLocations.length}));
    Map<String, String> uploaded;
    try {
      uploaded = await uploadImages(this._context.noteId, event.fileLocations,
          (completedCount) {
        this.publishSide(NoteSide(NoteSideState.uploadImageProgress,
            arguments: {
              "completedCount": completedCount,
              "totalCount": event.fileLocations.length
            }));
      });
      this.publishSide(NoteSide(NoteSideState.uploadCompleted));
    } catch (error) {
      print(error);
      this.publishSide(NoteSide(NoteSideState.cannotUploadImages));
      return;
    }

    final lastIndex = this.elementCount;
    var insertIndex = lastIndex;
    final images = <NoteImageVO>[];
    for (final url in event.fileLocations
        .map((file) => uploaded[file])
        .where((each) => each != null)) {
      images.add(NoteImageVO(
        index: insertIndex++,
        url: url,
      ));
    }
    await this._requestOperation([
      AddOperation(indexToInsert: lastIndex, elements: images),
    ]);
  }

  Future<void> _onAddText(AddText event) async {
    await this._requestOperation([
      AddOperation(indexToInsert: this.elementCount, elements: [
        NoteTextVO(
            index: this.elementCount, text: event.text, level: event.level)
      ]),
    ]);
  }

  Future<void> _onAddChat(AddChat event) async {
    await this._requestOperation([
      AddOperation(indexToInsert: this.elementCount, elements: [
        NoteChatVO(
            index: this.elementCount,
            userId: getUserId(),
            text: event.text,
            level: event.level)
      ]),
    ]);
  }

  Future<void> _onMarkElementAsDeleted(MarkElementAsDeleted event) async {
    assert(this._context != null);
    if (event.deleted) {
      this._hiddenElementIds.addAll(event.elementIds);
    } else {
      this
          ._hiddenElementIds
          .removeWhere((each) => event.elementIds.contains(each));
    }
  }

  Future<void> _onPurgeElement(PurgeElement event) async {
    await this
        ._requestOperation([DeleteOperation(elementIds: event.elementIds)]);
  }

  Future<void> _onApplyCompletion(ApplyCompletion event) async {
    assert(this._context != null);

    var requestRefresh = false;
    for (final completion in event.completions) {
      print(completion);
      this._context.modified = completion.modified;
      if (completion is AddCompletion) {
        this._context.elements.addAll(completion.elements);
      } else if (completion is MoveCompletion) {
        for (final each in completion.newIndices.entries) {
          final target = this._context.elements[each.key];
          if (target == null) {
            requestRefresh = true;
          } else {
            this._context.elements[each.key] = target.reorder(each.value);
          }
        }
      } else if (completion is DeleteCompletion) {
        this
            ._context
            .elements
            .removeWhere((each, _) => completion.elementIds.contains(each));
        this
            ._hiddenElementIds
            .removeWhere((each) => completion.elementIds.contains(each));
      } else if (completion is ChangeProfileCompletion) {
        for (final each in completion.profiles.entries) {
          this._context.profiles[each.key] = NoteProfileVO(
              name: each.value.name, imageUrl: each.value.imageUrl);
          final pref = Preference();
          if (each.key == pref.userId) {
            await pref.updateProfile(each.value.name, each.value.imageUrl);
          }
          this.publishSide(NoteSide(NoteSideState.profileUpdated));
        }
      } else {
        throw new Exception('Unknown completion ${completion.runtimeType}');
      }
    }
    if (requestRefresh) {
      this.publishSide(NoteSide(NoteSideState.requestRefresh));
    }
  }

  Future<void> _initializeCallbackSocket(String noteId) async {
    if (this._callbackSocket != null && this._callbackSocket.noteId != noteId) {
      this._callbackSocket.close();
      this._callbackSocket = null;
    }

    if (this._callbackSocket == null || this._callbackSocket.closed) {
      this._callbackSocket = CallbackSocket(
          noteId: noteId,
          onData: (completions) =>
              this.dispatch(ApplyCompletion(completions: completions)));
      try {
        await this._callbackSocket.connect();
      } catch (error) {
        print(error);
        this.publishSide(NoteSide(NoteSideState.cannotConnectToServer));
        this._callbackSocket.close();
        this._callbackSocket = null;
      }
    }
  }

  Future<void> _requestOperation(List<Operation> operations) async {
    assert(this._context != null);
    await this._initializeCallbackSocket(this._context.noteId);

    print(operations);
    try {
      await requestOperation(this._context.noteId, operations);

      // If cannot connect to the callback server, use refresh instead.
      if (this._callbackSocket == null) {
        await Future.delayed(Duration(milliseconds: 500));
        this.dispatch(LoadNote(noteId: this._context.noteId));
      }
    } catch (error) {
      print(error);
      this.publishSide(NoteSide(NoteSideState.cannotConnectToServer));
    }
  }

  List<NoteElement> _buildElementsFromContext() {
    assert(this._context != null);
    final entries = this._context.elements.entries.toList();
    entries.sort((a, b) => a.value.index - b.value.index);
    return entries.map((entry) {
      final elementId = entry.key;
      final vo = entry.value;
      if (vo is NotePaddingVO) {
        return NotePaddingElement(elementId: elementId, height: vo.height);
      } else if (vo is NoteImageVO) {
        return NoteImageElement(
            elementId: elementId,
            sourceType: NoteImageSourceType.url,
            url: vo.url);
      } else if (vo is NoteTextVO) {
        return NoteTextElement(
            elementId: elementId, text: vo.text, level: vo.level);
      } else if (vo is NoteChatVO) {
        final user = this._context.profiles[vo.userId];
        return NoteChatElement(
            elementId: elementId,
            name: user?.name ?? '비밀',
            imageUrl: user?.imageUrl ?? 'default',
            text: vo.text,
            level: vo.level);
      }
      throw new Exception('No mapping for vo ${vo.runtimeType}');
    }).toList();
  }

  @override
  Future<void> onAfterYield(NoteEvent event) async {
    print('onAfterYield: ' + event.runtimeType.toString());
    if (event is ApplyCompletion) {
      if (event.completions.any((each) => each is AddCompletion)) {
        this.publishSide(NoteSide(NoteSideState.elementAdded));
      }
    }
  }
}
