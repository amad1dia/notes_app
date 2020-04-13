import 'dart:async';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

const _NOTE_TABLE = 'notes';

class Note {
  int id;
  String title;
  String content;
  int isArchived;
  int isFavorite;
  String date;

  Note({this.id, this.title, this.content, this.isArchived = 0, this.date, this.isFavorite =0});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'isArchived': isArchived,
      'date': date,
      'isFavorite': isFavorite,
    };
  }

  @override
  String toString() {
    return 'Note : { '
        'id : $id, '
        'archived: $isArchived, '
        'title : $title, '
        'content : $content, '
        'date : $date '
        'isFavorite: $isFavorite'
        '}';
  }
}

class NoteRepository {
  Future<void> update(Note note) async {
    Database db = await NoteDBHelper.getDatabase();
    db.update(_NOTE_TABLE, note.toMap(),
        where: 'id = ? ', whereArgs: [note.id]);
  }

  Future<void> insert(Note note) async {
    Database db = await NoteDBHelper.getDatabase();
    await db.insert(_NOTE_TABLE, note.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> delete(Note note) async {
    Database db = await NoteDBHelper.getDatabase();
    await db.delete(_NOTE_TABLE, where: 'id = ?', whereArgs: [note.id]);
  }

  ///
  ///
  Future<List<Note>> getNotes() async {
    Database db = await NoteDBHelper.getDatabase();
    List<Map<String, dynamic>> maps = await db.query(_NOTE_TABLE);
    return List.generate(maps.length, (i) {
      return Note(
        id: maps[i]['id'],
        title: maps[i]['title'],
        content: maps[i]['content'],
        isArchived: maps[i]['isArchived'],
        date: maps[i]['date'],
        isFavorite: maps[i]['isFavorite'],
      );
    });
  }

  Future<List<Note>> getArchivedNotes() async {
    return getNotes().then((notes) =>
        notes.where((note) => note.isArchived == 1).toList());
  }

  Future<void> archiveNote(Note note) async {
    final Database db = await NoteDBHelper.getDatabase();
    return db.update(_NOTE_TABLE, note.toMap(),
        where: 'id = ?', whereArgs: [note.id]);
  }
}

class NoteDBHelper {
  static NoteDBHelper _databaseHelper; // Singleton DatabaseHelper
  static Database _database;

  factory NoteDBHelper() {
    if (_databaseHelper == null) {
      _databaseHelper = NoteDBHelper();
    }
    return _databaseHelper;
  }

  static Future<Database> getDatabase() async {
    if (_database == null) {
      _database = await initializeDatabase();
    }
    return _database;
  }

  static Future<Database> initializeDatabase() async {
    // Open/create the database at a given path
    var noteDatabase = await openDatabase(
      // Set the path to the database. Note: Using the `join` function from the
      // `path` package is best practice to ensure the path is correctly
      // constructed for each platform.
        join(await getDatabasesPath(), 'note.db'),
        // When the database is first created, create a table to store dogs.
        onCreate: _createDb,
        onUpgrade: _onUpgrade,
        version: 9);
    return noteDatabase;
  }

  static void _createDb(Database db, int newVersion) async {
    return db.execute(
      "CREATE TABLE $_NOTE_TABLE ("
          "id INTEGER PRIMARY KEY AUTOINCREMENT,"
          "title TEXT,"
          "content TEXT,"
          "isArchived INTEGER,"
          "isFavorite INTEGER,"
          "date TEXT"
          ")",
    );
  }

  static _onUpgrade(Database db, int oldVersion, int newVersion) async {
    await db.execute("DROP TABLE IF EXISTS $_NOTE_TABLE");
    _createDb(db, newVersion);
  }
}
