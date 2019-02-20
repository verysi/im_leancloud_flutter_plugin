import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../user.dart';

final String tableConversation = 'conversation';
final String columnId = '_id';
final String columnCurrentUser = 'currentUser';
final String columnConversationId = 'conversationId';
final String columnUsername = 'username';
final String columnLastReadAt = 'LastReadAt';
final String columnUpdateAt = 'UpdateAt';
final String columLastDelivered = 'LastDelivered';

class Conversation {
  String currentUser;
  String conversationId;
  String username;
  int LastReadAt;
  int UpdateAt;
  int LastDelivered;
  int id;

  Conversation(this.currentUser, this.conversationId, this.username,
      {this.LastReadAt, this.UpdateAt, this.LastDelivered, this.id});

  Conversation.fromMap(Map obj) {
    this.currentUser = obj[columnCurrentUser];
    this.conversationId = obj[columnConversationId];
    this.username = obj[columnUsername];
    this.LastReadAt = obj[columnLastReadAt];
    this.UpdateAt = obj[columnUpdateAt];
    this.LastDelivered = obj[columLastDelivered];
    this.id = obj[columnId];
  }

  Map<String, dynamic> toMap() {
    var map = <String, dynamic>{
      columnCurrentUser: this.currentUser,
      columnConversationId: this.conversationId,
      columnUsername: this.username,
    };

    if (LastReadAt != null) {
      map[columnLastReadAt] = this.LastReadAt;
    } else {
      map[columnLastReadAt] = 0;
    }

    if (UpdateAt != null) {
      map[columnUpdateAt] = this.UpdateAt;
    } else {
      map[columnUpdateAt] = 0;
    }

    if (LastDelivered != null) {
      map[columLastDelivered] = this.LastDelivered;
    } else {
      map[columLastDelivered] = 0;
    }

    if (id != null) {
      map[columnId] = this.id;
    }

    return map;
  }

//对Map列表进行排序，按照键值key从大到小排序
  static List<Map<String, dynamic>> SortListMaps(
      List<Map<String, dynamic>> list, String key) {
    if (list.length < 2) {
      return list;
    } else {
      //获取比较的标准（参考）值
      Map<String, dynamic> pivot = list[0];
      int refer = pivot[key];
      var less = <Map<String, dynamic>>[];
      var greater = <Map<String, dynamic>>[];
      for (int i = 1; i < list.length; i++) {
        int compare = list[i][key];
        if (compare >= refer) {
          print(i);
          //从大到小排序，if (i[key] <= pivot[key])从小到大
          less.add(list[i]);
        } else {
          greater.add(list[i]);
        }
      }
      //使用递归的方式，对less 和 greater 再进行排序，最终返回排序好的集合
      return SortListMaps(less, key) + [pivot] + SortListMaps(greater, key);
    }
  }
}

class ConversationSqlite {
  Database db;
  static List<String> conversationList = [];
  static List<Map<String, dynamic>> convmaps;
  openSqlite() async {
    // 获取数据库文件的存储路径
    var databasesPath = await getDatabasesPath();
    String path = join(databasesPath, 'demo.db');

//根据数据库文件路径和数据库版本号创建数据库表
    db = await openDatabase(path, version: 1,
        onCreate: (Database db, int version) async {
      await db.execute('''
          CREATE TABLE $tableConversation (
            $columnId INTEGER PRIMARY KEY, 
            $columnCurrentUser TEXT, 
            $columnConversationId TEXT, 
            $columnUsername TEXT, 
            $columnLastReadAt INTEGER,
            $columnUpdateAt INTEGER,
            $columLastDelivered INTEGER)
          ''');
    });
  }

  // 插入一条会话数据
  Future<Conversation> insert(Conversation conversation) async {
    await openSqlite();
    conversation.id = await db.insert(tableConversation, conversation.toMap());
    return conversation;
  }

