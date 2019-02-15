import 'package:flutter/material.dart';
import 'dart:convert';
import 'sql/conversation.dart';
import 'sql/sqlconversation.dart';
import 'sql/message.dart';
import 'sql/sql.dart';
import 'dart:async';
import 'talk2.dart';
import 'login.dart';
import 'package:im_leancloud_plugin/im_leancloud_plugin.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  sqlConversation dbc = new sqlConversation();
  sql db = new sql();
  List<Conversation> conversations;

  Future<void> saveNewconversation(
      String conversationId, String username) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String currentUser = prefs.getString('currentUser');
    bool isconversationExist = await dbc.conversationExist(username);
    if (isconversationExist == false) {
      Conversation conversation =
          new Conversation(currentUser, conversationId, username);
      int res = await dbc.saveConversation(conversation);
      getcurrentUserConversation();
      print('会话列表数：$res');
    } else {
      print('会话已经存在');
    }
  }

  Future<void> saveUnreadMessages(String listmessages) async {
    List<dynamic> messages = json.decode(listmessages);
    int length = messages.length;
    if (length > 1) {
      for (int i = 0; i < length; i++) {
        if (messages[i]['MessageStatus'] == 'AVIMMessageStatusNone') {
          String content = json.decode(messages[i]['content'])['_lctext'];
          Message onReceiveMessage = new Message(
              content, messages[i]['getfrom'], messages[i]['conversationId']);
          int res = await db.saveMessage(onReceiveMessage);
          await saveNewconversation(
              messages[i]['conversationId'], messages[i]['getfrom']);
          print(res);
        }
      }
    } else if (length == 1) {
      if (messages[0]['MessageStatus'] == 'AVIMMessageStatusNone') {
        String content = json.decode(messages[0]['content'])['_lctext'];
        Message onReceiveMessage = new Message(
            content, messages[0]['getfrom'], messages[0]['conversationId']);
        int res = await db.saveMessage(onReceiveMessage);
        print(res);
        await saveNewconversation(
            messages[0]['conversationId'], messages[0]['getfrom']);
      }
    } else {
      print('没有未收消息');
    }
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    ImleancloudPlugin.addEventHandler(
      //接收实时消息
      onReceiveMessage: (Map<String, dynamic> message) async {
        String content = json.decode(message['content'])['_lctext'];
        Message onReceiveMessage =
            new Message(content, message['getfrom'], message['conversationId']);
        int res = await db.saveMessage(onReceiveMessage);
        saveNewconversation(message['conversationId'], message['getfrom']);
        print(res);
      },
      //网络状态重新连接
      onConnectionResume: (isResume) async {
        print(isResume);
      },
      //未读消息状态发生变化
      unRead: (Map<String, dynamic> unreadmessage) async {
        int unreadcount = unreadmessage['unreadcount'];
        String unReadConversationId = unreadmessage['conversationId'];
        print('unreadcount:$unreadcount');
        print('unReadConversationId:$unReadConversationId');
        String messages = await ImleancloudPlugin.queryUnreadMessages(
            unReadConversationId, unreadcount);
        print(messages);
        saveUnreadMessages(messages);
      },
    );
  }

  Future<String> getConversationId(String username) async {
    String conversationId = await ImleancloudPlugin.getConversation(username);
    return conversationId;
  }

  Future savesqlConversation(String username) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String currentUser = prefs.getString('currentUser');
    String conversationId = await getConversationId(username);
    print('savesqlConversation:$conversationId');
    bool isconversationExist = await dbc.conversationExist(username);
    print('savesqlConversation isconversationExist:$isconversationExist');
    if (isconversationExist == false) {
      Conversation conversation =
          new Conversation(currentUser, conversationId, username);
      int res = await dbc.saveConversation(conversation);
      print(res);
      textEditingController.clear();
    } else {
      print('会话已经存在');
      textEditingController.clear();
    }
  }

  Future getcurrentUserConversation() async {
    conversations = await dbc.getcurrentUserConversation();
    _streamController.sink.add(conversations);
  }

  Future test1(String username) async {
    await savesqlConversation(username);
    getcurrentUserConversation();
  }

  int _lastClickTime = 0;
  bool btnShow = true;

  Future<bool> onBackPress() async {
    int nowTime = new DateTime.now().microsecondsSinceEpoch;
    if (_lastClickTime != 0 && nowTime - _lastClickTime > 1500) {
      return new Future.value(true);
    } else {
      _lastClickTime = new DateTime.now().microsecondsSinceEpoch;
      new Future.delayed(const Duration(milliseconds: 1500), () {
        _lastClickTime = 0;
      });
      return new Future.value(false);
    }
  }

  Future<void> signout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.remove('currentUser');
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
              // margin: new EdgeInsets.symmetric(horizontal: 1.0),
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
      decoration: new BoxDecoration(
          border: new Border(
              top: new BorderSide(color: Colors.black54, width: 0.5)),
          color: Colors.white),
    );
  }

  Widget buildListConversation() {
    return Flexible(
      child: StreamBuilder(
        stream: _streamController.stream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(
                child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blue)));
          } else {
            return ListView.builder(
              padding: EdgeInsets.all(10.0),
              itemBuilder: (context, index) => buildItem(index,
                  snapshot.data[snapshot.data.length - index - 1].toMap()),
              itemCount: snapshot.data.length,
              reverse: true,
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
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) =>
                      talk2(detail['conversationId'], detail['username'])));
        }
        //pageroute(detail['conversationId'], detail['username']),
        );
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
