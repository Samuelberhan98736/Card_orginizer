import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('card_organizer.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE Folders(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        folder_name TEXT NOT NULL,
        timestamp TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE Cards(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        suit TEXT NOT NULL,
        image_url TEXT,
        folder_id INTEGER,
        FOREIGN KEY (folder_id) REFERENCES Folders(id)
      )
    ''');

    await _prepopulateData(db);
  }

  Future _prepopulateData(Database db) async {
    final suits = ['Hearts', 'Spades', 'Diamonds', 'Clubs'];
    final now = DateTime.now().toIso8601String();

    for (var suit in suits) {
      await db.insert('Folders', {
        'folder_name': suit,
        'timestamp': now,
      });
    }

    final cardNames = ['Ace', '2', '3', '4', '5', '6', '7', '8', '9', '10', 'Jack', 'Queen', 'King'];
    
    for (var suit in suits) {
      for (var name in cardNames) {
        await db.insert('Cards', {
          'name': name,
          'suit': suit,
          'image_url': 'https://deckofcardsapi.com/static/img/${_getCardCode(name, suit)}.png',
          'folder_id': null,
        });
      }
    }
  }

  String _getCardCode(String name, String suit) {
    String value;
    switch (name) {
      case 'Ace': value = 'A'; break;
      case '10': value = '0'; break;  // Deck of Cards API uses '0' for 10
      case 'Jack': value = 'J'; break;
      case 'Queen': value = 'Q'; break;
      case 'King': value = 'K'; break;
      default: value = name;
    }
    
    String suitCode = suit[0];  // H, S, D, or C
    return '$value$suitCode';
  }

  // FOLDER CRUD
  Future<List<Map<String, dynamic>>> getFolders() async {
    final db = await database;
    return await db.query('Folders');
  }

  Future<int> createFolder(String folderName) async {
    final db = await database;
    return await db.insert('Folders', {
      'folder_name': folderName,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  Future<int> updateFolder(int id, String newName) async {
    final db = await database;
    return await db.update(
      'Folders',
      {'folder_name': newName},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteFolder(int folderId) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('Cards', where: 'folder_id = ?', whereArgs: [folderId]);
      await txn.delete('Folders', where: 'id = ?', whereArgs: [folderId]);
    });
  }

  // CARD CRUD
  Future<List<Map<String, dynamic>>> getCardsInFolder(int folderId) async {
    final db = await database;
    return await db.query('Cards', where: 'folder_id = ?', whereArgs: [folderId]);
  }

  Future<List<Map<String, dynamic>>> getAvailableCards(String suit) async {
    final db = await database;
    return await db.query('Cards', where: 'suit = ? AND folder_id IS NULL', whereArgs: [suit]);
  }

  Future<int> getCardCountInFolder(int folderId) async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM Cards WHERE folder_id = ?', [folderId]);
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> addCardToFolder(int cardId, int folderId) async {
    final db = await database;
    return await db.update(
      'Cards',
      {'folder_id': folderId},
      where: 'id = ?',
      whereArgs: [cardId],
    );
  }

  Future<int> removeCardFromFolder(int cardId) async {
    final db = await database;
    return await db.update(
      'Cards',
      {'folder_id': null},
      where: 'id = ?',
      whereArgs: [cardId],
    );
  }

  Future<int> updateCard(int cardId, String name, int? folderId) async {
    final db = await database;
    return await db.update(
      'Cards',
      {'name': name, 'folder_id': folderId},
      where: 'id = ?',
      whereArgs: [cardId],
    );
  }

  Future<Map<String, dynamic>?> getFirstCardInFolder(int folderId) async {
    final db = await database;
    final result = await db.query('Cards', where: 'folder_id = ?', whereArgs: [folderId], limit: 1);
    return result.isNotEmpty ? result.first : null;
  }
}
