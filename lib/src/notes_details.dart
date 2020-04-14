import 'package:flutter/material.dart';
import 'package:notes_app/src/utils.dart';

import 'notes_db.dart';

class NoteDetailsScreen extends StatefulWidget {
  final Note note;

  NoteDetailsScreen(this.note);

  @override
  State<StatefulWidget> createState() => NoteDetailsScreenState();
}

class NoteDetailsScreenState extends State<NoteDetailsScreen> {
  NoteRepository _noteRepository;
  bool _keyBoardEnabled = true;
  final myController = TextEditingController();
  FocusNode _myFocusNode;

  @override
  void initState() {
    super.initState();
    _noteRepository = NoteRepository();
    _myFocusNode = FocusNode();
  }

  @override
  void dispose() {
    // Clean up the focus node when the Form is disposed.
    _myFocusNode.dispose();
    _noteRepository = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      resizeToAvoidBottomPadding: false,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: Text("Details de la note"),
        elevation: 4.0,
        actions: <Widget>[
          IconButton(
            icon: Icon(_keyBoardEnabled ? Icons.edit : Icons.done),
            onPressed: () {
              setState(() {
                _keyBoardEnabled = !_keyBoardEnabled;
                _myFocusNode.requestFocus();
              });
            },
          ),
          PopupMenuButton(
            itemBuilder: (BuildContext _) {
              return [
                PopupMenuItem(
                    child: FlatButton.icon(
                        onPressed: () {
                          _noteRepository.delete(widget.note).then((value) {
                            Navigator.of(context).pop();
                          });
                        },
                        icon: const Icon(Icons.delete),
                        label: Text('Supprimer'))),
                PopupMenuItem(
                    child: FlatButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.archive),
                        label: const Text('Archiver')))
              ];
            },
          )
        ],
      ),
      body: noteDetailsWidget(),
    );
  }

  Widget noteDetailsWidget() {
    Note note = widget.note;
    var noteDate = 'Editée le ${formatDate(parseDate(note.date))}';
    return Container(
      padding: EdgeInsets.only(left: 8.0, right: 8.0),
      margin: EdgeInsets.only(left: 8.0, right: 8.0, top: 8.0),
      child: SingleChildScrollView(
          child: ListBody(children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text(
                  note.title,
                  style: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
                ),
                Text(
                  noteDate,
                  style: TextStyle(fontSize: 12.0, fontWeight: FontWeight.normal),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            Divider(
              color: Colors.grey,
            ),
            TextFormField(
              initialValue: note.content,
              maxLines: _keyBoardEnabled ? null : 6,
              readOnly: _keyBoardEnabled,
              focusNode: _myFocusNode,
              keyboardType: TextInputType.multiline,
              scrollPadding: EdgeInsets.all(10.0),
              style: TextStyle(
                fontSize: 16.0,
              ),
              onChanged: (String value) {
                setState(() {
                  note.content = value;
                  _noteRepository.update(note);
                });
              },
            ),
          ])),
    );
  }
}