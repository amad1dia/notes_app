import 'dart:developer';

import 'package:flushbar/flushbar.dart';
import 'package:flutter/material.dart';

import 'notes_db.dart';
import 'utils.dart';

class NoteScreen extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => NoteScreenState();
}

class NoteScreenState extends State<NoteScreen> {
  List<Note> _notes = <Note>[];
  NoteRepository _repository;
  final _contentController = TextEditingController();
  final _titleController = TextEditingController();
  int _currentIndex = 0;
  final _formKey = GlobalKey<FormState>();
  bool isEnabled = false;

  bool _isFavorite = false;

  String _listTitle = 'Mes Notes';

  var _isVisible = true;

  @override
  void initState() {
    super.initState();
    _repository = NoteRepository();
    _updateView();
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
        appBar: AppBar(
            elevation: 4,
            title: Text(
              'Appli de prise notes',
              textAlign: TextAlign.center,
            ),
            actions: <Widget>[
              IconButton(
                icon:
                    Icon(_isFavorite ? Icons.favorite : Icons.favorite_border),
                tooltip: 'Notes favorites',
                onPressed: () {
                  setState(() {
                    _isFavorite = !_isFavorite;
                    _updateView();
                  });
                },
              ),
            ]),
        bottomNavigationBar: BottomNavigationBar(
            elevation: 8,
            selectedItemColor: Colors.deepPurple,
            backgroundColor: Colors.white70,
            onTap: (index) {
              _onTabTapped(index);
              _updateView();
            },
            // new
            currentIndex: _currentIndex,
            // ne
            items: [
              BottomNavigationBarItem(
                  icon: Icon(Icons.list), title: Text('Mes notes')),
              BottomNavigationBarItem(
                icon: Icon(Icons.archive),
                title: Text('Archivées'),
              ),
            ]),
        body: _noteListWidget(_currentIndex),
        floatingActionButton: Visibility(
          visible: _isVisible,
          child: FloatingActionButton(
            elevation: 4,
            onPressed: () {
              // ignore: unnecessary_statements
              _addCourse();
            },
            child: Icon(Icons.add),
            backgroundColor: Colors.deepPurpleAccent,
          ),
        ));
  }

  void changeMode(value) {
    setState(() {
      isEnabled = value;
    });
  }

  @override
  void dispose() {
    // Clean up the controller when the widget is removed from the
    // widget tree.
    _contentController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  _addCourse() {
    return showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Ajout d\'une nouvelle note'),
            insetPadding: EdgeInsets.all(5.0),
            content: SingleChildScrollView(
              padding: EdgeInsets.all(5.0),
              child: _dialogFormInput(),
            ),
            actions: <Widget>[
              new FlatButton(
                onPressed: () {
                  closeWindow(context);
                },
                child: Text('Annuler'),
                textColor: Colors.redAccent,
              ),
              new FlatButton(
                onPressed: () {
                  if (_formKey.currentState.validate()) {
                    var note = Note(
                        content: _contentController.text,
                        title: _titleController.text,
                        date: DateTime.now().toIso8601String());
                    _repository.insert(note).then((value) {
                      setState(() {
                        //Update widget
                        _updateView();
                        closeWindow(context);
                      });
                    });
                  }
                },
                child: Text('Valider'),
                textColor: Colors.deepPurpleAccent,
              )
            ],
          );
        });
  }

  Widget _dialogFormInput() {
    return Form(
        key: _formKey,
        child: ListBody(
          children: <Widget>[
            TextFormField(
              cursorColor: Colors.deepPurpleAccent,
              controller: _titleController,
              validator: (value) => validateField(value, 'Entrer un titre'),
              decoration: InputDecoration(
                  labelText: 'Titre de la note',
                  hintText: 'Saisir le titre de la note'),
            ),
            TextFormField(
              cursorColor: Colors.deepPurpleAccent,
              controller: _contentController,
              validator: (value) =>
                  validateField(value, 'Entrer une description'),
              keyboardType: TextInputType.text,
              maxLines: null,
              decoration: InputDecoration(
                  hintText: 'En quoi consitue la note',
                  labelText: 'Description'),
              enableSuggestions: true,
            ),
          ],
        ));
  }

  String validateField(value, String message) => value.isEmpty ? message : null;

  ///
  /// Update view depending to the current bottom menu item
  void _updateView() {
    if (_isFavorite) {
      _listTitle = 'Notes Favorites';
      _repository.getNotes().then((notes) {
        _notes.clear();
        _notes.addAll(notes.where((note) => note.isFavorite == 1));
      });
      return;
    }
    if (_currentIndex == 0) {
      _isVisible = true;
      _listTitle = 'Dernières Notes';
      _repository.getNotes().then((notes) {
        _notes.clear();
        _notes.addAll(notes.where((note) => note.isArchived == 0));
      });
    } else if (_currentIndex == 1) {
      _isVisible = false;
      _listTitle = 'Notes Archivées';
      _repository.getArchivedNotes().then((notes) {
        _notes.clear();
        _notes.addAll(notes);
      });
    }
  }

  Widget _noteListWidget(index) {
    Future<List<Note>> future;
    if (index == 0)
      future = _repository.getNotes();
    else if (index == 1) future = _repository.getArchivedNotes();
    //Permet charger les donnees a partir de la base de facon async
    return FutureBuilder<List<Note>>(
        future: future,
        builder: (_, AsyncSnapshot<List<Note>> snapshot) {
          List<Widget> children;
          if (snapshot.hasData) {
            children = <Widget>[
              Container(
                padding: EdgeInsets.all(8.0),
                child: Text(
                  // Adaptez le titre selon la vue active
                  _listTitle.toUpperCase(),
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18.0),
                ),
              ),
              Flexible(child: listViewWidget())
            ];
          } else if (snapshot.hasError) {
            children = <Widget>[
              Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 60,
              ),
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text('Error: ${snapshot.error}'),
              )
            ];
          } else {
            children = <Widget>[
              SizedBox(
                child: Center(child: CircularProgressIndicator()),
                width: 60,
                height: 60,
              ),
              const Padding(
                padding: EdgeInsets.only(top: 16),
                child: Text('Chargement des données...'),
              )
            ];
          }
          return Center(
            child: Column(children: children),
          );
        });
  }

  Widget _gridViewWidget() {
    return GridView.count(
      // Create a grid with 2 columns. If you change the scrollDirection to
      // horizontal, this produces 2 rows.
      crossAxisCount: 2,
      children: List.generate(_notes.length, (index) {
        return Container(
          padding: const EdgeInsets.all(8),
          child: Text(_notes[index].title),
          color: Colors.teal[400],
        );
      }),
    );
  }

  Widget listViewWidget() {
    return ListView.separated(
        itemBuilder: (context, index) => _listTileItem(_notes[index], context),
        separatorBuilder: (_, index) => const Divider(height: 1.0),
        itemCount: _notes.length);
  }

  Widget _listTileItem(Note note, context) {
    final bool alreadyArchived = note.isArchived == 1;
    final bool isFavorite = note.isFavorite == 1;
    var _listTileFont = alreadyArchived
        ? TextStyle(decoration: TextDecoration.lineThrough)
        : TextStyle(decoration: TextDecoration.none);
    var noteContent = note.content;
    return Dismissible(
      key: Key(note.id.toString()),
      child: Card(
        elevation: 8,
        margin: EdgeInsets.all(8.0),
        child: ListTile(
          contentPadding: EdgeInsets.all(5.0),
          title: Text(
            note.title,
            style: _listTileFont,
          ),
          leading: IconButton(
            icon:
                isFavorite ? Icon(Icons.favorite) : Icon(Icons.favorite_border),
            onPressed: () {
              setState(() {
                //Change note status
                note.isFavorite = note.isFavorite == 1 ? 0 : 1;
                _repository.update(note).then((value) {
                  setState(() {
                    showFavoriteSnackBar(context, isFavorite);
                  });
                }).catchError((onError) {
                  print('${onError.toString()}');
                });
              });
            },
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Divider(
                color: Colors.grey,
              ),
              Text(
                noteContent.length >= 120
                    ? '${noteContent.substring(0, 100)}... Voir plus'
                    : noteContent,
                textAlign: TextAlign.justify,
//                style: TextStyle(color: Colors.black54),
              ),
              Divider(
                color: Colors.grey,
              ),
              Text(
                note.date == null
                    ? 'No date'
                    : 'Editée le ${formatDate(parseDate(note.date))}',
                style: TextStyle(fontStyle: FontStyle.italic),
                textAlign: TextAlign.end,
              )
            ],
          ),
          trailing: IconButton(
            icon: Icon(Icons.delete),
            onPressed: () => _deleteConfirmDialog(note),
          ),
          onTap: () => _showCourseDetails(note),
        ),
      ),
      onDismissed: (direction) {
        // Remove the item from the data source.
        setState(() {
          _notes.remove(note);
          note.isArchived = note.isArchived == 1 ? 0 : 1;
          log(note.toString());
          _repository.update(note).then((value) {
            setState(() {
              showArchivedSnackBar(context, alreadyArchived);
            });
          }).catchError((onError) {
            print('${onError.toString()}');
          });
        });
      },
      background: Container(color: Colors.deepPurpleAccent),
    );
  }

  void showFavoriteSnackBar(context, bool isFavorite) {
    var textStyle = TextStyle(color: Colors.white);
    final snackBar = Flushbar(
      margin: EdgeInsets.only(left: 8, right: 8, bottom: 8),
      borderRadius: 4,
      backgroundColor: Colors.black54,
      duration: Duration(seconds: 3),
      messageText: isFavorite
          ? Text(
              'Note supprimée des favoris avec succès',
              style: textStyle,
            )
          : Text(
              'Note ajoutée au favoris avec succès',
              style: textStyle,
            ),
      mainButton: FlatButton(
        child: Text('Annuler'),
        onPressed: () {
          // Some code to undo the change.
        },
      ),
    );

    // Find the Scaffold in the widget tree and use
    // it to show a SnackBar.
    snackBar.show(context);
  }

  void showArchivedSnackBar(context, bool alreadyArchived) {
    var textStyle = TextStyle(color: Colors.white);
    final snackBar = Flushbar(
      margin: EdgeInsets.only(left: 8, right: 8, bottom: 8),
      borderRadius: 4,
      backgroundColor: Colors.black54,
      duration: Duration(seconds: 3),
      messageText: alreadyArchived
          ? Text(
              'Note desarchivée avec succès',
              style: textStyle,
            )
          : Text(
              'Note archivée avec succès',
              style: textStyle,
            ),
      mainButton: FlatButton(
        child: Text('Annuler'),
        onPressed: () {
          // Some code to undo the change.
        },
      ),
    );

    // Find the Scaffold in the widget tree and use
    // it to show a SnackBar.
    snackBar.show(context);
  }

  _deleteConfirmDialog(Note note) {
    return showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text(
              'Suppression de la note',
            ),
            content: Text('Voulez-vous supprimer cette note?'),
            actions: <Widget>[
              FlatButton(
                child: Text(
                  'Annuler',
                  style: TextStyle(
                    color: Colors.redAccent,
                  ),
                ),
                onPressed: () {
                  closeWindow(context);
                },
              ),
              FlatButton(
                onPressed: () {
                  _repository.delete(note).then((value) {
                    setState(() {
                      _notes.remove(note);
                      closeWindow(context);
                    });
                  });
                },
                child: Text(
                  'Oui',
                ),
                textColor: Colors.deepPurpleAccent,
              ),
            ],
          );
        });
  }

  void closeWindow(BuildContext context) {
    Navigator.of(context).pop();
  }

  void _showCourseDetails(Note note) {
    Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (BuildContext context) {
      return NoteDetailsScreen(note);
    }));
  }

  void _onTabTapped(int index) {
    setState(() {
      _isFavorite = false;
      _currentIndex = index;
    });
  }
}

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
        elevation: 1.0,
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
