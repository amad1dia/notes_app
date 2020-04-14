import 'package:flutter/material.dart';

import 'src/notes_screens.dart';

void main() async {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      //Pass the repository to the view
      home: NoteScreen(),
      theme: ThemeData(
        primaryColor: Colors.white,
        brightness: Brightness.light,
      ),
    );
  }
}
