import 'package:flutter/material.dart';

import '../constants/color_map.dart';
import '../store/preference.dart';
import 'page_names.dart';

class SplashPage extends StatefulWidget {
  static const String routeName = PageNames.splash;

  SplashPage({Key key}) : super(key: key);

  _SplashPageState createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    this._warmUpAndStart();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorMap.key3,
      body: Center(
        child: Image.asset('assets/images/logo.png', width: 240),
      ),
    );
  }

  Future<void> _warmUpAndStart() async {
    await Preference().warmUp();
    await Future.delayed(Duration(seconds: 2));
    Navigator.of(context).pushReplacementNamed(PageNames.noteList);
  }
}
