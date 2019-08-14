import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/note_list/bloc.dart';
import '../widgets/note_list/note_list.dart';
import '../widgets/prompt_dialog.dart';
import '../widgets/snacks.dart';
import 'page_names.dart';

// https://github.com/devefy/Flutter-Story-App-UI
class NoteListPage extends StatefulWidget {
  static const String routeName = PageNames.noteList;

  NoteListPage({Key key}) : super(key: key);

  @override
  _NoteListPageState createState() => _NoteListPageState();
}

class _NoteListPageState extends State<NoteListPage> {
  final _bloc = NoteListBloc();

  @override
  void initState() {
    super.initState();
    this._bloc.dispatch(LoadNoteList());
    this._bloc.sideState.listen((side) => SchedulerBinding.instance
        .addPostFrameCallback((_) => this._onSideState(side)));
  }

  @override
  void dispose() {
    this._bloc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Image.asset('assets/image/logo.png',
            fit: BoxFit.cover, width: 24, height: 24),
        title: Text('여름 새벽'),
        actions: [_buildRefreshButton()],
      ),
      body: SafeArea(
          bottom: false,
          child: BlocProvider(
              builder: (context) => this._bloc, child: NoteList())),
      floatingActionButton: _buildAddButton(context),
    );
  }

  Widget _buildRefreshButton() {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: IconButton(
        icon: Icon(Icons.refresh),
        tooltip: '새로고침',
        onPressed: () {
          this._bloc.dispatch(LoadNoteList());
        },
      ),
    );
  }

  Widget _buildAddButton(BuildContext context) {
    return FloatingActionButton(
      onPressed: () {
        this._addNoteList(context);
      },
      tooltip: '새 노트',
      child: Icon(Icons.add),
    );
  }

  void _addNoteList(BuildContext context) async {
    final title = await showDialog(
        context: context,
        builder: (BuildContext context) => PromptDialog(
              title: '새 노트 만들기',
              defaultValue: '새 노트',
            ));
    if (title != null) {
      this._bloc.dispatch(AddNote(title: title));
    }
  }

  void _onSideState(NoteListSideState state) {
    switch (state) {
      case NoteListSideState.loadError:
      case NoteListSideState.addError:
        Snacks.of(context).text('서버와의 연결이 끊어졌습니다. 잠시 후 다시 시도해주세요.');
        break;
    }
  }
}
