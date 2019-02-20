import 'package:flutter/material.dart';
import 'dart:convert';
import 'sql/conversation.dart';
import 'sql/sql.dart';
import 'dart:async';
import 'talk2.dart';
import 'login.dart';
import 'user.dart';
import 'package:im_leancloud_plugin/im_leancloud_plugin.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'custome_router.dart';

class contact extends StatefulWidget {
  @override
  contactState createState() => new contactState();
}

class contactState extends State<contact> {
  final TextEditingController EditingController = new TextEditingController();
  final TextEditingController textEditingController =
      new TextEditingController();
  final ScrollController listScrollController = new ScrollController();
  final StreamController<List<Conversation>> _streamController =
      StreamController<List<Conversation>>();
  ImLeancloudPlugin ImleancloudPlugin = ImLeancloudPlugin.getInstance();
  // List<String> contents=List<String>();
  final FocusNode focusNode = new FocusNode();
  ConversationSqlite dbc = new ConversationSqlite();
  sql db = new sql();
  List<Conversation> conversations;

  Future<void> saveNewconversation(
      String conversationId, String username) async {
    bool isconversationExist = await dbc.conversationExist(username);
    if (isconversationExist == false) {
      Conversation conversation =
          new Conversation(User.currentUser, conversationId, username);
      await dbc.insert(conversation);
      // getcurrentUserConversation();
    } else {
      print('会话已经存在');
    }
    await dbc.close();
  }

  Future _showNotification(String getfrom, String content) async {
    var flutterLocalNotificationsPlugin = new FlutterLocalNotificationsPlugin();
    var androidPlatformChannelSpecifics = new AndroidNotificationDetails(
        'your channel id', 'your channel name', 'your channel description',
        importance: Importance.Max, priority: Priority.High);
    var iOSPlatformChannelSpecifics = new IOSNotificationDetails();
    var platformChannelSpecifics = new NotificationDetails(
        androidPlatformChannelSpecifics, iOSPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin
        .show(0, getfrom, content, platformChannelSpecifics, payload: 'item x');
  }

  //获取接收过来的会话里对方用户名，只有两人会话的情况
  String conversationName(List<dynamic> members) {
    if (members.length > 1) {
      if (User.currentUser == members[0]) {
        return members[1];
      } else {
        return members[0];
      }
    } else {
      return members[0];
    }
  }

//处理未读消息
  Future<void> Unreadconversation(String jsonUnread) async {
    Map<String, dynamic> mapUnread = json.decode(jsonUnread);
    List<dynamic> members = mapUnread['getMembers'];
    String username = conversationName(members);
    String conversationId = mapUnread['conversationId'];
    await saveNewconversation(conversationId, username);
    _showNotification(username, '有未读消息');
  }

  //更新LastDelivered
  Future<void> updateLastDelivered(String jsonLastDelivered) async {
    Map<String, dynamic> mapLastdelivered = json.decode(jsonLastDelivered);
    String conversationId = mapLastdelivered['conversationId'];
    int LastDelivered = mapLastdelivered['LastDelivered'];
    await dbc.updateLastDelivered(conversationId, LastDelivered);
    dbc.close();
  }

  //设置已读功能，更新聊天状态

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    ImleancloudPlugin.addEventHandler(
      //接收实时消息
      onReceiveMessage: (Map<String, dynamic> message) async {
        print('这是contact文件传来的消息');
        print(message);
        String content = json.decode(message['content'])['_lctext'];
        _showNotification(message['getfrom'], content);
        await saveNewconversation(
            message['conversationId'], message['getfrom']);
        await dbc.sequenceConversation(
            message['conversationId'], message['Timestamp']);
        getcurrentUserConversation();
        // dbc.close();
      },
      //网络状态重新连接
      onConnectionResume: (isResume) async {
        print(isResume);
      },
      //未读消息状态发生变化
      unRead: (Map<String, dynamic> unreadmessage) async {
        print(unreadmessage);
        String jsonUnread = unreadmessage['unRead'];
        //await dbc.getcurrentUserConversation;
        await Unreadconversation(jsonUnread);
        getcurrentUserConversation();
      },
      onLastReadAtUpdated: (Map<String, dynamic> lastreadat) async {
        print('更新最后读取时间');
        print(lastreadat);
      },
      onLastDeliveredAtUpdated: (Map<String, dynamic> lastdeliver) async {
        print('接收时间更新');
        print(lastdeliver);
        String jsonLastDelivered = lastdeliver['LastDeliveredAt'];
        updateLastDelivered(jsonLastDelivered);
      },
    );
  }

