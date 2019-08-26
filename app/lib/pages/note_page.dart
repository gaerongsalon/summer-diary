import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:file_picker/file_picker.dart';

import '../bloc/note/bloc.dart';
import '../store/preference.dart';
import '../widgets/note.dart';
import '../widgets/snacks.dart';
import '../widgets/prompt_dialog.dart';
import 'page_names.dart';

class NotePage extends StatefulWidget {
  static const String routeName = PageNames.note;

  NotePage({Key key, @required this.noteId}) : super(key: key);

  final String noteId;

  @override
  _NotePageState createState() => _NotePageState();
}

class _NotePageState extends State<NotePage> {
  final _scaffoldKey = new GlobalKey<ScaffoldState>();
  final _scrollController = ScrollController();
  final _bloc = NoteBloc();

  @override
  void initState() {
    super.initState();
    this._bloc.dispatch(LoadNote(noteId: widget.noteId));
    this._bloc.sideState.listen(this._onSide);
  }

  @override
  void dispose() {
    this._bloc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
        builder: (BuildContext context) => this._bloc,
        child: BlocBuilder(
          bloc: this._bloc,
          builder: (BuildContext context, NoteState state) =>
              this._buildNoteView(context, state),
        ));
  }

  Widget _buildNoteView(BuildContext context, NoteState state) {
    return Scaffold(
        key: this._scaffoldKey,
        appBar: AppBar(
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            tooltip: '뒤로가기',
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          titleSpacing: 4,
          title: Text(state is NoteLoadedState ? state.document.title : '...'),
          actions: [this._buildRefreshButton()],
        ),
        body: state is NoteLoadedState
            ? SafeArea(
                bottom: false,
                child: Column(
                  children: <Widget>[
                    Expanded(
                      child: _NoteElementList(
                        scrollController: this._scrollController,
                      ),
                    ),
                    _NoteChatField(
                      onText: (text) => this._addChat(context, text),
                      onPickImage: () => this._pickImages(context),
                    ),
                  ],
                ),
              )
            : Center(
                child: Text('불러오고 있습니다.'),
              ),
        floatingActionButton: this._buildAddButton(context));
  }

  Widget _buildRefreshButton() {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: IconButton(
        icon: Icon(Icons.refresh),
        tooltip: '새로고침',
        onPressed: () {
          this._bloc.dispatch(LoadNote(noteId: widget.noteId));
        },
      ),
    );
  }

  Widget _buildAddButton(BuildContext context) {
    return SpeedDial(
      marginBottom: 80,
      child: Icon(Icons.add),
      onOpen: () => this._openAddButton(context),
      tooltip: '추가',
      children: [
        SpeedDialChild(
            child: Icon(Icons.arrow_downward),
            label: '아래로',
            onTap: this._moveScrollToEnd),
        SpeedDialChild(
          child: Icon(Icons.portrait),
          label: '프로필 바꾸기',
          onTap: () => this._changeProfile(context),
        ),
      ],
    );
  }

  void _openAddButton(BuildContext context) {
    if (this._bloc.busy) {
      Snacks.contextOf(context)
          .text('다른 작업이 완료되지 않았습니다. 조금만 기다려주세요.', closable: true);
    }
  }

  void _pickImages(BuildContext context) async {
    try {
      final sourceFiles =
          await FilePicker.getMultiFilePath(type: FileType.IMAGE);
      if (sourceFiles == null || sourceFiles.length == 0) {
        Snacks.of(this._scaffoldKey.currentState)
            .text('취소합니다.', closable: true);
        return;
      }
      final files = sourceFiles.values.toList();
      this._bloc.dispatch(AddImage(fileLocations: files));
    } catch (error) {
      print(error);
      Snacks.of(this._scaffoldKey.currentState).text('취소합니다.', closable: true);
    }
  }

  void _addChat(BuildContext context, String maybeText) async {
    final text = maybeText?.trim();
    if (text == null || text.length == 0) {
      return;
    }
    if (text.length > 0) {
      this._bloc.dispatch(AddChat(text: text, level: 14));
    }
  }

  void _changeProfile(BuildContext context) async {
    final nameResponse = await showDialog(
        context: context,
        builder: (BuildContext context) => PromptDialog(
              title: '새 이름',
              defaultValue: Preference().userName ?? '',
            ));
    if (nameResponse == null) {
      Snacks.of(this._scaffoldKey.currentState).text('취소합니다.', closable: true);
      return;
    }
    final name = (nameResponse as String).trim();
    if (name.length == 0) {
      Snacks.of(this._scaffoldKey.currentState).text('취소합니다.', closable: true);
      return;
    }
    final imageFile = await FilePicker.getFile(type: FileType.IMAGE);
    if (imageFile == null) {
      Snacks.of(this._scaffoldKey.currentState).text('취소합니다.', closable: true);
      return;
    }
    this._bloc.dispatch(
        ChangeUserProfile(name: name, fileLocation: imageFile.absolute.path));
  }

  final _snackBar = StatefulSnackBar();

  void _onSide(NoteSide side) async {
    switch (side.state) {
      case NoteSideState.noDocument:
        return this._snackBar.show(
            context: context,
            message: '노트를 찾을 수 없습니다 ㅜㅜ',
            barrier: false,
            closeAfter: Duration(milliseconds: 4000));
      case NoteSideState.startToLoadDocument:
        return this._snackBar.show(context: context, message: '노트를 열고 있습니다!');
      case NoteSideState.documentLoaded:
        return this._snackBar.show(
            context: context,
            message: '로딩이 끝났습니다!',
            barrier: false,
            closeAfter: Duration(milliseconds: 1500));
      case NoteSideState.joinDocument:
        return this
            ._snackBar
            .show(context: context, message: '프로필을 동기화하고 있습니다');
      case NoteSideState.startToUpdateProfile:
        return this._snackBar.show(context: context, message: '새 프로필을 업로드합니다.');
      case NoteSideState.cannotUpdateProfile:
        return this._snackBar.show(
            context: context,
            message: '프로필을 갱신할 수 없습니다 ㅜㅜ',
            barrier: false,
            closeAfter: Duration(milliseconds: 1500));
      case NoteSideState.profileUpdated:
        return this._snackBar.show(
            context: context,
            message: '프로필이 갱신되었습니다!',
            barrier: false,
            closeAfter: Duration(milliseconds: 1500));
      case NoteSideState.requestRefresh:
        return this._snackBar.show(
            context: context,
            message: '페이지를 새로고침해주세요 ㅜㅜ',
            barrier: false,
            closeAfter: Duration(milliseconds: 4000));
      case NoteSideState.startToUploadImage:
      case NoteSideState.uploadImageProgress:
        return this._snackBar.show(
            context: context,
            message: '이미지를 업로드합니다 (' +
                (side.arguments['completedCount']?.toString() ?? '0') +
                '/' +
                side.arguments['totalCount'].toString() +
                ')');
      case NoteSideState.uploadCompleted:
        return this._snackBar.show(
            context: context,
            message: '업로드가 완료되었습니다!',
            barrier: false,
            closeAfter: Duration(milliseconds: 1500));
      case NoteSideState.cannotUploadImages:
        return this._snackBar.show(
            context: context,
            message: '이미지 업로드에 실패했습니다 ㅜㅜ',
            barrier: false,
            closeAfter: Duration(milliseconds: 4000));
      case NoteSideState.cannotConnectToServer:
        return this._snackBar.show(
            context: context,
            message: '서버에 연결할 수가 없습니다 ㅜㅜ',
            barrier: false,
            closeAfter: Duration(milliseconds: 4000));
      case NoteSideState.elementAdded:
        Future.delayed(Duration(milliseconds: 300))
            .then((_) => this._moveScrollToEnd());
        break;
    }
  }

  void _moveScrollToEnd() async {
    double maxScroll = 0;
    double newMaxScroll = this._scrollController.position.maxScrollExtent;
    do {
      maxScroll = newMaxScroll;
      this._scrollController.animateTo(
            maxScroll,
            duration: const Duration(milliseconds: 100),
            curve: Curves.easeOut,
          );
      print(maxScroll);
      await Future.delayed(Duration(milliseconds: 100));
      newMaxScroll = this._scrollController.position.maxScrollExtent;
    } while ((newMaxScroll - maxScroll).abs() > 1);
  }
}

