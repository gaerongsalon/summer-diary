import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bloc/note_list/bloc.dart';
import 'note_list_item.dart';

class NoteList extends StatelessWidget {
  final _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      child: BlocBuilder(
        bloc: BlocProvider.of<NoteListBloc>(context),
        builder: (BuildContext context, NoteListState state) =>
            this._buildListView(context, state),
      ),
    );
  }

  Widget _buildListView(BuildContext context, NoteListState state) {
    if (state is UnInitNoteListState) {
      return Center(
        child: Text('불러오는 중...'),
      );
    } else if (state is NoteListLoadedState) {
      if (state.items.length == 0) {
        return Center(child: Text('하단의 +를 눌러 새 노트를 시작할 수 있어요!'));
      }
      return ListView.builder(
          controller: this._scrollController,
          itemCount: state.items.length,
          itemBuilder: (BuildContext context, int index) => NoteListItem(
                element: state.items[index],
              ));
    }
    return Container();
  }
}