  // 获取当前用户会话列表
  Future<List<Conversation>> getcurrentUserConversation(
      String currentUser) async {
    await openSqlite();
    List<Map> maps = await db.query(tableConversation,
        columns: [
          columnId,
          columnCurrentUser,
          columnConversationId,
          columnUsername,
          columnLastReadAt,
          columnUpdateAt,
          columLastDelivered
        ],
        where: '$columnCurrentUser = ?',
        whereArgs: [currentUser]);
    if (maps.length > 0) {
      maps = Conversation.SortListMaps(maps, columnUpdateAt); //按照会话时间排序
      print(maps);
      convmaps = maps;
      //conversationList.clear();
      List<Conversation> conversations = new List();
      for (int i = 0; i < maps.length; i++) {
       // conversationList.add(maps[i][columnUsername]);
        conversations.add(Conversation.fromMap(maps[i]));
      }
      return conversations;
    }
    return null;
  }

  // 判断会话是否存在
  Future<bool> conversationExist(String username) async {
    bool isExist = false;
    if (convmaps.length == 0 || convmaps == null) {
      return false;
    } else {
      for (var i in convmaps) {
        if (i['username'] == username) {
          isExist = true;
          break;
        }
      }
    }
    return isExist;
  }

  //根据conversationId从存储的会话列表里获取某个会话
  Future<Map<String, dynamic>> getConversation(String conversationId) async {
    print('根据conversatonId获取会话');
    print(convmaps);
    Map<String, dynamic> conv;
    if (convmaps.length > 0 || convmaps != null) {
      for (var i in convmaps) {
        if (conversationId == i['conversationId']) {
          conv = i;
          break;
        }
      }
    }
    print(conv);
    return conv;
  }

  //更新会话时间updateAt，排序会话列表
  Future<void> sequenceConversation(String conversationId, int UpdateAt) async {
    print('更新会话时间updateAt，排序会话列表');
    Map<String, dynamic> conv = await getConversation(conversationId);
    Map<String, dynamic> convmap = {
      '_id': conv['_id'],
      'currentUser': User.currentUser,
      'conversationId': conv['conversationId'],
      'username': conv['username'],
      'LastReadAt': conv['LastReadAt'],
      'UpdateAt': UpdateAt,
      'LastDelivered': conv['LastDelivered'],
    };
    print(convmap);
    await update(convmap);
  }

  //更新LastReadAt,为已读功能准备
  Future<void> updateLastReadAt(String conversationId, int LastReadAt) async {
    Map<String, dynamic> conv = await getConversation(conversationId);
    Map<String, dynamic> convmap = {
      '_id': conv['_id'],
      'currentUser': User.currentUser,
      'conversationId': conv['conversationId'],
      'username': conv['username'],
      'LastReadAt': LastReadAt,
      'UpdateAt': conv['UpdateAt'],
      'LastDelivered': conv['LastDelivered'],
    };
    print(convmap);
    await update(convmap);
  }

  //更新LastDelivered,更新对方接收时间
  Future<void> updateLastDelivered(
      String conversationId, int LastDelivered) async {
    print('更新LastDelivered,更新对方接收时间');
    Map<String, dynamic> conv = await getConversation(conversationId);
    Map<String, dynamic> convmap = {
      '_id': conv['_id'],
      'currentUser': User.currentUser,
      'conversationId': conv['conversationId'],
      'username': conv['username'],
      'LastReadAt': conv['LastReadAt'],
      'UpdateAt': conv['UpdateAt'],
      'LastDelivered': LastDelivered,
    };
    print(convmap);
    await update(convmap);
  }

  //删除会话消息
  Future<int> deleteConversation(int id) async {
    await openSqlite();
    return await db
        .delete(tableConversation, where: '$columnId = ?', whereArgs: [id]);
  }

  // 更新会话信息
  Future<int> update(Map<String, dynamic> conversation) async {
    await openSqlite();
    print('传入update数据库的数据');
    print(conversation);
    print('${conversation['_id']}');
    return await db.update(tableConversation, conversation,
        where: '$columnId = ?', whereArgs: [conversation[columnId]]);
  }

  // 记得及时关闭数据库，防止内存泄漏
  close() async {
    await db.close();
  }
}