class _NoteElementList extends StatelessWidget {
  _NoteElementList({Key key, @required ScrollController scrollController})
      : this._scrollController = scrollController,
        super(key: key);

  final ScrollController _scrollController;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12.0),
      child: Scrollbar(
        child: BlocBuilder(
          bloc: BlocProvider.of<NoteBloc>(context),
          builder: (BuildContext context, NoteState state) =>
              this._buildListView(state),
        ),
      ),
    );
  }

  Widget _buildListView(NoteState state) {
    if (state is NoteLoadedState) {
      return ListView.builder(
        controller: this._scrollController,
        itemCount: state.document.elements.length,
        itemBuilder: (BuildContext context, int index) =>
            buildNoteElementWidget(context, state.document.elements[index]),
      );
    }
    return Container();
  }
}

class _NoteChatField extends StatelessWidget {
  _NoteChatField({Key key, @required this.onText, @required this.onPickImage})
      : super(key: key);

  final _controller = TextEditingController(text: '');
  final void Function(String) onText;
  final void Function() onPickImage;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 4, bottom: 4, right: 12),
      decoration: BoxDecoration(
        border:
            Border(top: BorderSide(color: const Color(0x08000000), width: 2)),
        color: const Color(0x04000000),
      ),
      child: Row(children: <Widget>[
        IconButton(
          icon: Icon(Icons.photo_library),
          onPressed: this.onPickImage,
        ),
        Expanded(
          child: Container(
            child: TextFormField(
              decoration: InputDecoration(
                  contentPadding: const EdgeInsets.all(12),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(
                        style: BorderStyle.solid,
                        width: 20,
                        color: Colors.grey),
                    borderRadius: const BorderRadius.all(
                      const Radius.circular(36.0),
                    ),
                  ),
                  filled: true,
                  hintStyle: TextStyle(color: Colors.black12, fontSize: 14),
                  hintText: "Type in your text",
                  fillColor: Colors.white70),
              style: TextStyle(fontSize: 14),
              controller: this._controller,
              onEditingComplete: this._onEditingComplete,
            ),
          ),
        )
      ]),
    );
  }

  void _onEditingComplete() {
    this.onText(this._controller.text);
    this._controller.clear();
  }
}
