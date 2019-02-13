import 'dart:async';
import 'dart:io' as io;
import 'package:shared_preferences/shared_preferences.dart';
import 'conversation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';



class sqlConversation {

  final String tableTodo = 'Conversation';
  final String columnId = 'id';
  final String conversationId = 'conversationId';
  final String username = 'username';
  final String currentUser = 'currentUser';

  static final sqlConversation _instance = new sqlConversation.internal();
  factory sqlConversation() => _instance;
  static Database _db;

  Future<Database> get db async {
    if (_db != null) return _db;
    _db = await initDb();
    return _db;
  }

  sqlConversation.internal();

  initDb() async {
    io.Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, "convercation.db");
    var theDb = await openDatabase(path, version: 1, onCreate: _onCreate);
    return theDb;
  }

  void _onCreate(Database db, int version) async {
    // When creating the db, create the table
    await db.execute('''
        create table $tableTodo (
        $columnId integer primary key autoincrement,
        $currentUser text not null,
        $conversationId text not null,
        $username text not null)
       ''');
  }

  Future<int> saveConversation(Conversation conversation) async {
    var dbClient = await db;
    int res = await dbClient.insert(tableTodo, conversation.toMap());
    return res;
  }

  Future<bool> conversationExist(String uname) async {
    var dbClient = await db;
    List<Map> list = await dbClient.query(tableTodo,
        columns: [currentUser, conversationId, username],
        where: '"username" = ?',
        whereArgs: [uname]);
    print(list);
    int length = list.length;
    if (length == 0) {
      return false;
    } else {
      return true;
    }
  }

  Future<List<Conversation>> getcurrentUserConversation() async {
    var dbClient = await db;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String cUser = prefs.getString('currentUser');
    List<Map> list = await dbClient.query(tableTodo,
        columns: [currentUser, conversationId, username],
        where: '"currentUser" = ?',
        whereArgs: [cUser]);
    List<Conversation> conversations = new List();
    for (int i = 0; i < list.length; i++) {
      var conversation = new Conversation(
          cUser, list[i]["conversationId"], list[i]["username"]);
      conversation.setConversationId(list[i]["id"]);
      conversations.add(conversation);
    }
    print('会话列表数：${conversations.length}');
    return conversations;
  }

  Future<int> deleteConversation(Conversation conversation) async {
    var dbClient = await db;
    int res = await dbClient
        .rawDelete('DELETE FROM Conversation WHERE id = ?', [conversation.id]);
    return res;
  }

  Future<bool> update(Conversation conversation) async {
    var dbClient = await db;
    int res = await dbClient.update(tableTodo, conversation.toMap(),
        where: "id = ?", whereArgs: <int>[conversation.id]);
    return res > 0 ? true : false;
  }
}
