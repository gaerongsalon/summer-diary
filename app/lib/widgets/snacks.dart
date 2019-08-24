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

  Future<void> text(String text,
      {Duration duration = const Duration(milliseconds: 4000),
      bool closable = false}) {
    this.state.hideCurrentSnackBar();
    final closeAction = SnackBarAction(
      label: '닫기',
      onPressed: () {
        this.state.hideCurrentSnackBar();
      },
    );
    final controller = this.state.showSnackBar(SnackBar(
          key: ValueKey('SnackBar'),
          content: Text(text),
          action: closable ? closeAction : null,
          duration: duration,
          animation: kAlwaysDismissedAnimation,
        ));
    return controller.closed;
  }

  void hide() => this.state.hideCurrentSnackBar();
}

class StatefulSnackBar {
  StatefulSnackBarController _controller;
  OverlayEntry _barrierEntry;

  void show(
      {@required BuildContext context,
      @required String message,
      bool barrier = true,
      Duration closeAfter}) async {
    if (!barrier) {
      this._barrierOff();
    }
    if (this._controller != null && !this._controller.closed.value) {
      this._controller.update(message: message);
    } else {
      this._controller = StatefulSnackBarController(message: message);
      if (this._barrierEntry == null && barrier) {
        this._barrierEntry = this._buildBarrier();
      }
      final entry = this._buildBar();
      if (barrier) {
        Overlay.of(context).insert(this._barrierEntry);
      }
      Overlay.of(context).insert(entry);
      _controller.closed.addListener(() {
        entry.remove();
        this._barrierOff();
      });
    }
    if (!this._controller.closed.value && closeAfter != null) {
      Future.delayed(closeAfter).then((_) {
        if (message == this._controller.message.value) {
          this.close();
        }
      });
    }
  }

  void close() {
    if (this._controller == null) {
      return;
    }
    this._controller.close();
    this._controller = null;
  }

  void _barrierOff() {
    if (this._barrierEntry == null) {
      return;
    }
    this._barrierEntry.remove();
    this._barrierEntry = null;
  }

  OverlayEntry _buildBar() => OverlayEntry(
      builder: (context) => Positioned(
            bottom: 0,
            child: Material(
              elevation: 4,
              child: _StatefulSnackBar(
                controller: this._controller,
              ),
            ),
          ));

  OverlayEntry _buildBarrier() => OverlayEntry(
      builder: (context) => Opacity(
            opacity: 0.2,
            child: Container(
              constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height,
                  maxWidth: MediaQuery.of(context).size.width),
              color: Colors.black,
            ),
          ));
}

class _StatefulSnackBarMessage extends ValueNotifier<String> {
  _StatefulSnackBarMessage({String value}) : super(value);
}

class _StatefulSnackBarClosed extends ValueNotifier<bool> {
  _StatefulSnackBarClosed({bool closed = false}) : super(closed);
}

class StatefulSnackBarController {
  final _StatefulSnackBarMessage message;
  final closed = _StatefulSnackBarClosed();

  StatefulSnackBarController({@required String message})
      : this.message = _StatefulSnackBarMessage(value: message);

  void update({@required String message}) {
    this.message.value = message;
  }

  void close() {
    if (this.closed.value) {
      return;
    }
    this.closed.value = true;
  }
}

class _StatefulSnackBar extends StatefulWidget {
  final StatefulSnackBarController controller;

  _StatefulSnackBar({@required this.controller});

  @override
  State<StatefulWidget> createState() => _StatefulSnackBarState();
}

class _StatefulSnackBarState extends State<_StatefulSnackBar> {
  @override
  void initState() {
    super.initState();
    widget.controller.message.addListener(this._onMessageChanged);
  }

  @override
  void dispose() {
    widget.controller.message.removeListener(this._onMessageChanged);
    super.dispose();
  }

  @override
  void didUpdateWidget(_StatefulSnackBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    oldWidget.controller.message.removeListener(this._onMessageChanged);
    widget.controller.message.addListener(this._onMessageChanged);
  }

  void _onMessageChanged() {
    this.setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      constraints: BoxConstraints(
          minHeight: 56, maxWidth: MediaQuery.of(context).size.width),
      color: const Color(0xFF222222),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Padding(
              padding:
                  const EdgeInsets.only(top: 12.0, bottom: 12.0, left: 18.0),
              child: Text(this.widget.controller.message.value,
                  style: textTheme.body1.copyWith(
                    fontSize: 14,
                    color: Colors.white,
                  )),
            ),
          ),
          /*
          FlatButton(
            child: Text('닫기',
                style: TextStyle(
                  color: Colors.lightBlue,
                )),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          */
        ],
      ),
    );
  }
}
