import 'package:meta/meta.dart';
import 'package:flutter/material.dart';

class Snacks {
  final BuildContext context;

  Snacks._({@required this.context}) : assert(context != null);

  factory Snacks.of(BuildContext context) {
    return Snacks._(context: context);
  }

  Future<void> undoableDelete({
    @required String title,
    @required void Function(bool) markAsDeleted,
    @required void Function() purge,
  }) async {
    markAsDeleted(true);

    await Scaffold.of(this.context)
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
    Scaffold.of(context).hideCurrentSnackBar();
    return Scaffold.of(this.context)
        .showSnackBar(SnackBar(
          content: Text(text),
          action: SnackBarAction(
            label: '닫기',
            onPressed: () {
              Scaffold.of(context).hideCurrentSnackBar();
            },
          ),
        ))
        .closed;
  }
}
