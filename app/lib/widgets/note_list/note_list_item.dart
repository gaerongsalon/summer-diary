import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../models/note_list.dart';
import '../../bloc/note_list/bloc.dart';
import '../../pages/page_names.dart';
import '../../widgets/snacks.dart';

final formatter = DateFormat('yyyy년 M월 d일 h시');

class NoteListItem extends StatelessWidget {
  const NoteListItem({Key key, @required this.element}) : super(key: key);

  final NoteListItemElement element;

  @override
  Widget build(BuildContext context) {
    return InkWell(
        onTap: () => _onItemTap(context),
        child: Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
              border:
                  Border(bottom: BorderSide(color: const Color(0x20000000)))),
          child: Dismissible(
              key: ObjectKey(this.element.noteId),
              child: _buildItemColumn(),
              onDismissed: (direction) =>
                  this._onConfirmDismiss(context, direction)),
        ));
  }

  void _onItemTap(BuildContext context) {
    Navigator.of(context).pushNamed(PageNames.note,
        arguments: NotePageArguments(noteId: this.element.noteId));
  }

  Widget _buildItemColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: Text(this.element.title,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        Row(
          children: <Widget>[
            Text(formatter.format(this.element.created) + ' 만듦',
                style: TextStyle(fontSize: 15)),
          ],
        ),
      ],
    );
  }

  void _onConfirmDismiss(
      BuildContext context, DismissDirection direction) async {
    if (direction != DismissDirection.startToEnd) {
      return;
    }

    final bloc = BlocProvider.of<NoteListBloc>(context);
    await Snacks.of(context).undoableDelete(
        title: '노트를 삭제했습니다.',
        markAsDeleted: (deleted) => bloc.dispatch(
            MarkNoteAsDeleted(noteId: this.element.noteId, deleted: deleted)),
        purge: () => bloc.dispatch(PurgeNote(noteId: this.element.noteId)));
  }
}
