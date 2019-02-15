import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:im_leancloud_plugin/im_leancloud_plugin.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'sql/sqlconversation.dart';
import 'sql/conversation.dart';
import 'sql/sql.dart';
import 'sql/message.dart';
import 'login.dart';
import 'contact.dart';
import 'chat.dart';

void main() {
  _islogin().then((onValue) {
    runApp(new MyApp(onValue));
  });
}

Future<bool> _islogin() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String currentUser = prefs.getString('currentUser');
  if (currentUser == null) {
    return false;
  } else {
    return true;
  }
}

class MyApp extends StatefulWidget {
  MyApp(this.landing);
  final bool landing;
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _platformVersion = 'Unknown';
  ImLeancloudPlugin ImleancloudPlugin = ImLeancloudPlugin.getInstance();
  sql db = new sql();
  sqlConversation dbc = new sqlConversation();

  @override
  void initState() {
    initApp();
    super.initState();
  }

  void onLoginClick()async {
    if(widget.landing) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String currentUser=prefs.getString('currentUser');
      ImleancloudPlugin.onLoginClick(currentUser);
    }
  }


  Future<void> initApp() async {
    await initLeancloud();
    initPlatformState();
    onLoginClick();
  }

  void initLeancloud() {
    String appId = "";//输入设置当前Leancloud appId
    String appKey = "";//输入设置当前Leancloud appKey
    ImleancloudPlugin.initialize(appId, appKey);
  }

  void conversationRead() {
    ImleancloudPlugin.conversationRead();
  }

  Future<void> saveNewconversation(
      String conversationId, String username) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String currentUser = prefs.getString('currentUser');
    bool isconversationExist = await dbc.conversationExist(username);
    if (isconversationExist == false) {
      Conversation conversation =
          new Conversation(currentUser, conversationId, username);
      int res = await dbc.saveConversation(conversation);
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
      }
    } else {
      print('没有未收消息');
    }
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    String platformVersion;
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      platformVersion = await ImLeancloudPlugin.platformVersion;
      ImleancloudPlugin.addEventHandler(
        //接收实时消息
        onReceiveMessage: (Map<String, dynamic> message) async {
          String content = json.decode(message['content'])['_lctext'];
          Message onReceiveMessage = new Message(
              content, message['getfrom'], message['conversationId']);
          int res = await db.saveMessage(onReceiveMessage);
          print(res);
          saveNewconversation(message['conversationId'], message['getfrom']);
        },
        //网络状态重新连接
        unReadMessages: (isResume) async {
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
    } on PlatformException {
      platformVersion = '获取平台版本失败';
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _platformVersion = platformVersion;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: widget.landing ? contact() : LoginPage());
  }
}