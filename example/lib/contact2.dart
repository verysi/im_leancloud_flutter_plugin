import 'package:flutter/material.dart';
import 'dart:convert';
import 'user.dart';
import 'sql/message.dart';
import 'dart:async';
import 'talk2.dart';
import 'login.dart';
import 'package:im_leancloud_plugin/im_leancloud_plugin.dart';
import 'package:shared_preferences/shared_preferences.dart';

class contact2 extends StatefulWidget {
  @override
  contact2State createState() => new contact2State();
}

class contact2State extends State<contact2> {
  final TextEditingController EditingController = new TextEditingController();
  final TextEditingController textEditingController =
      new TextEditingController();
  final ScrollController listScrollController = new ScrollController();
  final StreamController<List<dynamic>> _streamController =
      StreamController<List<dynamic>>();
  ImLeancloudPlugin ImleancloudPlugin = ImLeancloudPlugin.getInstance();
  // List<String> contents=List<String>();
  final FocusNode focusNode = new FocusNode();
  List<dynamic> conversations = [];

  @override
  void initState() {
    initPlatformState();
    getcurrentUserConversation();
    super.initState();
  }


  Future<void> onLoginClick(String currentUser) async {
    ImLeancloudPlugin ImleancloudPlugin = ImLeancloudPlugin.getInstance();
    ImleancloudPlugin.onLoginClick(currentUser);
   // bool islogin = await ImleancloudPlugin.onLoginClick(currentUser);
  //  if (islogin) {
    //  User.isloginLcchat = true;
   // }
  }

  Future<void> getcurrentUserConversation() async {
    String jsonconversations =
        await ImleancloudPlugin.conversationList(User.currentUser);
    print(jsonconversations);
    List<dynamic> lconversation = json.decode(jsonconversations);
    conversations = lconversation;
    _streamController.sink.add(conversations);
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    ImleancloudPlugin.addEventHandler(
      //接收实时消息
      onReceiveMessage: (Map<String, dynamic> message) async {
        String content = json.decode(message['content'])['_lctext'];
        Message onReceiveMessage =
            new Message(content, message['getfrom'], message['conversationId']);
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
      },
    );
  }

  Future<void> savesqlConversation(String username) async {
    print(username);
    String conversationId =
        await ImleancloudPlugin.getConversation(User.currentUser, username);
    print('savesqlConversation:$conversationId');
    textEditingController.clear();
    getcurrentUserConversation();
  }

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
              //itemBuilder: (context, index) => buildItem(
              // index, snapshot.data[snapshot.data.length - index]),
              itemBuilder: (context, index) =>
                  buildItem(index, snapshot.data[index]),
              itemCount: snapshot.data.length,
              //reverse: true,
              controller: listScrollController,
            );
          }
        },
      ),
    );
  }

  Widget buildItem(int index, Map detail) {
    String convesationname = conversationName(detail['getMembers']);
    return ListTile(
        title: Text(convesationname),
        onTap: () {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) =>
                      talk2(detail['conversationId'], convesationname)));
        });
  }

  @override
  void dispose() {
    super.dispose();
  }
}
