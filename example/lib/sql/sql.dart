import 'dart:async';
import 'dart:io' as io;
import 'message.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class sql {
  static final sql _instance = new sql.internal();
  factory sql() => _instance;
  static Database _db;

  Future<Database> get db async {
    if (_db != null) return _db;
    _db = await initDb();
    return _db;
  }

  sql.internal();

  initDb() async {
    io.Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, "message.db");
    var theDb = await openDatabase(path, version: 1, onCreate: _onCreate);
    return theDb;
  }

  void _onCreate(Database db, int version) async {
    // When creating the db, create the table
    await db.execute(
        "CREATE TABLE Message(id INTEGER PRIMARY KEY,content TEXT, messagefrom TEXT,conversationId TEXT)");
  }

  Future<int> saveMessage(Message message) async {
    var dbClient = await db;
    int res = await dbClient.insert("Message", message.toMap());
    return res;
  }

  Future<List<Message>> getMessage() async {
    var dbClient = await db;
    List<Map> list = await dbClient.rawQuery('SELECT * FROM Message');
    List<Message> messages = new List();
    for (int i = 0; i < list.length; i++) {
      var message = new Message(list[i]["content"], list[i]["messagefrom"],
          list[i]["conversationId"]);
      message.setMessageId(list[i]["id"]);
      messages.add(message);
    }
    print(messages.length);
    return messages;
  }

  Future<List<Message>> getMessageFrom(String conversationId) async {
    var dbClient = await db;
    List<Map> list = await dbClient.query("Message",
        columns: ["content", "messagefrom", "conversationId"],
        where: '"conversationId" = ?',
        whereArgs: [conversationId]);
    List<Message> messages = new List();
    for (int i = 0; i < list.length; i++) {
      var message = new Message(list[i]["content"], list[i]["messagefrom"],
          list[i]['conversationId']);
      message.setMessageId(list[i]["id"]);
      messages.add(message);
    }
    print(messages.length);
    return messages;
  }

  Future<int> deleteUsers(Message message) async {
    var dbClient = await db;
    int res = await dbClient
        .rawDelete('DELETE FROM Message WHERE id = ?', [message.id]);
    return res;
  }

  Future<bool> update(Message message) async {
    var dbClient = await db;
    int res = await dbClient.update("Message", message.toMap(),
        where: "id = ?", whereArgs: <int>[message.id]);
    return res > 0 ? true : false;
  }
}
