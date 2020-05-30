import 'dart:developer';

import 'package:flushbar/flushbar.dart';
import 'package:flutter/material.dart';
import 'package:notes_app/src/custom_widget.dart';

import 'notes_db.dart';
import 'notes_details.dart';
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
              ThemeSwitch(),
              IconButton(
                icon: Icon(Icons.search),
                onPressed: () {
                  showSearch(
                      context: context, delegate: NoteSearch(notes: _notes));
                },
              ),
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
            elevation: 4,
            selectedItemColor: Theme.of(context).accentColor,
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
              _addNote(context);
            },
            child: Icon(Icons.add),
            backgroundColor: Theme.of(context).accentColor,
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

  _addNote(BuildContext context) {
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
                textColor: Theme.of(context).accentColor,
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
              cursorColor: Theme.of(context).accentColor,
              controller: _titleController,
              validator: (value) => validateField(value, 'Entrer un titre'),
              decoration: InputDecoration(
                  labelText: 'Titre de la note',
                  hintText: 'Saisir le titre de la note'),
            ),
            TextFormField(
              cursorColor: Theme.of(context).accentColor,
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
        _notes.addAll(notes
            .where((note) => note.isFavorite == 1 && note.isArchived == 0));
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

  Widget listViewWidget() {
    return ListView.separated(
        itemBuilder: (context, index) => _listItem(_notes[index], context),
        separatorBuilder: (_, index) => const Divider(height: 1.0),
        itemCount: _notes.length);
  }

  Widget _listItem(Note note, context) {
    return Dismissible(
      key: Key(note.id.toString()),
      child: Card(
        elevation: 8,
        margin: EdgeInsets.all(8.0),
        child: listTile(note, context),
      ),
      onDismissed: (direction) {
        // Remove the item from the data source.
        setState(() {
          _notes.remove(note);
          note.isArchived = note.isArchived == 1 ? 0 : 1;
          log(note.toString());
          _repository.update(note).then((value) {
            setState(() {
              showArchivedSnackBar(context, note.isArchived == 0);
            });
          }).catchError((onError) {
            print('${onError.toString()}');
          });
        });
      },
      background: Container(color: Theme.of(context).accentColor),
    );
  }

  ListTile listTile(Note note, context) {
    final bool alreadyArchived = note.isArchived == 1;
    final bool isFavorite = note.isFavorite == 1;

    var listTileFont = alreadyArchived
        ? TextStyle(decoration: TextDecoration.lineThrough)
        : TextStyle(decoration: TextDecoration.none);
    return ListTile(
      contentPadding: EdgeInsets.all(5.0),
      title: Text(
        note.title,
        style: listTileFont,
      ),
      leading: IconButton(
        icon: isFavorite ? Icon(Icons.favorite) : Icon(Icons.favorite_border),
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
            note.content.length >= 120
                ? '${note.content.substring(0, 100)}... Voir plus'
                : note.content,
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
        onPressed: () => _deleteConfirmDialog(note, context),
      ),
      onTap: () => _showNoteDetails(note, context),
    );
  }

  void showFavoriteSnackBar(context, bool isFavorite) {
    var textStyle = TextStyle(color: Colors.white);
    final snackBar = Flushbar(
      margin: EdgeInsets.only(left: 8, right: 8, bottom: 8),
      borderRadius: 4,
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
        color: Theme.of(context).primaryColor,
        child: Text('Annuler'),
        onPressed: () {
          // TODO Some code to undo the change.
        },
      ),
    );

    // Find the Scaffold in the widget tree and use
    // it to show a SnackBar.
    snackBar.show(context);
  }

  void showArchivedSnackBar(context, bool alreadyArchived) {
    var textStyle = TextStyle(color: Theme.of(context).primaryColor);
    final snackBar = Flushbar(
      margin: EdgeInsets.only(left: 8, right: 8, bottom: 8),
      borderRadius: 4,
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
        color: Theme.of(context).primaryColor,
        child: Text(
          'Annuler',
        ),
        onPressed: () {
          // TODO Some code to undo the change.
        },
      ),
    );

    // Find the Scaffold in the widget tree and use
    // it to show a SnackBar.
    snackBar.show(context);
  }

  _deleteConfirmDialog(Note note, BuildContext context) {
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
                textColor: Theme.of(context).accentColor,
              ),
            ],
          );
        });
  }

  void closeWindow(BuildContext context) {
    Navigator.of(context).pop();
  }

  void _onTabTapped(int index) {
    setState(() {
      _isFavorite = false;
      _currentIndex = index;
    });
  }
}

void _showNoteDetails(Note note, BuildContext context) {
  Navigator.of(context)
      .push(MaterialPageRoute<void>(builder: (BuildContext context) {
    return NoteDetailsScreen(note);
  }));
}

class NoteSearch extends SearchDelegate<Note> {
  List<Note> notes;

  NoteSearch({this.notes});

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
          icon: Icon(Icons.close),
          onPressed: () {
            query = '';
          })
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
        icon: Icon(Icons.arrow_back),
        onPressed: () {
          close(context, null);
        });
  }

  @override
  Widget buildResults(BuildContext context) {
    final results = [];
    print(query);
    results.addAll(notes
        .where((n) => n.title.toLowerCase().contains(query.toLowerCase())));
//    print(results);
    return ListView.separated(
      itemCount: results.length,
      itemBuilder: (context, index) {
        var note = results[index];
        return ListTile(
          title: Text(note.title),
          onTap: () => _showNoteDetails(note, context),
        );
      },
      separatorBuilder: (_, index) => const Divider(height: 1.0),
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final results = [];
    results.addAll(notes
        .where((n) => n.title.toLowerCase().contains(query.toLowerCase())));
//    print(results);
    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        var note = results[index];
        return ListTile(
          title: Text(note.title, style: TextStyle(color: Colors.blue)),
          onTap: () => _showNoteDetails(note, context),
        );
      },
    );
  }
}
