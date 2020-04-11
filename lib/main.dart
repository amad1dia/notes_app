import 'package:flutter/material.dart';

import 'notes_screens.dart';

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
        primaryColor: Colors.greenAccent,
        brightness: Brightness.dark,
        secondaryHeaderColor: Colors.green,
      ),
    );
  }
}
