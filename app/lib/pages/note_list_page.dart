import 'package:flutter/material.dart';
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
  final _scaffoldKey = new GlobalKey<ScaffoldState>();
  final _bloc = NoteListBloc();

  @override
  void initState() {
    super.initState();
    this._bloc.dispatch(LoadNoteList());
    this._bloc.sideState.listen(this._onSideState);
  }

  @override
  void dispose() {
    this._bloc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: this._scaffoldKey,
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.all(9.0),
          child: Image.asset('assets/images/logo.png'),
        ),
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
        onPressed: () async {
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
    if (this._bloc.busy) {
      Snacks.contextOf(context).text('조금만 기다려주세요!', closable: true);
      return;
    }
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

  final _snackBar = StatefulSnackBar();

  void _onSideState(NoteListSideState state) {
    switch (state) {
      case NoteListSideState.loadList:
        return this._snackBar.show(context: context, message: '불러오는 중입니다!');
      case NoteListSideState.listLoaded:
        return this._snackBar.show(
            context: context,
            message: '완료되었습니다!',
            barrier: false,
            closeAfter: Duration(milliseconds: 1500));
      case NoteListSideState.addItem:
        return this._snackBar.show(context: context, message: '새 노트를 추가합니다!');
      case NoteListSideState.itemAdded:
        return this._snackBar.show(
            context: context,
            message: '추가되었습니다!',
            barrier: false,
            closeAfter: Duration(milliseconds: 1500));
      case NoteListSideState.loadError:
      case NoteListSideState.addError:
        return this._snackBar.show(
            context: context,
            message: '서버와의 연결이 끊어졌습니다 ㅜㅜ 잠시 후 다시 시도해주세요!',
            barrier: false,
            closeAfter: Duration(milliseconds: 4000));
    }
  }
}