  Future<String> getConversationId(String username) async {
    String conversationId =
        await ImleancloudPlugin.getConversation(User.currentUser, username);
    return conversationId;
  }

  Future savesqlConversation(String username) async {
    String conversationId = await getConversationId(username);
    print('savesqlConversation:$conversationId');
    bool isconversationExist = await dbc.conversationExist(username);
    print('savesqlConversation isconversationExist:$isconversationExist');
    if (isconversationExist == false) {
      Conversation conversation =
          new Conversation(User.currentUser, conversationId, username);
      await dbc.insert(conversation);
      textEditingController.clear();
    } else {
      print('会话已经存在');
      textEditingController.clear();
    }
    // await dbc.close();
  }

  Future getcurrentUserConversation() async {
    conversations = await dbc.getcurrentUserConversation(User.currentUser);
    _streamController.sink.add(conversations);
    //  await dbc.close();
  }

  Future test1(String username) async {
    await savesqlConversation(username);
    getcurrentUserConversation();
  }

  //int _lastClickTime = 0;
  //bool btnShow = true;
//返回键监听存在技术bug
  Future<bool> onBackPress() async {
//    int nowTime = new DateTime.now().microsecondsSinceEpoch;
//    if (_lastClickTime != 0 && nowTime - _lastClickTime > 1500) {
//      return new Future.value(true);
//    } else {
//      _lastClickTime = new DateTime.now().microsecondsSinceEpoch;
//      new Future.delayed(const Duration(milliseconds: 1500), () {
//        _lastClickTime = 0;
//      });
    return Future.value(true);
    //}
  }

  Future<void> signout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.remove('currentUser');
    await dbc.close();
    Navigator.push(
        context, MaterialPageRoute(builder: (context) => LoginPage()));
    await ImleancloudPlugin.signoutClick();
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: AppBar(
        title: const Text('聊天测试程序'),
        actions: <Widget>[
          IconButton(
            onPressed: signout,
            icon: Icon(Icons.delete),
          )
        ],
      ),
      body: WillPopScope(
        child: Column(
          children: <Widget>[
            buildInput(),
            buildListConversation(),
          ],
        ),
        onWillPop: onBackPress,
      ),
    );
  }

  Widget buildInput() {
    return Container(
      child: Row(
        children: <Widget>[
          // Edit text
          Flexible(
            child: Container(
              child: TextField(
                style: TextStyle(color: Colors.black54, fontSize: 18.0),
                controller: textEditingController,
                decoration: InputDecoration.collapsed(
                  hintText: '输入发送对象',
                  hintStyle: TextStyle(color: Colors.black38),
                ),
                focusNode: focusNode,
                //maxLines: 9,
              ),
            ),
          ),

          // Button send message
          Material(
            child: new Container(
              margin: new EdgeInsets.symmetric(horizontal: 8.0),
              child: new IconButton(
                icon: new Icon(Icons.send),
                onPressed: () => test1(textEditingController.text),
                color: Colors.blue,
              ),
            ),
            color: Colors.white,
          ),
        ],
      ),
      width: double.infinity,
      height: 50.0,
//      decoration: new BoxDecoration(
//          border: new Border(
//              top: new BorderSide(color: Colors.black54, width: 0.5)),
//          color: Colors.white),
    );
  }

  Widget buildListConversation() {
    return Flexible(
      child: StreamBuilder(
        stream: _streamController.stream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(
              child: null,
//                child: CircularProgressIndicator(
//                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blue)));
            );
          } else {
            return ListView.builder(
              padding: EdgeInsets.all(10.0),
              itemBuilder: (context, index) =>
                  buildItem(index, snapshot.data[index].toMap()),
              itemCount: snapshot.data.length,
              controller: listScrollController,
            );
          }
        },
      ),
    );
  }

  Widget buildItem(int index, Map detail) {
    // return Text('${detail['username']}');
    return ListTile(
        title: Text(detail['username']),
        onTap: () {
          Navigator.of(context).pushReplacement(
              CustomeRout(talk2(detail['conversationId'], detail['username']),1.0));
//              MaterialPageRoute(
//                  builder: (context) =>
//                      talk2(detail['conversationId'], detail['username']))
          // getcurrentUserConversation();
        });
  }

  @override
  void initState() {
    initPlatformState();
    getcurrentUserConversation();
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }
}
