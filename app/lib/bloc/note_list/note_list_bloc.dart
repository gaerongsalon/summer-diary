import 'dart:async';

import '../../models/note_list.dart';
import '../../proxy/backend.dart';
import '../simple_state_machine.dart';
import 'bloc.dart';

enum NoteListSideState { loading, loadError, addError }

class NoteListBloc extends SimpleBlocStateMachine<NoteListEvent, NoteListState,
    NoteListSideState> {
  List<NoteListItemElement> _items = [];
  List<String> _hiddenIds = [];

  @override
  NoteListState get initialState => UnInitNoteListState();

  @override
  Map<Type, Future<void> Function(NoteListEvent)> get routes => {
        LoadNoteList: (event) => this._onLoadNoteList(event),
        AddNote: (event) => this._onAddNote(event),
        MarkNoteAsDeleted: (event) => this.onMarkNoteAsDeleted(event),
        PurgeNote: (event) => this.onPurgeNote(event)
      };

  @override
  NoteListState buildCurrentState() => NoteListLoadedState(
      items: []..addAll(
          this._items.where((each) => !this._hiddenIds.contains(each.noteId))));

  Future<void> _onLoadNoteList(LoadNoteList event) async {
    try {
      this.publishSide(NoteListSideState.loading);
      this._items = await loadNoteItemList();
      this._hiddenIds = [];
    } catch (error) {
      print(error);
      this.publishSide(NoteListSideState.loadError);
    }
  }

  Future<void> _onAddNote(AddNote event) async {
    try {
      final newNote = await addNote(event.title);
      this._items.insert(0, newNote);
    } catch (error) {
      print(error);
      this.publishSide(NoteListSideState.addError);
    }
  }

  Future<void> onMarkNoteAsDeleted(MarkNoteAsDeleted event) async {
    if (event.deleted) {
      this._hiddenIds.add(event.noteId);
    } else {
      this._hiddenIds.remove(event.noteId);
    }
  }

  Future<void> onPurgeNote(PurgeNote event) async {
    await deleteNote(event.noteId);
    this._hiddenIds.remove(event.noteId);
    this._items.removeWhere((note) => note.noteId == event.noteId);
  }
}
