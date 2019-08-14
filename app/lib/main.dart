import 'package:flutter/material.dart';

import 'constants/color_map.dart';
import 'pages/pages.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '여름 새벽',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: ColorMap.dawn,
      ),
      initialRoute: '/',
      onGenerateRoute: this._routePage,
      home: SplashPage(),
    );
  }

  MaterialPageRoute _routePage(RouteSettings settings) {
    switch (settings.name) {
      case SplashPage.routeName:
        return MaterialPageRoute(builder: (context) => SplashPage());
      case NoteListPage.routeName:
        return MaterialPageRoute(builder: (context) => NoteListPage());
      case NotePage.routeName:
        return MaterialPageRoute(
            builder: (context) => NotePage(
                noteId: (settings.arguments as NotePageArguments).noteId));
      default: // HomeScreen.routeName:
        return MaterialPageRoute(builder: (context) => SplashPage());
    }
  }
}
