import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

Future<Database> openNotesDb() async {
  final dir = await getDatabasesPath();

  return openDatabase(
    p.join(dir, 'offline_notes.db'),
    version: 4,

    onCreate: (db, version) async {
      await db.execute('''
        CREATE TABLE notes(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT NOT NULL,
          body TEXT NOT NULL DEFAULT '',
          updated_at TEXT NOT NULL,
          dirty INTEGER NOT NULL DEFAULT 0
        )
      ''');

      await _createCachedPostsTable(db);
    },

    onUpgrade: (db, oldVersion, newVersion) async {
      if (oldVersion < 4) {
        // cached_posts hanya berisi cache API,
        // sehingga aman dibuat ulang ketika schema berubah.
        await db.execute(
          'DROP TABLE IF EXISTS cached_posts',
        );

        await _createCachedPostsTable(db);
      }
    },
  );
}

Future<void> _createCachedPostsTable(Database db) async {
  await db.execute('''
    CREATE TABLE cached_posts(
      id INTEGER PRIMARY KEY,
      user_id INTEGER NOT NULL DEFAULT 0,
      title TEXT NOT NULL,
      body TEXT NOT NULL
    )
  ''');
}