import 'package:meta/meta.dart';
import 'package:flutter/material.dart';

class Snacks {
  final ScaffoldState state;

  Snacks._({@required this.state}) : assert(state != null);

  factory Snacks.of(ScaffoldState state) {
    return Snacks._(state: state);
  }

  factory Snacks.contextOf(BuildContext context) {
    return Snacks._(state: Scaffold.of(context));
  }

  Future<void> undoableDelete({
    @required String title,
    @required void Function(bool) markAsDeleted,
    @required void Function() purge,
  }) async {
    markAsDeleted(true);

    await this
        .state
        .showSnackBar(SnackBar(
          content: Text(title),
          action: SnackBarAction(
            label: '취소',
            onPressed: () {
              markAsDeleted(false);
            },
          ),
        ))
        .closed
        .then((SnackBarClosedReason reason) {
      switch (reason) {
        case SnackBarClosedReason.action:
          break;
        case SnackBarClosedReason.dismiss:
        case SnackBarClosedReason.hide:
        case SnackBarClosedReason.remove:
        case SnackBarClosedReason.swipe:
          markAsDeleted(false);
          break;
        case SnackBarClosedReason.timeout:
          purge();
          break;
      }
    });
  }

  Future<void> text(String text) {
    this.state.hideCurrentSnackBar();
    return this
        .state
        .showSnackBar(SnackBar(
          content: Text(text),
          action: SnackBarAction(
            label: '닫기',
            onPressed: () {
              this.state.hideCurrentSnackBar();
            },
          ),
        ))
        .closed;
  }
}
