import 'package:flutter/material.dart';

class PromptDialog extends StatelessWidget {
  PromptDialog({
    Key key,
    @required this.title,
    String defaultValue = "",
  })  : _controller = TextEditingController(text: defaultValue),
        super(key: key);

  final String title;
  final TextEditingController _controller;

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      title: Text(this.title),
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(
              top: 8.0, left: 16.0, right: 16.0, bottom: 24.0),
          child: TextFormField(
            controller: this._controller,
            autofocus: true,
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            RaisedButton(
              child: Text('취소'),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            RaisedButton(
              child: Text('추가'),
              onPressed: () {
                Navigator.pop(context, this._controller.text);
              },
            ),
          ],
        )
      ],
    );
  }
}
