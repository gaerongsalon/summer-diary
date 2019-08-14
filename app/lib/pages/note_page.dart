import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:image_picker/image_picker.dart';
import 'package:multi_image_picker/multi_image_picker.dart';

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
  final _bloc = NoteBloc();

  @override
  void initState() {
    super.initState();
    this._bloc.dispatch(LoadNote(noteId: widget.noteId));
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
    if (state is NoteLoadedState) {
      return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: Icon(Icons.arrow_back),
              tooltip: '뒤로가기',
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            titleSpacing: 4,
            title: Text(state.document.title),
            actions: [this._buildRefreshButton()],
          ),
          body: SafeArea(
            bottom: false,
            child: _NoteElementList(),
          ),
          floatingActionButton: this._buildAddButton(context));
    }
    return Center(
      child: Text('불러오고 있습니다.'),
    );
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
      child: Icon(Icons.add),
      tooltip: '추가',
      children: [
        SpeedDialChild(
            child: Icon(Icons.photo_library),
            label: '사진',
            onTap: () => this._pickImages(context)),
        SpeedDialChild(
          child: Icon(Icons.chat),
          label: '메시지',
          onTap: () => this._addChat(context),
        ),
        SpeedDialChild(
          child: Icon(Icons.portrait),
          label: '프로필 바꾸기',
          onTap: () => this._changeProfile(context),
        ),
      ],
    );
  }

  void _pickImages(BuildContext context) async {
    final sourceFiles =
        await MultiImagePicker.pickImages(maxImages: 20, enableCamera: true);
    if (sourceFiles == null) {
      Snacks.of(context).text('취소합니다.');
      return;
    }
    final files = await Future.wait(sourceFiles.map((each) => each.filePath));
    this._bloc.dispatch(AddImage(fileLocations: files));
  }

  void _addChat(BuildContext context) async {
    final response = await showDialog(
        context: context,
        builder: (BuildContext context) => PromptDialog(title: '새 메시지'));
    if (response == null) {
      Snacks.of(context).text('취소합니다.');
      return;
    }
    final text = (response as String).trim();
    if (text.length > 0) {
      this._bloc.dispatch(AddChat(text: text, level: 15));
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
      Snacks.of(context).text('취소합니다.');
      return;
    }
    final name = (nameResponse as String).trim();
    if (name.length == 0) {
      Snacks.of(context).text('취소합니다.');
      return;
    }
    final image = await ImagePicker.pickImage(source: ImageSource.gallery);
    if (image == null) {
      Snacks.of(context).text('취소합니다.');
      return;
    }
    this._bloc.dispatch(
        ChangeUserProfile(name: name, fileLocation: image.absolute.path));
  }
}

class _NoteElementList extends StatelessWidget {
  _NoteElementList({
    Key key,
  }) : super(key: key);

  final ScrollController _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      child: BlocBuilder(
        bloc: BlocProvider.of<NoteBloc>(context),
        builder: (BuildContext context, NoteState state) =>
            this._buildListView(state),
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
